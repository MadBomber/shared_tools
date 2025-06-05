# frozen_string_literal: true
# File: tools/ruby_llm/edit_file.rb

require "ruby_llm/tool"

module SharedTools
  class EditFile < RubyLLM::Tool
    
    description <<~DESCRIPTION
      Make edits to a text file.

      Replaces 'old_str' with 'new_str' in the given file.
      'old_str' and 'new_str' MUST be different from each other.

      If the file specified with path doesn't exist, it will be created.
    DESCRIPTION
    param :path, desc: "The path to the file"
    param :old_str, desc: "Text to search for - must match exactly and must only have one match exactly"
    param :new_str, desc: "Text to replace old_str with"

    def execute(path:, old_str:, new_str:)
      logger.info("Editing file: #{path}")
      
      if File.exist?(path)
        logger.debug("File exists, reading content")
        content = File.read(path)
      else
        logger.debug("File doesn't exist, creating new file")
        content = ""
      end
      
      matches = content.scan(old_str).size
      logger.debug("Found #{matches} matches for the string to replace")
      
      updated_content = content.sub(old_str, new_str)
      File.write(path, updated_content)
      
      logger.info("Successfully updated file: #{path}")
      true
    rescue => e
      logger.error("Failed to edit file '#{path}': #{e.message}")
      { error: e.message }
    end
  end
end
