# frozen_string_literal: true

require "shared_tools/ruby_llm/tool"

module SharedTools
  module RubyLLM
    class RunShellCommand < Tool
      
      description "Execute a shell command"
      param :command, desc: "The command to execute"

      def execute(command:)
        logger.info("Requesting permission to execute command: '#{command}'")
        
        puts "AI wants to execute the following shell command: '#{command}'"
        print "Do you want to execute it? (y/n) "
        response = gets.chomp
        
        unless response == "y"
          logger.warn("User declined to execute the command: '#{command}'")
          return { error: "User declined to execute the command" }
        end
        
        logger.info("Executing command: '#{command}'")
        result = `#{command}`
        logger.debug("Command execution completed with #{result.bytesize} bytes of output")
        
        result
      rescue => e
        logger.error("Command execution failed: #{e.message}")
        { error: e.message }
      end
    end
  end
end
