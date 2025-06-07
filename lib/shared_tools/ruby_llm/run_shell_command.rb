# frozen_string_literal: true

require("ruby_llm")     unless defined?(RubyLLM)
require("shared_tools") unless defined?(SharedTools)

module SharedTools
  class RunShellCommand < RubyLLM::Tool

    description "Execute a shell command"
    param :command, desc: "The command to execute"

    def execute(command:)
      logger.info("Requesting permission to execute command: '#{command}'")

      if command.strip.empty?
        error_msg = "Command cannot be empty"
        logger.error(error_msg)
        return { error: error_msg }
      end

      # Show user the command and ask for confirmation
      puts "AI wants to execute the following shell command: '#{command}'"
      print "Do you want to execute it? (y/n) "
      response = gets.chomp.downcase

      unless response == "y"
        logger.warn("User declined to execute the command: '#{command}'")
        return { error: "User declined to execute the command" }
      end

      logger.info("Executing command: '#{command}'")

      # Use Open3 for safer command execution with proper error handling
      require "open3"
      stdout, stderr, status = Open3.capture3(command)

      if status.success?
        logger.debug("Command execution completed successfully with #{stdout.bytesize} bytes of output")
        { stdout: stdout, exit_status: status.exitstatus }
      else
        logger.warn("Command execution failed with exit code #{status.exitstatus}: #{stderr}")
        { error: "Command failed with exit code #{status.exitstatus}", stderr: stderr, exit_status: status.exitstatus }
      end
    rescue => e
      logger.error("Command execution failed: #{e.message}")
      { error: e.message }
    end
  end
end
