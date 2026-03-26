# frozen_string_literal: true

require 'time'
require_relative '../../shared_tools'

module SharedTools
  module Tools
    # Returns the current date, time, and timezone from the local system.
    #
    # @example
    #   tool = SharedTools::Tools::CurrentDateTimeTool.new
    #   tool.execute                    # full output
    #   tool.execute(format: 'date')    # date fields only
    class CurrentDateTimeTool < ::RubyLLM::Tool
      def self.name = 'current_date_time_tool'

      description <<~DESC
        Returns the current date, time, timezone, and calendar metadata from the system clock.

        Supported formats:
        - 'full'    (default) — all fields: date, time, timezone, ISO 8601, unix timestamp, DST flag
        - 'date'    — year, month, day, day_of_week, week_of_year, quarter, ordinal_day
        - 'time'    — hour, minute, second, timezone, utc_offset
        - 'iso8601' — iso8601, iso8601_utc, unix_timestamp
      DESC

      params do
        string :format, required: false, description: <<~DESC.strip
          Output format. Options: 'full' (default), 'date', 'time', 'iso8601'.
        DESC
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param format [String] output format
      # @return [Hash] date/time information
      def execute(format: 'full')
        @logger.info("CurrentDateTimeTool#execute format=#{format}")

        now = Time.now
        utc = now.utc

        date_info = {
          year:            now.year,
          month:           now.month,
          day:             now.day,
          day_of_week:     now.strftime('%A'),
          day_of_week_num: now.wday,
          week_of_year:    now.strftime('%U').to_i,
          quarter:         ((now.month - 1) / 3) + 1,
          ordinal_day:     now.yday
        }

        time_info = {
          hour:             now.hour,
          minute:           now.min,
          second:           now.sec,
          timezone:         now.zone,
          utc_offset:       now.strftime('%z'),
          utc_offset_hours: (now.utc_offset / 3600.0).round(2)
        }

        iso_info = {
          iso8601:       now.iso8601,
          iso8601_utc:   utc.iso8601,
          unix_timestamp: now.to_i
        }

        case format.to_s.downcase
        when 'date'
          { success: true }.merge(date_info)
        when 'time'
          { success: true }.merge(time_info)
        when 'iso8601'
          { success: true }.merge(iso_info)
        else
          { success: true, dst: now.dst? }
            .merge(date_info)
            .merge(time_info)
            .merge(iso_info)
        end
      end
    end
  end
end
