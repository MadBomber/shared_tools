# frozen_string_literal: true

module SharedTools
  module Tools
    module Doc
      # Read and return the full contents of a plain text file.
      #
      # @example
      #   tool = SharedTools::Tools::Doc::TextReaderTool.new
      #   tool.execute(doc_path: "./guide.txt")
      class TextReaderTool < ::RubyLLM::Tool
        def self.name = 'doc_text_read'

        description "Read the full contents of a plain text file."

        params do
          string :doc_path, description: "Path to the text file to read."
        end

        # @param logger [Logger] optional logger
        def initialize(logger: nil)
          @logger = logger || RubyLLM.logger
        end

        # @param doc_path [String] path to the text file
        # @return [Hash] file content and metadata
        def execute(doc_path:)
          @logger.info("TextReaderTool#execute doc_path=#{doc_path.inspect}")

          raise ArgumentError, "doc_path is required" if doc_path.nil? || doc_path.strip.empty?
          raise ArgumentError, "File not found: #{doc_path}" unless File.exist?(doc_path)
          raise ArgumentError, "Not a file: #{doc_path}" unless File.file?(doc_path)

          content    = File.read(doc_path, encoding: 'utf-8')
          line_count = content.lines.size
          char_count = content.length
          word_count = content.split.size

          @logger.info("TextReaderTool read #{char_count} chars, #{line_count} lines from #{doc_path}")

          {
            doc_path:   doc_path,
            content:    content,
            line_count: line_count,
            word_count: word_count,
            char_count: char_count
          }
        rescue ArgumentError
          raise
        rescue => e
          @logger.error("TextReaderTool failed to read #{doc_path}: #{e.message}")
          { error: e.message, doc_path: doc_path }
        end
      end
    end
  end
end
