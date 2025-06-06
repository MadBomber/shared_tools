# frozen_string_literal: true

require "ruby_llm"

module SharedTools
  class ListFiles < RubyLLM::Tool

    description "List files and directories at a given path. If no path is provided, lists files in the current directory."
    param :path, desc: "Optional relative path to list files from. Defaults to current directory if not provided."

    def execute(path: Dir.pwd)
      logger.info("Listing files in path: #{path}")

      # Convert to absolute path for consistency
      absolute_path = File.absolute_path(path)

      # Verify the path exists and is a directory
      unless File.directory?(absolute_path)
        error_msg = "Path does not exist or is not a directory: #{path}"
        logger.error(error_msg)
        return { error: error_msg }
      end

      # Get all files including hidden ones
      visible_files = Dir.glob(File.join(absolute_path, "*"))
      hidden_files = Dir.glob(File.join(absolute_path, ".*"))
                        .reject { |f| f.end_with?("/.") || f.end_with?("/..") }

      # Combine and format results
      all_files = (visible_files + hidden_files).sort
      formatted_files = all_files.map do |filename|
        if File.directory?(filename)
          "#{filename}/"
        else
          filename
        end
      end

      logger.debug("Found #{formatted_files.size} files/directories (including #{hidden_files.size} hidden)")
      formatted_files
    rescue => e
      logger.error("Failed to list files in '#{path}': #{e.message}")
      { error: e.message }
    end
  end
end
