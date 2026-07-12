# frozen_string_literal: true

require 'csv'
require 'fileutils'
require_relative '../../shared_tools'

module SharedTools
  module Tools
    # Writes rows to a CSV file. Optional header row. Missing parent
    # directories are created. Overwrites an existing file. Mutating —
    # requires user authorization (see SharedTools.execute?).
    #
    # @example
    #   tool = SharedTools::Tools::CsvWriteTool.new
    #   tool.execute(path: "./out.csv", headers: ["name", "age"], rows: [["Alice", 30]])
    class CsvWriteTool < ::RubyLLM::Tool
      def self.name = 'csv_write'

      description "Write rows to a CSV file. Provide rows as an array of arrays (each inner array " \
                  "is a row of cell values, written as strings), with an optional headers array " \
                  "written as the first line. Overwrites an existing file."

      params do
        string :path, description: "Destination CSV path."
        array  :rows, description: "Array of rows; each row is an array of cell values (as strings)." do
          array of: :string
        end
        array :headers, of: :string, description: "Optional column header row, written first.", required: false
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param path [String]
      # @param rows [Array<Array>]
      # @param headers [Array<String>, nil]
      #
      # @return [String, Hash]
      def execute(path:, rows:, headers: nil)
        @logger.info("#{self.class.name}#execute path=#{path.inspect} rows=#{Array(rows).size}")

        return { error: "rows must be an array of arrays" } unless rows.is_a?(Array)
        return { error: "path is a directory: #{path}" } if File.directory?(path)

        all = []
        all << Array(headers) if headers && !Array(headers).empty?
        rows.each { |row| all << Array(row) }

        allowed = SharedTools.execute?(tool: self.class.to_s, stuff: "Write #{rows.size} row(s) to #{path}")
        unless allowed
          @logger.warn("User declined to write CSV to #{path}")
          return { error: "User declined to write the CSV file" }
        end

        FileUtils.mkdir_p(File.dirname(path))
        CSV.open(path, "w") { |csv| all.each { |row| csv << row } }

        "Wrote #{rows.size} row#{rows.size == 1 ? '' : 's'} to #{path}"
      rescue => e
        @logger.error("#{self.class.name} failed: #{e.message}")
        { error: e.message }
      end
    end
  end
end
