# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  SharedTools.verify_gem :ruby_llm

  class RunShellCommand < ::RubyLLM::Tool

    description "Execute a shell command"
    param :command, desc: "The command to execute"

    def execute(command:)
      RubyLLM.logger.info("Requesting permission to execute command: '#{command}'")

      if command.strip.empty?
        error_msg = "Command cannot be empty"
        RubyLLM.logger.error(error_msg)
        return { error: error_msg }
      end

      # Show user the command and ask for confirmation
      allowed = SharedTools.execute?(tool: self.class.name, stuff: command)

      unless allowed
        RubyLLM.logger.warn("User declined to execute the command: '#{command}'")
        return { error: "User declined to execute the command" }
      end

      RubyLLM.logger.info("Executing command: '#{command}'")

      # Use Open3 for safer command execution with proper error handling
      require "open3"
      stdout, stderr, status = Open3.capture3(command)

      if status.success?
        RubyLLM.logger.debug("Command execution completed successfully with #{stdout.bytesize} bytes of output")
        { stdout: stdout, exit_status: status.exitstatus }
      else
        RubyLLM.logger.warn("Command execution failed with exit code #{status.exitstatus}: #{stderr}")
        { error: "Command failed with exit code #{status.exitstatus}", stderr: stderr, exit_status: status.exitstatus }
      end
    rescue => e
      RubyLLM.logger.error("Command execution failed: #{e.message}")
      { error: e.message }
    end
  end
end
