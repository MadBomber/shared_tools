# frozen_string_literal: true

require 'ruby_llm/tool'
require 'time'

module SharedTools
  module Tools
    # A tool for parsing, validating, and explaining cron expressions.
    # Supports standard 5-field cron format (minute, hour, day of month, month, day of week).
    #
    # @example
    #   tool = SharedTools::Tools::CronTool.new
    #   result = tool.execute(action: 'parse', expression: '0 9 * * 1-5')
    #   puts result[:description]  # "At 09:00, Monday through Friday"
    class CronTool < RubyLLM::Tool
      def self.name = 'cron'

      description <<~'DESCRIPTION'
        Parse, validate, and explain cron expressions.

        Supports standard 5-field cron format:
        - minute (0-59)
        - hour (0-23)
        - day of month (1-31)
        - month (1-12 or JAN-DEC)
        - day of week (0-7 or SUN-SAT, where 0 and 7 are Sunday)

        Special characters supported:
        - * (any value)
        - , (value list separator)
        - - (range of values)
        - / (step values)

        Actions:
        - 'parse': Parse and explain a cron expression
        - 'validate': Check if a cron expression is valid
        - 'next': Calculate the next N execution times
        - 'generate': Generate a cron expression from a description

        Example usage:
          tool = SharedTools::Tools::CronTool.new

          # Parse and explain
          tool.execute(action: 'parse', expression: '0 9 * * 1-5')
          # => "At 09:00, Monday through Friday"

          # Validate
          tool.execute(action: 'validate', expression: '0 9 * * *')
          # => { valid: true }

          # Get next execution times
          tool.execute(action: 'next', expression: '0 * * * *', count: 5)

          # Generate from description
          tool.execute(action: 'generate', description: 'every day at 9am')
      DESCRIPTION

      params do
        string :action, description: <<~DESC.strip
          The action to perform:
          - 'parse': Parse and explain a cron expression
          - 'validate': Check if expression is valid
          - 'next': Calculate next execution times
          - 'generate': Generate expression from description
        DESC

        string :expression, description: <<~DESC.strip, required: false
          The cron expression to parse, validate, or calculate.
          Required for 'parse', 'validate', and 'next' actions.
        DESC

        string :description, description: <<~DESC.strip, required: false
          Human-readable schedule description for 'generate' action.
          Examples: 'every day at 9am', 'every monday at noon', 'every 5 minutes'
        DESC

        integer :count, description: <<~DESC.strip, required: false
          Number of next execution times to return for 'next' action.
          Default: 5, Maximum: 20
        DESC
      end

      DAYS_OF_WEEK = {
        'SUN' => 0, 'MON' => 1, 'TUE' => 2, 'WED' => 3,
        'THU' => 4, 'FRI' => 5, 'SAT' => 6
      }.freeze

      MONTHS = {
        'JAN' => 1, 'FEB' => 2, 'MAR' => 3, 'APR' => 4,
        'MAY' => 5, 'JUN' => 6, 'JUL' => 7, 'AUG' => 8,
        'SEP' => 9, 'OCT' => 10, 'NOV' => 11, 'DEC' => 12
      }.freeze

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # Execute cron action
      #
      # @param action [String] action to perform
      # @param expression [String, nil] cron expression
      # @param description [String, nil] schedule description for generate
      # @param count [Integer, nil] number of next executions
      # @return [Hash] result
      def execute(action:, expression: nil, description: nil, count: nil)
        @logger.info("CronTool#execute action=#{action.inspect}")

        case action.to_s.downcase
        when 'parse'
          parse_expression(expression)
        when 'validate'
          validate_expression(expression)
        when 'next'
          next_executions(expression, count || 5)
        when 'generate'
          generate_expression(description)
        else
          {
            success: false,
            error: "Unknown action: #{action}. Valid actions are: parse, validate, next, generate"
          }
        end
      rescue => e
        @logger.error("CronTool error: #{e.message}")
        {
          success: false,
          error: e.message
        }
      end

      private

      def parse_expression(expression)
        return { success: false, error: "Expression is required" } if expression.nil? || expression.empty?

        validation = validate_expression(expression)
        return validation unless validation[:valid]

        parts = expression.strip.split(/\s+/)
        minute, hour, dom, month, dow = parts

        {
          success: true,
          expression: expression,
          fields: {
            minute: minute,
            hour: hour,
            day_of_month: dom,
            month: month,
            day_of_week: dow
          },
          description: build_description(minute, hour, dom, month, dow),
          expanded: {
            minutes: expand_field(minute, 0, 59),
            hours: expand_field(hour, 0, 23),
            days_of_month: expand_field(dom, 1, 31),
            months: expand_field(month, 1, 12),
            days_of_week: expand_field(dow, 0, 6)
          }
        }
      end

      def validate_expression(expression)
        return { valid: false, error: "Expression is required" } if expression.nil? || expression.empty?

        parts = expression.strip.split(/\s+/)

        unless parts.length == 5
          return {
            valid: false,
            error: "Invalid cron expression: expected 5 fields, got #{parts.length}"
          }
        end

        minute, hour, dom, month, dow = parts

        errors = []
        errors << validate_field(minute, 0, 59, 'minute')
        errors << validate_field(hour, 0, 23, 'hour')
        errors << validate_field(dom, 1, 31, 'day of month')
        errors << validate_field(month, 1, 12, 'month')
        errors << validate_field(dow, 0, 7, 'day of week')

        errors.compact!

        if errors.empty?
          { valid: true, expression: expression }
        else
          { valid: false, errors: errors }
        end
      end

      def next_executions(expression, count)
        return { success: false, error: "Expression is required" } if expression.nil? || expression.empty?

        validation = validate_expression(expression)
        return { success: false, error: validation[:errors]&.join(', ') || validation[:error] } unless validation[:valid]

        count = [[count.to_i, 1].max, 20].min

        parts = expression.strip.split(/\s+/)
        minute_spec, hour_spec, dom_spec, month_spec, dow_spec = parts

        minutes = expand_field(minute_spec, 0, 59)
        hours = expand_field(hour_spec, 0, 23)
        doms = expand_field(dom_spec, 1, 31)
        months = expand_field(month_spec, 1, 12)
        dows = expand_field(dow_spec, 0, 6)

        executions = []
        current = Time.now + 60 # Start from next minute

        max_iterations = 366 * 24 * 60 # One year of minutes max
        iterations = 0

        while executions.length < count && iterations < max_iterations
          iterations += 1

          if matches_cron?(current, minutes, hours, doms, months, dows)
            executions << current.strftime('%Y-%m-%d %H:%M')
            current += 60
          else
            current += 60
          end
        end

        {
          success: true,
          expression: expression,
          count: executions.length,
          next_executions: executions
        }
      end

      def generate_expression(description)
        return { success: false, error: "Description is required" } if description.nil? || description.empty?

        desc = description.downcase.strip
        expression = nil

        # Common patterns - more specific patterns must come before general ones
        case desc
        when /every\s+minute/
          expression = '* * * * *'
        when /every\s+(\d+)\s+minutes?/
          interval = $1.to_i
          expression = "*/#{interval} * * * *"
        when /every\s+hour/
          expression = '0 * * * *'
        when /every\s+(\d+)\s+hours?/
          interval = $1.to_i
          expression = "0 */#{interval} * * *"
        when /every\s+day\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?/
          hour, min, ampm = $1.to_i, ($2 || '0').to_i, $3
          hour += 12 if ampm == 'pm' && hour != 12
          hour = 0 if ampm == 'am' && hour == 12
          expression = "#{min} #{hour} * * *"
        when /every\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?/
          day_name = $1.upcase[0..2]
          day_num = DAYS_OF_WEEK[day_name]
          hour, min, ampm = $2.to_i, ($3 || '0').to_i, $4
          hour += 12 if ampm == 'pm' && hour != 12
          hour = 0 if ampm == 'am' && hour == 12
          expression = "#{min} #{hour} * * #{day_num}"
        when /every\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)/
          day_name = $1.upcase[0..2]
          day_num = DAYS_OF_WEEK[day_name]
          expression = "0 0 * * #{day_num}"
        when /weekdays?\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?/
          hour, min, ampm = $1.to_i, ($2 || '0').to_i, $3
          hour += 12 if ampm == 'pm' && hour != 12
          hour = 0 if ampm == 'am' && hour == 12
          expression = "#{min} #{hour} * * 1-5"
        when /weekends?\s+at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?/
          hour, min, ampm = $1.to_i, ($2 || '0').to_i, $3
          hour += 12 if ampm == 'pm' && hour != 12
          hour = 0 if ampm == 'am' && hour == 12
          expression = "#{min} #{hour} * * 0,6"
        when /at\s+noon/
          expression = '0 12 * * *'
        when /at\s+midnight/
          expression = '0 0 * * *'
        when /monthly|first\s+of\s+(the\s+)?month/
          expression = '0 0 1 * *'
        when /yearly|annually/
          expression = '0 0 1 1 *'
        when /hourly\s+at\s+:?(\d{2})/
          min = $1.to_i
          expression = "#{min} * * * *"
        end

        if expression
          parsed = parse_expression(expression)
          {
            success: true,
            description: description,
            expression: expression,
            explanation: parsed[:description]
          }
        else
          {
            success: false,
            error: "Could not parse description: '#{description}'. Try formats like 'every day at 9am', 'every monday at noon', 'every 5 minutes'"
          }
        end
      end

      def validate_field(field, min, max, name)
        return nil if field == '*'

        # Handle step values
        if field.include?('/')
          base, step = field.split('/')
          return "Invalid step value in #{name}" unless step =~ /^\d+$/ && step.to_i > 0
          return validate_field(base, min, max, name) unless base == '*'
          return nil
        end

        # Handle ranges
        if field.include?('-')
          parts = field.split('-')
          return "Invalid range in #{name}" unless parts.length == 2
          start_val = normalize_value(parts[0], name)
          end_val = normalize_value(parts[1], name)
          return "Invalid range values in #{name}" if start_val.nil? || end_val.nil?
          return "Range out of bounds in #{name}" if start_val < min || end_val > max || start_val > end_val
          return nil
        end

        # Handle lists
        if field.include?(',')
          field.split(',').each do |val|
            err = validate_field(val.strip, min, max, name)
            return err if err
          end
          return nil
        end

        # Single value
        val = normalize_value(field, name)
        return "Invalid value '#{field}' in #{name}" if val.nil?
        return "Value #{val} out of bounds (#{min}-#{max}) in #{name}" if val < min || val > max

        nil
      end

      def normalize_value(val, field_name)
        return nil if val.nil? || val.empty?

        # Handle day of week names
        if %w[day\ of\ week].include?(field_name)
          return DAYS_OF_WEEK[val.upcase] if DAYS_OF_WEEK.key?(val.upcase)
        end

        # Handle month names
        if field_name == 'month'
          return MONTHS[val.upcase] if MONTHS.key?(val.upcase)
        end

        return val.to_i if val =~ /^\d+$/

        nil
      end

      def expand_field(field, min, max)
        return (min..max).to_a if field == '*'

        if field.include?('/')
          base, step = field.split('/')
          step = step.to_i
          start_vals = base == '*' ? (min..max).to_a : expand_field(base, min, max)
          return start_vals.select { |v| (v - start_vals.first) % step == 0 }
        end

        if field.include?(',')
          return field.split(',').flat_map { |f| expand_field(f.strip, min, max) }.sort.uniq
        end

        if field.include?('-')
          start_val, end_val = field.split('-').map { |v| normalize_value(v, '') || v.to_i }
          return (start_val..end_val).to_a
        end

        [normalize_value(field, '') || field.to_i]
      end

      def matches_cron?(time, minutes, hours, doms, months, dows)
        return false unless minutes.include?(time.min)
        return false unless hours.include?(time.hour)
        return false unless months.include?(time.month)

        # Day matching: either day of month OR day of week must match
        # (unless both are specified as specific values)
        dom_match = doms.include?(time.day)
        dow_match = dows.include?(time.wday)

        dom_match || dow_match
      end

      def build_description(minute, hour, dom, month, dow)
        parts = []

        # Time part
        time_desc = describe_time(minute, hour)
        parts << time_desc if time_desc

        # Day of month part
        if dom != '*'
          parts << "on day #{describe_field(dom)} of the month"
        end

        # Month part
        if month != '*'
          month_names = expand_field(month, 1, 12).map { |m| Date::MONTHNAMES[m] }
          parts << "in #{month_names.join(', ')}"
        end

        # Day of week part
        if dow != '*'
          day_names = expand_field(dow, 0, 6).map { |d| Date::DAYNAMES[d] }
          if day_names == %w[Monday Tuesday Wednesday Thursday Friday]
            parts << "on weekdays"
          elsif day_names == %w[Sunday Saturday]
            parts << "on weekends"
          else
            parts << "on #{day_names.join(', ')}"
          end
        end

        parts.empty? ? "Every minute" : parts.join(', ')
      end

      def describe_time(minute, hour)
        if minute == '*' && hour == '*'
          return nil # Every minute, handled by default
        end

        if minute == '*'
          hours = expand_field(hour, 0, 23)
          return "Every minute during hour(s) #{hours.join(', ')}"
        end

        if hour == '*'
          minutes = expand_field(minute, 0, 59)
          if minute.include?('/')
            return "Every #{minute.split('/').last} minutes"
          end
          return "At minute #{minutes.join(', ')} of every hour"
        end

        hours = expand_field(hour, 0, 23)
        minutes = expand_field(minute, 0, 59)

        times = hours.flat_map do |h|
          minutes.map { |m| format('%02d:%02d', h, m) }
        end

        "At #{times.join(', ')}"
      end

      def describe_field(field)
        return 'every' if field == '*'

        if field.include?('/')
          base, step = field.split('/')
          return "every #{step}#{base == '*' ? '' : " starting at #{base}"}"
        end

        field
      end
    end
  end
end
