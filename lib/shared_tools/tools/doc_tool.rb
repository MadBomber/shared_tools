# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  module Tools
    # A tool for reading and processing documents
    class DocTool < ::RubyLLM::Tool
      def self.name = 'doc_tool'

      module Action
        PDF_READ         = "pdf_read"
        TEXT_READ        = "text_read"
        DOCX_READ        = "docx_read"
        SPREADSHEET_READ = "spreadsheet_read"
      end

      ACTIONS = [
        Action::PDF_READ,
        Action::TEXT_READ,
        Action::DOCX_READ,
        Action::SPREADSHEET_READ,
      ].freeze

      description <<~TEXT
        Read and process document files.

        ## Actions:

        1. `#{Action::TEXT_READ}` - Read the full contents of a plain text file (.txt, .md, etc.)
          Required: "action": "text_read", "doc_path": "[path to text file]"

        2. `#{Action::PDF_READ}` - Read specific pages from a PDF document
          Required: "action": "pdf_read", "doc_path": "[path to PDF]", "page_numbers": "[comma-separated page numbers]"

          The page_numbers parameter accepts:
          - Single page: "5"
          - Multiple pages: "1, 3, 5"
          - Range notation: "1-10" or "1, 3-5, 10"

        3. `#{Action::DOCX_READ}` - Read text content from a Microsoft Word (.docx) document
          Required: "action": "docx_read", "doc_path": "[path to .docx file]"
          Optional: "paragraph_range": "[comma-separated paragraph numbers or ranges]"

          The paragraph_range parameter accepts the same notation as page_numbers.
          Omit paragraph_range to return the full document.

        ## Examples:

        Read a text file
          {"action": "#{Action::TEXT_READ}", "doc_path": "./notes.txt"}

        Read single page from PDF
          {"action": "#{Action::PDF_READ}", "doc_path": "./document.pdf", "page_numbers": "1"}

        Read multiple pages
          {"action": "#{Action::PDF_READ}", "doc_path": "./report.pdf", "page_numbers": "1, 5, 10"}

        Read page range
          {"action": "#{Action::PDF_READ}", "doc_path": "./book.pdf", "page_numbers": "10-15"}

        Read specific pages with range
          {"action": "#{Action::PDF_READ}", "doc_path": "./manual.pdf", "page_numbers": "1, 5-8, 15, 20-25"}

        Read a full Word document
          {"action": "#{Action::DOCX_READ}", "doc_path": "./report.docx"}

        Read first 20 paragraphs of a Word document
          {"action": "#{Action::DOCX_READ}", "doc_path": "./report.docx", "paragraph_range": "1-20"}

        4. `#{Action::SPREADSHEET_READ}` - Read tabular data from a spreadsheet file
          Supported formats: CSV, XLSX, ODS, XLSM
          Required: "action": "spreadsheet_read", "doc_path": "[path to spreadsheet]"
          Optional: "sheet": "[sheet name or 1-based index]"
                    "row_range": "[row range, e.g. '2-100']"
                    "headers": true/false (default true — first row treated as headers)

        Read a full CSV file
          {"action": "#{Action::SPREADSHEET_READ}", "doc_path": "./data.csv"}

        Read a specific sheet from an Excel workbook
          {"action": "#{Action::SPREADSHEET_READ}", "doc_path": "./report.xlsx", "sheet": "Q1 Sales"}

        Read rows 2-50 from a worksheet without header treatment
          {"action": "#{Action::SPREADSHEET_READ}", "doc_path": "./report.xlsx", "row_range": "2-50", "headers": false}
      TEXT

      params do
        string :action, description: <<~TEXT.strip
          The document action to perform. Options:
          * `#{Action::TEXT_READ}`: Read a plain text file
          * `#{Action::PDF_READ}`: Read pages from a PDF document
          * `#{Action::DOCX_READ}`: Read paragraphs from a Microsoft Word (.docx) document
          * `#{Action::SPREADSHEET_READ}`: Read tabular data from a spreadsheet (CSV, XLSX, ODS)
        TEXT

        string :doc_path, description: <<~TEXT.strip, required: false
          Path to the document file. Required for all actions.
        TEXT

        string :page_numbers, description: <<~TEXT.strip, required: false
          Comma-separated page numbers to read (first page is 1).
          Examples: "1", "1, 3, 5", "1-10", "1, 5-8, 15"
          Required for the following actions:
          * `#{Action::PDF_READ}`
        TEXT

        string :paragraph_range, description: <<~TEXT.strip, required: false
          Comma-separated paragraph numbers or ranges to read from a Word document (first paragraph is 1).
          Examples: "1", "1, 3, 5", "1-20", "1, 5-8, 15"
          Optional for the following actions (omit to return the full document):
          * `#{Action::DOCX_READ}`
        TEXT

        string :sheet, description: <<~TEXT.strip, required: false
          Sheet name or 1-based sheet index to read from a multi-sheet spreadsheet.
          Examples: "Q1 Sales", "2"
          Optional for the following actions (defaults to the first sheet):
          * `#{Action::SPREADSHEET_READ}`
        TEXT

        string :row_range, description: <<~TEXT.strip, required: false
          Comma-separated row numbers or ranges to read from a spreadsheet (first row is 1).
          Examples: "1", "2-100", "1, 5-20, 30"
          Optional for the following actions (omit to return all rows):
          * `#{Action::SPREADSHEET_READ}`
        TEXT

        boolean :headers, description: <<~TEXT.strip, required: false
          When true (default), treats the first row as column headers and returns each
          subsequent row as a hash. When false, returns rows as plain arrays.
          Optional for the following actions:
          * `#{Action::SPREADSHEET_READ}`
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
      def execute(action:, doc_path: nil, page_numbers: nil, paragraph_range: nil, sheet: nil, row_range: nil, headers: true)
        @logger.info("DocTool#execute action=#{action}")

        case action.to_s.downcase
        when Action::TEXT_READ
          require_param!(:doc_path, doc_path)
          text_reader_tool.execute(doc_path: doc_path)
        when Action::PDF_READ
          require_param!(:doc_path, doc_path)
          require_param!(:page_numbers, page_numbers)
          pdf_reader_tool.execute(doc_path: doc_path, page_numbers: page_numbers)
        when Action::DOCX_READ
          require_param!(:doc_path, doc_path)
          docx_reader_tool.execute(doc_path: doc_path, paragraph_range: paragraph_range)
        when Action::SPREADSHEET_READ
          require_param!(:doc_path, doc_path)
          spreadsheet_reader_tool.execute(doc_path: doc_path, sheet: sheet, row_range: row_range, headers: headers)
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

      # @return [Doc::TextReaderTool]
      def text_reader_tool
        @text_reader_tool ||= Doc::TextReaderTool.new(logger: @logger)
      end

      # @return [Doc::DocxReaderTool]
      def docx_reader_tool
        @docx_reader_tool ||= Doc::DocxReaderTool.new(logger: @logger)
      end

      # @return [Doc::SpreadsheetReaderTool]
      def spreadsheet_reader_tool
        @spreadsheet_reader_tool ||= Doc::SpreadsheetReaderTool.new(logger: @logger)
      end
    end
  end
end
