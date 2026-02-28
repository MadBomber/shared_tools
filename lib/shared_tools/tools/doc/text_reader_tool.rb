# frozen_string_literal: true

module SharedTools
  module Tools
    module Doc
      # Reads plain text files (markdown, txt, source code, etc.)
      #
      # @example
      #   tool = SharedTools::Tools::Doc::TextReaderTool.new
      #   tool.execute(doc_path: "./README.md")
      class TextReaderTool < ::RubyLLM::Tool
        def self.name = 'doc_text_read'

        description "Read the contents of a plain text file (markdown, txt, source code, etc.)."

        params do
          string :doc_path, description: "Path to the text file."
        end

        # @param logger [Logger] optional logger
        def initialize(logger: nil)
          @logger = logger || RubyLLM.logger
        end

        # @param doc_path [String] path to the text file
        #
        # @return [Hash] file contents or error
        def execute(doc_path:)
          @logger.info("Reading text file: #{doc_path}")

          path = File.expand_path(doc_path)

          unless File.exist?(path)
            return { error: "File not found: #{doc_path}" }
          end

          unless File.file?(path)
            return { error: "Not a file: #{doc_path}" }
          end

          content   = File.read(path)
          extension = File.extname(path)

          @logger.info("Successfully read #{content.bytesize} bytes from #{doc_path}")

          {
            path:      doc_path,
            extension: extension,
            size:      content.bytesize,
            lines:     content.count("\n") + 1,
            content:   content
          }
        rescue => e
          @logger.error("Failed to read text file '#{doc_path}': #{e.message}")
          { error: e.message }
        end
      end
    end
  end
end
