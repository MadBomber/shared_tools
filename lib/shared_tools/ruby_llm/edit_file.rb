# frozen_string_literal: true

require("ruby_llm")     unless defined?(RubyLLM)
require("shared_tools") unless defined?(SharedTools)

module SharedTools
  class EditFile < RubyLLM::Tool

    description <<~DESCRIPTION
                  Make edits to a text file.

                  Replaces 'old_str' with 'new_str' in the given file.
                  'old_str' and 'new_str' MUST be different from each other.

                  If the file specified with path doesn't exist, it will be created.

                  By default, only the first occurrence will be replaced. Set replace_all to true to replace all occurrences.
                DESCRIPTION
    param :path, desc: "The path to the file"
    param :old_str, desc: "Text to search for - must match exactly"
    param :new_str, desc: "Text to replace old_str with"
    param :replace_all, desc: "Whether to replace all occurrences (true) or just the first one (false)", required: false

    def execute(path:, old_str:, new_str:, replace_all: false)
      logger.info("Editing file: #{path}")

      # Normalize path to absolute path
      absolute_path = File.absolute_path(path)

      if File.exist?(absolute_path)
        logger.debug("File exists, reading content")
        content = File.read(absolute_path)
      else
        logger.debug("File doesn't exist, creating new file")
        content = ""
      end

      matches = content.scan(old_str).size
      logger.debug("Found #{matches} matches for the string to replace")

      if matches == 0
        logger.warn("No matches found for the string to replace. File will remain unchanged.")
        return { success: false, warning: "No matches found for the string to replace" }
      end

      if matches > 1 && !replace_all
        logger.warn("Multiple matches (#{matches}) found for the string to replace. Only the first occurrence will be replaced.")
      end

      if replace_all
        updated_content = content.gsub(old_str, new_str)
        replaced_count = matches
        logger.info("Replacing all #{matches} occurrences")
      else
        updated_content = content.sub(old_str, new_str)
        replaced_count = 1
        logger.info("Replacing first occurrence only")
      end

      File.write(absolute_path, updated_content)

      logger.info("Successfully updated file: #{path}")
      { success: true, matches: matches, replaced: replaced_count }
    rescue => e
      logger.error("Failed to edit file '#{path}': #{e.message}")
      { error: e.message }
    end
  end
end
