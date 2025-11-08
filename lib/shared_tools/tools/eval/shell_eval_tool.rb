# frozen_string_literal: true


module SharedTools
  module Tools
    module Eval
      # @example
      #   tool = SharedTools::Tools::Eval::ShellEvalTool.new
      #   tool.execute(command: "ls -la")
      class ShellEvalTool < ::RubyLLM::Tool
        def self.name = 'eval_shell'

        description "Execute a shell command safely and return the result."

        params do
          string :command, description: "The shell command to execute"
        end

        # @param logger [Logger] optional logger
        def initialize(logger: nil)
          @logger = logger || RubyLLM.logger
        end

        # @param command [String] shell command to execute
        #
        # @return [Hash] execution result
        def execute(command:)
          @logger.info("Requesting permission to execute command: '#{command}'")

          if command.strip.empty?
            error_msg = "Command cannot be empty"
            @logger.error(error_msg)
            return { error: error_msg }
          end

          # Show user the command and ask for confirmation
          allowed = SharedTools.execute?(tool: self.class.to_s, stuff: command)

          unless allowed
            @logger.warn("User declined to execute the command: '#{command}'")
            return { error: "User declined to execute the command" }
          end

          @logger.info("Executing command: '#{command}'")

          # Use Open3 for safer command execution with proper error handling
          require "open3"
          stdout, stderr, status = Open3.capture3(command)

          if status.success?
            @logger.debug("Command execution completed successfully with #{stdout.bytesize} bytes of output")
            { stdout: stdout, exit_status: status.exitstatus }
          else
            @logger.warn("Command execution failed with exit code #{status.exitstatus}: #{stderr}")
            { error: "Command failed with exit code #{status.exitstatus}", stderr: stderr, exit_status: status.exitstatus }
          end
        rescue => e
          @logger.error("Command execution failed: #{e.message}")
          { error: e.message }
        end
      end
    end
  end
end
