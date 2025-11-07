# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  module Tools
    # A tool for reading and processing documents
    class DocTool < ::RubyLLM::Tool
      def self.name = 'doc_tool'

      module Action
        PDF_READ = "pdf_read"
      end

      ACTIONS = [
        Action::PDF_READ,
      ].freeze

      description <<~TEXT
        Read and process various document formats.

        ## Actions:

        1. `#{Action::PDF_READ}` - Read specific pages from a PDF document
          Required: "action": "pdf_read", "doc_path": "[path to PDF]", "page_numbers": "[comma-separated page numbers]"

          The page_numbers parameter accepts:
          - Single page: "5"
          - Multiple pages: "1, 3, 5"
          - Range notation: "1-10" or "1, 3-5, 10"

        ## Examples:

        Read single page from PDF
          {"action": "#{Action::PDF_READ}", "doc_path": "./document.pdf", "page_numbers": "1"}

        Read multiple pages
          {"action": "#{Action::PDF_READ}", "doc_path": "./report.pdf", "page_numbers": "1, 5, 10"}

        Read page range
          {"action": "#{Action::PDF_READ}", "doc_path": "./book.pdf", "page_numbers": "10-15"}

        Read specific pages with range
          {"action": "#{Action::PDF_READ}", "doc_path": "./manual.pdf", "page_numbers": "1, 5-8, 15, 20-25"}
      TEXT

      params do
        string :action, description: <<~TEXT.strip
          The document action to perform. Options:
          * `#{Action::PDF_READ}`: Read pages from a PDF document
        TEXT

        string :doc_path, description: <<~TEXT.strip, required: false
          Path to the document file. Required for the following actions:
          * `#{Action::PDF_READ}`
        TEXT

        string :page_numbers, description: <<~TEXT.strip, required: false
          Comma-separated page numbers to read (first page is 1).
          Examples: "1", "1, 3, 5", "1-10", "1, 5-8, 15"
          Required for the following actions:
          * `#{Action::PDF_READ}`
        TEXT
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param action [String] the action to perform
      # @param doc_path [String, nil] path to document
      # @param page_numbers [String, nil] page numbers to read
      #
      # @return [Hash] execution result
      def execute(action:, doc_path: nil, page_numbers: nil)
        @logger.info("DocTool#execute action=#{action}")

        case action.to_s.downcase
        when Action::PDF_READ
          require_param!(:doc_path, doc_path)
          require_param!(:page_numbers, page_numbers)
          pdf_reader_tool.execute(doc_path: doc_path, page_numbers: page_numbers)
        else
          { error: "Unsupported action: #{action}. Supported actions are: #{ACTIONS.join(', ')}" }
        end
      rescue StandardError => e
        @logger.error("DocTool execution failed: #{e.message}")
        { error: e.message }
      end

    private

      # @param name [Symbol]
      # @param value [Object]
      #
      # @raise [ArgumentError]
      # @return [void]
      def require_param!(name, value)
        raise ArgumentError, "#{name} param is required for this action" if value.nil?
      end

      # @return [Doc::PdfReaderTool]
      def pdf_reader_tool
        @pdf_reader_tool ||= Doc::PdfReaderTool.new(logger: @logger)
      end
    end
  end
end
