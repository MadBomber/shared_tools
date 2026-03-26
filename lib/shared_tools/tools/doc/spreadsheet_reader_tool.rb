# frozen_string_literal: true

begin
  require "roo"
rescue LoadError
  # roo is optional - will raise an error when the tool is used without it
end

module SharedTools
  module Tools
    module Doc
      # Read spreadsheet data from CSV, XLSX, ODS, and other formats supported by the roo gem.
      #
      # @example Read all rows from a CSV
      #   tool = SharedTools::Tools::Doc::SpreadsheetReaderTool.new
      #   tool.execute(doc_path: "./data.csv")
      #
      # @example Read a specific sheet from an Excel workbook
      #   tool.execute(doc_path: "./report.xlsx", sheet: "Q1 Sales")
      #
      # @example Read a row range from a worksheet
      #   tool.execute(doc_path: "./report.xlsx", sheet: "Summary", row_range: "2-50")
      class SpreadsheetReaderTool < ::RubyLLM::Tool
        def self.name = 'doc_spreadsheet_read'

        description "Read tabular data from spreadsheet files (CSV, XLSX, ODS, and other formats)."

        SUPPORTED_FORMATS = %w[.csv .xlsx .ods .xlsm].freeze

        params do
          string :doc_path, description: <<~DESC.strip
            Path to the spreadsheet file. Supported formats:
            - .csv  — Comma-separated values (plain text, no gem beyond roo required)
            - .xlsx — Microsoft Excel Open XML Workbook (Excel 2007+)
            - .xlsm — Microsoft Excel Macro-Enabled Workbook
            - .ods  — OpenDocument Spreadsheet (LibreOffice / OpenOffice)
            Note: Legacy .xls (Excel 97-2003) requires the additional 'roo-xls' gem.
          DESC

          string :sheet, description: <<~DESC.strip, required: false
            Name or 1-based index of the worksheet to read. For multi-sheet workbooks
            (XLSX, ODS), specify the exact sheet name (e.g. "Q1 Sales") or a number
            (e.g. "2" for the second sheet). Defaults to the first sheet.
            CSV files always have a single implicit sheet called "default".
          DESC

          string :row_range, description: <<~DESC.strip, required: false
            Row range to extract, 1-based (row 1 is the header row in most spreadsheets).
            Accepts the same notation as other doc tool parameters:
            - Single row:    "3"
            - Multiple rows: "1, 3, 5"
            - Range:         "1-100"
            - Mixed:         "1, 5-20, 30"
            Omit to return all rows.
          DESC

          boolean :headers, description: <<~DESC.strip, required: false
            When true (default), treats the first row as column headers and returns
            each subsequent row as a hash keyed by header name. When false, returns
            each row as a plain array of values. Set to false when the spreadsheet
            has no header row or when you want raw positional data.
          DESC
        end

        # @param logger [Logger] optional logger
        def initialize(logger: nil)
          @logger = logger || RubyLLM.logger
        end

        # @param doc_path [String] path to spreadsheet file
        # @param sheet [String, nil] sheet name or 1-based index
        # @param row_range [String, nil] row range to extract
        # @param headers [Boolean] whether first row is headers
        # @return [Hash] extraction result
        def execute(doc_path:, sheet: nil, row_range: nil, headers: true)
          raise LoadError, "SpreadsheetReaderTool requires the 'roo' gem. Install it with: gem install roo" unless defined?(Roo)

          @logger.info("SpreadsheetReaderTool#execute doc_path=#{doc_path} sheet=#{sheet} row_range=#{row_range}")

          return { error: "File not found: #{doc_path}" } unless File.exist?(doc_path)

          ext = File.extname(doc_path).downcase
          unless SUPPORTED_FORMATS.include?(ext)
            return { error: "Unsupported format '#{ext}'. Supported: #{SUPPORTED_FORMATS.join(', ')}" }
          end

          ss = Roo::Spreadsheet.open(doc_path)

          # Select sheet
          active_sheet = resolve_sheet(ss, sheet)
          return active_sheet if active_sheet.is_a?(Hash) && active_sheet[:error]

          ss.default_sheet = active_sheet

          total_rows  = ss.last_row.to_i
          first_row   = ss.first_row.to_i
          header_row  = headers ? ss.row(first_row).map { |h| h.to_s.strip } : nil

          # Determine data rows (skip header if using headers)
          data_start  = headers ? first_row + 1 : first_row
          all_indices = (data_start..total_rows).to_a

          selected = row_range ? filter_rows(all_indices, row_range) : all_indices
          invalid  = selected.reject { |n| n >= first_row && n <= total_rows }
          valid    = selected.select { |n| n >= first_row && n <= total_rows }

          rows = valid.map do |n|
            raw = ss.row(n)
            if headers && header_row
              header_row.zip(raw).to_h
            else
              raw
            end
          end

          @logger.info("SpreadsheetReaderTool: read #{rows.size} rows from '#{active_sheet}'")

          {
            doc_path:       doc_path,
            format:         ext,
            available_sheets: ss.sheets,
            active_sheet:   active_sheet,
            total_rows:     total_rows,
            header_row:     header_row,
            requested_range: row_range || "all",
            invalid_rows:   invalid,
            row_count:      rows.size,
            rows:           rows
          }
        rescue => e
          @logger.error("SpreadsheetReaderTool failed for '#{doc_path}': #{e.message}")
          { error: e.message }
        end

        private

        # Resolve sheet name or 1-based index to the actual sheet name.
        def resolve_sheet(ss, sheet_param)
          return ss.sheets.first if sheet_param.nil?

          # Numeric string → treat as 1-based index
          if sheet_param.match?(/\A\d+\z/)
            idx = sheet_param.to_i - 1
            return { error: "Sheet index #{sheet_param} out of range (workbook has #{ss.sheets.size} sheet(s))" } if idx < 0 || idx >= ss.sheets.size
            return ss.sheets[idx]
          end

          # Named sheet
          return sheet_param if ss.sheets.include?(sheet_param)

          { error: "Sheet '#{sheet_param}' not found. Available sheets: #{ss.sheets.join(', ')}" }
        end

        # Parse a range string like "1, 3-5, 10" into a sorted array of row indices.
        def filter_rows(all_indices, range_str)
          requested = range_str.split(',').flat_map do |part|
            part.strip!
            if part.include?('-')
              lo, hi = part.split('-').map { |n| n.strip.to_i }
              (lo..hi).to_a
            else
              [part.to_i]
            end
          end.uniq.sort

          all_indices & requested
        end
      end
    end
  end
end
