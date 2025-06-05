# frozen_string_literal: true

require "shared_tools/ruby_llm/tool"

module SharedTools
  module RubyLLM
    class ListFiles < Tool
      
      description "List files and directories at a given path. If no path is provided, lists files in the current directory."
      param :path, desc: "Optional relative path to list files from. Defaults to current directory if not provided."

      def execute(path: Dir.pwd)
        logger.info("Listing files in path: #{path}")
        
        files = Dir.glob(File.join(path, "*"))
               .map { |filename| File.directory?(filename) ? "#{filename}/" : filename }
        
        logger.debug("Found #{files.size} files/directories")
        files
      rescue => e
        logger.error("Failed to list files in '#{path}': #{e.message}")
        { error: e.message }
      end
    end
  end
end
