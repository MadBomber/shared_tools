# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools

  class RubyEval < ::RubyLLM::Tool
    def self.name = 'ruby_eval'

    description <<~DESCRIPTION
                  Execute Ruby source code safely and return the result.

                  This tool evaluates Ruby code in a sandboxed context and returns
                  the result of the last expression or any output produced.

                  WARNING: This tool executes arbitrary Ruby code. Use with caution.
                DESCRIPTION
    param :code, desc: "The Ruby code to execute"

    def execute(code:)
      RubyLLM.logger.info("Requesting permission to execute Ruby code")

      if code.strip.empty?
        error_msg = "Ruby code cannot be empty"
        RubyLLM.logger.error(error_msg)
        return { error: error_msg }
      end

      # Show user the code and ask for confirmation
      allowed = SharedTools.execute?(tool: self.class.to_s, stuff: code)

      unless allowed
        RubyLLM.logger.warn("User declined to execute the Ruby code")
        return { error: "User declined to execute the Ruby code" }
      end

      RubyLLM.logger.info("Executing Ruby code")

      # Capture both stdout and the result of evaluation
      original_stdout = $stdout
      captured_output = StringIO.new
      $stdout = captured_output

      begin
        result = eval(code)
        output = captured_output.string

        RubyLLM.logger.debug("Ruby code execution completed successfully")

        response = {
          result: result,
          output: output.empty? ? nil : output,
          success: true
        }

        # Include both result and output in a readable format
        if output.empty?
          response[:display] = result.inspect
        else
          response[:display] = output + (result.nil? ? "" : "\n=> #{result.inspect}")
        end

        response
      rescue SyntaxError, StandardError => e
        RubyLLM.logger.error("Ruby code execution failed: #{e.message}")
        {
          error: e.message,
          backtrace: e.backtrace&.first(5),
          success: false
        }
      ensure
        $stdout = original_stdout
      end
    end
  end
end
