# frozen_string_literal: true


module SharedTools
  module Tools
    module Eval
      # @example
      #   tool = SharedTools::Tools::Eval::RubyEvalTool.new
      #   tool.execute(code: "puts 'Hello'; 2 + 2")
      class RubyEvalTool < ::RubyLLM::Tool
        def self.name = 'eval_ruby'

        description <<~DESCRIPTION
                      Execute Ruby source code safely and return the result.

                      This tool evaluates Ruby code in a sandboxed context and returns
                      the result of the last expression or any output produced.

                      WARNING: This tool executes arbitrary Ruby code. Use with caution.
                    DESCRIPTION
        param :code, desc: "The Ruby code to execute"

        # @param logger [Logger] optional logger
        def initialize(logger: nil)
          @logger = logger || RubyLLM.logger
        end

        # @param code [String] Ruby code to execute
        #
        # @return [Hash] execution result
        def execute(code:)
          @logger.info("Requesting permission to execute Ruby code")

          if code.strip.empty?
            error_msg = "Ruby code cannot be empty"
            @logger.error(error_msg)
            return { error: error_msg }
          end

          # Show user the code and ask for confirmation
          allowed = SharedTools.execute?(tool: self.class.to_s, stuff: code)

          unless allowed
            @logger.warn("User declined to execute the Ruby code")
            return { error: "User declined to execute the Ruby code" }
          end

          @logger.info("Executing Ruby code")

          # Capture both stdout and the result of evaluation
          original_stdout = $stdout
          captured_output = StringIO.new
          $stdout = captured_output

          begin
            result = eval(code)
            output = captured_output.string

            @logger.debug("Ruby code execution completed successfully")

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
            @logger.error("Ruby code execution failed: #{e.message}")
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
  end
end
