# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  verify_gem :ruby_llm

  class PythonEval < RubyLLM::Tool

    description <<~DESCRIPTION
                  Execute Python source code safely and return the result.

                  This tool evaluates Python code by writing it to a temporary file
                  and executing it with the python3 command, capturing both stdout
                  and the final expression result.

                  WARNING: This tool executes arbitrary Python code. Use with caution.
                  NOTE: Requires python3 to be available in the system PATH.
                DESCRIPTION
    param :code, desc: "The Python code to execute"

    def execute(code:)
      RubyLLM.logger.info("Requesting permission to execute Python code")

      if code.strip.empty?
        error_msg = "Python code cannot be empty"
        RubyLLM.logger.error(error_msg)
        return { error: error_msg }
      end

      # Show user the code and ask for confirmation
      puts "AI wants to execute the following Python code:"
      puts "=" * 50
      puts code
      puts "=" * 50
      print "Do you want to execute it? (y/n) "
      response = gets.chomp.downcase

      unless response == "y"
        RubyLLM.logger.warn("User declined to execute the Python code")
        return { error: "User declined to execute the Python code" }
      end

      RubyLLM.logger.info("Executing Python code")

      begin
        require 'tempfile'
        require 'open3'
        require 'json'

        # Create a Python script that captures both output and result
        python_script = create_python_wrapper(code)

        # Write to temporary file
        temp_file = Tempfile.new(['python_eval', '.py'])
        temp_file.write(python_script)
        temp_file.flush

        # Execute the Python script
        stdout, stderr, status = Open3.capture3("python3", temp_file.path)

        temp_file.close
        temp_file.unlink

        if status.success?
          RubyLLM.logger.debug("Python code execution completed successfully")
          parse_python_output(stdout)
        else
          RubyLLM.logger.error("Python code execution failed: #{stderr}")
          {
            error: stderr.strip,
            success: false
          }
        end
      rescue => e
        RubyLLM.logger.error("Failed to execute Python code: #{e.message}")
        {
          error: e.message,
          backtrace: e.backtrace&.first(5),
          success: false
        }
      end
    end

    private

    def create_python_wrapper(user_code)
      require 'base64'
      encoded_code = Base64.strict_encode64(user_code)

      <<~PYTHON
        import sys
        import json
        import io
        import base64
        from contextlib import redirect_stdout

        # Decode the user code
        user_code = base64.b64decode('#{encoded_code}').decode('utf-8')

        # Capture stdout
        captured_output = io.StringIO()

        try:
            with redirect_stdout(captured_output):
                # Handle compound statements (semicolon-separated)
                if ';' in user_code and not user_code.strip().startswith('for ') and not user_code.strip().startswith('if '):
                    # Split by semicolon, execute all but last, eval the last
                    parts = [part.strip() for part in user_code.split(';') if part.strip()]
                    if len(parts) > 1:
                        for part in parts[:-1]:
                            exec(part)
                        # Try to eval the last part
                        try:
                            result = eval(parts[-1])
                        except SyntaxError:
                            exec(parts[-1])
                            result = None
                    else:
                        # Single part, try eval then exec
                        try:
                            result = eval(parts[0])
                        except SyntaxError:
                            exec(parts[0])
                            result = None
                else:
                    # Try to evaluate as expression first
                    try:
                        result = eval(user_code)
                    except SyntaxError:
                        # If not an expression, execute as statement
                        exec(user_code)
                        result = None

            output = captured_output.getvalue()

            # Prepare result for JSON serialization
            try:
                json.dumps(result)  # Test if result is JSON serializable
                serializable_result = result
            except (TypeError, ValueError):
                serializable_result = str(result)

            result_data = {
                "success": True,
                "result": serializable_result,
                "output": output if output else None,
                "python_type": type(result).__name__
            }

            print("PYTHON_EVAL_RESULT:", json.dumps(result_data))

        except Exception as e:
            error_data = {
                "success": False,
                "error": str(e),
                "error_type": type(e).__name__
            }
            print("PYTHON_EVAL_RESULT:", json.dumps(error_data))
      PYTHON
    end

    def parse_python_output(stdout)
      lines = stdout.split("\n")
      result_line = lines.find { |line| line.start_with?("PYTHON_EVAL_RESULT:") }

      if result_line
        json_data = result_line.sub("PYTHON_EVAL_RESULT:", "").strip
        result = JSON.parse(json_data)

        # Add display formatting
        if result["success"]
          if result["output"].nil? || result["output"].empty?
            result["display"] = result["result"].inspect
          else
            result_part = result["result"].nil? ? "" : "\n=> #{result["result"].inspect}"
            result["display"] = result["output"] + result_part
          end
        end

        # Convert string keys to symbols
        result.transform_keys(&:to_sym)
      else
        {
          error: "Failed to parse Python execution result",
          raw_output: stdout,
          success: false
        }
      end
    rescue JSON::ParserError => e
      {
        error: "Failed to parse Python result as JSON: #{e.message}",
        raw_output: stdout,
        success: false
      }
    end
  end
end
