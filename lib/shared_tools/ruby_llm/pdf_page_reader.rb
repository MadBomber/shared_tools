# frozen_string_literal: true
# Credit: https://max.engineer/giant-pdf-llm

require "pdf-reader"
require_relative '../../shared_tools'

module SharedTools
  verify_gem :ruby_llm

  class PdfPageReader < ::RubyLLM::Tool

    description "Read the text of any set of pages from a PDF document."
    param :page_numbers,
      desc: 'Comma-separated page numbers (first page: 1). (e.g. "12, 14, 15")'
    param :doc_path,
      desc: "Path to the PDF document."

    def execute(page_numbers:, doc_path:)
      RubyLLM.logger.info("Reading PDF: #{doc_path}, pages: #{page_numbers}")

      begin
        @doc ||= PDF::Reader.new(doc_path)
        RubyLLM.logger.debug("PDF loaded successfully, total pages: #{@doc.pages.size}")

        page_numbers = page_numbers.split(",").map { |num| num.strip.to_i }
        RubyLLM.logger.debug("Processing pages: #{page_numbers.join(", ")}")

        # Validate page numbers
        total_pages = @doc.pages.size
        invalid_pages = page_numbers.select { |num| num < 1 || num > total_pages }

        if invalid_pages.any?
          RubyLLM.logger.warn("Invalid page numbers requested: #{invalid_pages.join(", ")}. Document has #{total_pages} pages.")
        end

        # Filter valid pages and map to content
        valid_pages = page_numbers.select { |num| num >= 1 && num <= total_pages }
        pages = valid_pages.map { |num| [num, @doc.pages[num.to_i - 1]] }

        result = {
          total_pages: total_pages,
          requested_pages: page_numbers,
          invalid_pages: invalid_pages,
          pages: pages.map { |num, p|
            RubyLLM.logger.debug("Extracted text from page #{num} (#{p&.text&.bytesize || 0} bytes)")
            { page: num, text: p&.text }
          },
        }

        RubyLLM.logger.info("Successfully extracted #{pages.size} pages from PDF")
        result
      rescue => e
        RubyLLM.logger.error("Failed to read PDF '#{doc_path}': #{e.message}")
        { error: e.message }
      end
    end
  end
end
