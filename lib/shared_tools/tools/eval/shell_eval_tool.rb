# frozen_string_literal: true

require "open3"

module SharedTools
  module Tools
    module Eval
      # @example
      #   tool = SharedTools::Tools::Eval::ShellEvalTool.new
      #   tool.execute(command: "ls -la")
      #   tool.execute(command: "ls -la", workdir: "/tmp")
      class ShellEvalTool < ::RubyLLM::Tool
        STDOUT_MAX = 5000
        STDERR_MAX = 2000

        def self.name = 'eval_shell'

        description "Execute a shell command safely and return the result."

        params do
          string :command, description: "The shell command to execute"
          string :workdir, description: "Working directory for the command (default: current directory)", required: false
        end

        # @param logger [Logger] optional logger
        def initialize(logger: nil)
          @logger = logger || RubyLLM.logger
        end

        # @param command [String] shell command to execute
        # @param workdir [String, nil] working directory for the command
        #
        # @return [Hash] execution result
        def execute(command:, workdir: nil)
          @logger.info("Requesting permission to execute command: '#{command}'")

          if command.strip.empty?
            error_msg = "Command cannot be empty"
            @logger.error(error_msg)
            return { error: error_msg }
          end

          if workdir
            unless File.directory?(workdir)
              return { error: "Working directory not found: #{workdir}" }
            end
          end

          allowed = SharedTools.execute?(tool: self.class.to_s, stuff: command)

          unless allowed
            @logger.warn("User declined to execute the command: '#{command}'")
            return { error: "User declined to execute the command" }
          end

          @logger.info("Executing command: '#{command}'")

          opts = workdir ? { chdir: workdir } : {}
          stdout, stderr, status = Open3.capture3(command, **opts)

          stdout = truncate(stdout, STDOUT_MAX)
          stderr = truncate(stderr, STDERR_MAX)

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

        private

        def truncate(str, max)
          return str if str.length <= max
          str.slice(0, max) + "\n[truncated]"
        end
      end
    end
  end
end
