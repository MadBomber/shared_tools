# frozen_string_literal: true

require("ruby_llm")     unless defined?(RubyLLM)
require("shared_tools") unless defined?(SharedTools)

module SharedTools
  class ReadFile < RubyLLM::Tool

    description "Read the contents of a given relative file path. Use this when you want to see what's inside a file. Do not use this with directory names."
    param :path, desc: "The relative path of a file in the working directory."

    def execute(path:)
      logger.info("Reading file: #{path}")

      # Handle both relative and absolute paths consistently
      absolute_path = File.absolute_path(path)

      if File.directory?(absolute_path)
        error_msg = "Path is a directory, not a file: #{path}"
        logger.error(error_msg)
        return { error: error_msg }
      end

      unless File.exist?(absolute_path)
        error_msg = "File does not exist: #{path}"
        logger.error(error_msg)
        return { error: error_msg }
      end

      content = File.read(absolute_path)
      logger.debug("Successfully read #{content.bytesize} bytes from #{path}")
      content
    rescue => e
      logger.error("Failed to read file '#{path}': #{e.message}")
      { error: e.message }
    end
  end
end
