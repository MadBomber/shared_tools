# frozen_string_literal: true

require 'ruby_llm/tool'
require 'time'

module SharedTools
  module Tools
    # A tool that returns the current date, time, and timezone information.
    # Useful for AI assistants that need to know the current time context.
    #
    # @example
    #   tool = SharedTools::Tools::CurrentDateTimeTool.new
    #   result = tool.execute
    #   puts result[:date]      # "2025-12-17"
    #   puts result[:time]      # "13:45:30"
    #   puts result[:timezone]  # "America/Chicago"
    class CurrentDateTimeTool < RubyLLM::Tool
      def self.name = 'current_date_time'

      description <<~'DESCRIPTION'
        Returns the current date, time, and timezone information from the system.
        This tool provides accurate temporal context for AI assistants that need
        to reason about time-sensitive information or schedule-related queries.

        The tool returns:
        - Current date in ISO 8601 format (YYYY-MM-DD)
        - Current time in 24-hour format (HH:MM:SS)
        - Current timezone name and UTC offset
        - Unix timestamp for precise time calculations
        - Day of week and week number for scheduling context

        Example usage:
          tool = SharedTools::Tools::CurrentDateTimeTool.new
          result = tool.execute
          puts "Today is #{result[:day_of_week]}, #{result[:date]}"
          puts "Current time: #{result[:time]} #{result[:timezone]}"
      DESCRIPTION

      params do
        string :format, description: <<~DESC.strip, required: false
          Output format preference. Options:
          - 'full' (default): Returns all date/time information
          - 'date_only': Returns only date-related fields
          - 'time_only': Returns only time-related fields
          - 'iso8601': Returns a single ISO 8601 formatted datetime string
        DESC
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # Execute the date/time query
      #
      # @param format [String] Output format ('full', 'date_only', 'time_only', 'iso8601')
      # @return [Hash] Current date/time information
      def execute(format: 'full')
        @logger.info("DateTimeTool#execute format=#{format.inspect}")

        now = Time.now

        case format.to_s.downcase
        when 'date_only'
          date_only_response(now)
        when 'time_only'
          time_only_response(now)
        when 'iso8601'
          iso8601_response(now)
        else
          full_response(now)
        end
      end

      private

      # Full response with all date/time information
      def full_response(now)
        {
          success:       true,
          date:          now.strftime('%Y-%m-%d'),
          time:          now.strftime('%H:%M:%S'),
          datetime:      now.iso8601,
          timezone:      now.zone,
          timezone_name: timezone_name(now),
          utc_offset:    formatted_utc_offset(now),
          unix_timestamp: now.to_i,
          day_of_week:   now.strftime('%A'),
          day_of_year:   now.yday,
          week_number:   now.strftime('%V').to_i,
          is_dst:        now.dst?,
          quarter:       ((now.month - 1) / 3) + 1
        }
      end

      # Date-only response
      def date_only_response(now)
        {
          success:     true,
          date:        now.strftime('%Y-%m-%d'),
          year:        now.year,
          month:       now.month,
          month_name:  now.strftime('%B'),
          day:         now.day,
          day_of_week: now.strftime('%A'),
          day_of_year: now.yday,
          week_number: now.strftime('%V').to_i,
          quarter:     ((now.month - 1) / 3) + 1
        }
      end

      # Time-only response
      def time_only_response(now)
        {
          success:        true,
          time:           now.strftime('%H:%M:%S'),
          time_12h:       now.strftime('%I:%M:%S %p'),
          hour:           now.hour,
          minute:         now.min,
          second:         now.sec,
          timezone:       now.zone,
          timezone_name:  timezone_name(now),
          utc_offset:     formatted_utc_offset(now),
          unix_timestamp: now.to_i,
          is_dst:         now.dst?
        }
      end

      # ISO 8601 formatted response
      def iso8601_response(now)
        {
          success:  true,
          datetime: now.iso8601,
          utc:      now.utc.iso8601
        }
      end

      # Get the IANA timezone name if available
      def timezone_name(time)
        # Try to get IANA timezone from TZ environment variable
        ENV['TZ'] || time.zone
      end

      # Format UTC offset as "+HH:MM" or "-HH:MM"
      def formatted_utc_offset(time)
        offset_seconds = time.utc_offset
        sign = offset_seconds >= 0 ? '+' : '-'
        hours, remainder = offset_seconds.abs.divmod(3600)
        minutes = remainder / 60
        format('%s%02d:%02d', sign, hours, minutes)
      end
    end
  end
end
