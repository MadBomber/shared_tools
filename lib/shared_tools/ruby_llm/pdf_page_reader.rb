# frozen_string_literal: true
# Credit: https://max.engineer/giant-pdf-llm

require "shared_tools/ruby_llm/tool"
require "pdf-reader"

module SharedTools
  module RubyLLM
    class PdfPageReader < Tool
      
      description "Read the text of any set of pages from a PDF document."
      param :page_numbers,
        desc: 'Comma-separated page numbers (first page: 1). (e.g. "12, 14, 15")'
      param :doc_path,
        desc: 'Path to the PDF document.'

      def execute(page_numbers:, doc_path:)
        logger.info("Reading PDF: #{doc_path}, pages: #{page_numbers}")
        
        begin
          @doc ||= PDF::Reader.new(doc_path)
          logger.debug("PDF loaded successfully, total pages: #{@doc.pages.size}")
          
          page_numbers = page_numbers.split(",").map { _1.strip.to_i }
          logger.debug("Processing pages: #{page_numbers.join(', ')}")
          
          pages = page_numbers.map { |num| [num, @doc.pages[num.to_i - 1]] }
          
          result = {
            pages: pages.map { |num, p|
              logger.debug("Extracted text from page #{num} (#{p&.text&.bytesize || 0} bytes)")
              { page: num, text: p&.text }
            },
          }
          
          logger.info("Successfully extracted #{pages.size} pages from PDF")
          result
        rescue => e
          logger.error("Failed to read PDF '#{doc_path}': #{e.message}")
          { error: e.message }
        end
      end
    end
  end
end
