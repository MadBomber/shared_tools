# frozen_string_literal: true

require 'csv'
require_relative '../../shared_tools'

module SharedTools
  module Tools
    # Reads a CSV file and returns its rows in a compact, readable form.
    # Read-only.
    #
    # @example
    #   tool = SharedTools::Tools::CsvReadTool.new
    #   tool.execute(path: "./sales.csv")
    #   tool.execute(path: "./sales.csv", headers: false, limit: 10)
    class CsvReadTool < ::RubyLLM::Tool
      MAX_BYTES = 10 * 1024 * 1024
      DEFAULT_LIMIT = 100

      def self.name = 'csv_read'

      description "Read a CSV file and return its rows. By default the first row is treated as a " \
                  "header. Use limit to cap the number of data rows returned."

      params do
        string  :path,    description: "CSV file to read."
        boolean :headers, description: "Treat the first row as column headers. Default true.", required: false
        integer :limit,   description: "Maximum number of data rows to return (default #{DEFAULT_LIMIT}).", required: false
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param path [String]
      # @param headers [Boolean]
      # @param limit [Integer]
      #
      # @return [String, Hash]
      def execute(path:, headers: true, limit: DEFAULT_LIMIT)
        @logger.info("#{self.class.name}#execute path=#{path.inspect} headers=#{headers} limit=#{limit}")

        return { error: "file not found: #{path}" } unless File.exist?(path)
        return { error: "not a file: #{path}" } unless File.file?(path)
        return { error: "file too large (> #{MAX_BYTES} bytes)" } if File.size(path) > MAX_BYTES

        rows = CSV.read(path)
        return "empty CSV" if rows.empty?

        max = limit.to_i
        max = DEFAULT_LIMIT if max <= 0
        render(rows, headers, max)
      rescue CSV::MalformedCSVError => e
        @logger.error("#{self.class.name} malformed CSV: #{e.message}")
        { error: "malformed CSV: #{e.message}" }
      rescue => e
        @logger.error("#{self.class.name} failed: #{e.message}")
        { error: e.message }
      end

      private

      def render(rows, headers, max)
        header = headers ? rows.first : nil
        data = headers ? rows[1..] : rows
        shown = data.first(max)

        lines = []
        lines << "columns: #{header.join(' | ')}" if header
        lines << "#{data.size} row#{data.size == 1 ? '' : 's'}#{data.size > max ? " (showing #{max})" : ''}"
        shown.each_with_index do |row, i|
          lines << if header
                     "#{i + 1}. " + header.zip(row).map { |k, v| "#{k}=#{v}" }.join(", ")
                   else
                     "#{i + 1}. " + row.join(" | ")
                   end
        end
        lines.join("\n")
      end
    end
  end
end
