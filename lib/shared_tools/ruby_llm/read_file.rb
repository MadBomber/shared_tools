# frozen_string_literal: true

require "shared_tools/ruby_llm/tool"

module SharedTools
  module RubyLLM
    class ReadFile < Tool
      
      description "Read the contents of a given relative file path. Use this when you want to see what's inside a file. Do not use this with directory names."
      param :path, desc: "The relative path of a file in the working directory."

      def execute(path:)
        logger.info("Reading file: #{path}")
        content = File.read(path)
        logger.debug("Successfully read #{content.bytesize} bytes from #{path}")
        content
      rescue => e
        logger.error("Failed to read file '#{path}': #{e.message}")
        { error: e.message }
      end
    end
  end
end
