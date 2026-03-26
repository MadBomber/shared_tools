# frozen_string_literal: true

begin
  require "docx"
rescue LoadError
  # docx is optional - will raise error when tool is used without it
end

module SharedTools
  module Tools
    module Doc
      # Read text content from Microsoft Word (.docx) documents.
      #
      # @example
      #   tool = SharedTools::Tools::Doc::DocxReaderTool.new
      #   tool.execute(doc_path: "./report.docx")
      #   tool.execute(doc_path: "./report.docx", paragraph_range: "1-10")
      class DocxReaderTool < ::RubyLLM::Tool
        def self.name = 'doc_docx_read'

        description "Read the text content of a Microsoft Word (.docx) document."

        params do
          string :doc_path, description: "Path to the .docx file."

          string :paragraph_range, description: <<~DESC.strip, required: false
            Optional range of paragraphs to extract, 1-based.
            Accepts the same notation as pdf_read page numbers:
            - Single paragraph: "5"
            - Multiple paragraphs: "1, 3, 5"
            - Range: "1-20"
            - Mixed: "1, 5-10, 15"
            Omit to return the full document.
          DESC
        end

        # @param logger [Logger] optional logger
        def initialize(logger: nil)
          @logger = logger || RubyLLM.logger
        end

        # @param doc_path [String] path to .docx file
        # @param paragraph_range [String, nil] optional paragraph range
        # @return [Hash] extraction result
        def execute(doc_path:, paragraph_range: nil)
          raise LoadError, "DocxReaderTool requires the 'docx' gem. Install it with: gem install docx" unless defined?(Docx)

          @logger.info("DocxReaderTool#execute doc_path=#{doc_path} paragraph_range=#{paragraph_range}")

          unless File.exist?(doc_path)
            return { error: "File not found: #{doc_path}" }
          end

          unless File.extname(doc_path).downcase == '.docx'
            return { error: "Expected a .docx file, got: #{File.extname(doc_path)}" }
          end

          doc        = Docx::Document.open(doc_path)
          paragraphs = doc.paragraphs.map(&:to_s).reject { |p| p.strip.empty? }
          total      = paragraphs.length

          @logger.debug("Loaded #{total} non-empty paragraphs from #{doc_path}")

          selected_indices = if paragraph_range
            parse_range(paragraph_range, total)
          else
            (1..total).to_a
          end

          invalid = selected_indices.select { |n| n < 1 || n > total }
          valid   = selected_indices.select { |n| n >= 1 && n <= total }

          extracted = valid.map { |n| { paragraph: n, text: paragraphs[n - 1] } }

          @logger.info("Extracted #{extracted.size} paragraphs from #{doc_path}")

          {
            doc_path:           doc_path,
            total_paragraphs:   total,
            requested_range:    paragraph_range || "all",
            invalid_paragraphs: invalid,
            paragraphs:         extracted,
            full_text:          extracted.map { |p| p[:text] }.join("\n\n")
          }
        rescue => e
          @logger.error("Failed to read DOCX '#{doc_path}': #{e.message}")
          { error: e.message }
        end

        private

        # Parse a range string like "1, 3-5, 10" into a sorted array of integers.
        def parse_range(range_str, max)
          range_str.split(',').flat_map do |part|
            part.strip!
            if part.include?('-')
              lo, hi = part.split('-').map { |n| n.strip.to_i }
              (lo..hi).to_a
            else
              [part.to_i]
            end
          end.uniq.sort
        end
      end
    end
  end
end
