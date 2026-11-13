# frozen_string_literal: true

require 'time'
require_relative '../../shared_tools'

module SharedTools
  module Tools
    # Parse, validate, explain, and generate cron expressions.
    #
    # @example
    #   tool = SharedTools::Tools::CronTool.new
    #   tool.execute(action: 'parse',      expression: '0 9 * * 1-5')
    #   tool.execute(action: 'validate',   expression: '*/15 * * * *')
    #   tool.execute(action: 'next_times', expression: '0 * * * *', count: 5)
    #   tool.execute(action: 'generate',   description: 'every day at 9am')
    class CronTool < ::RubyLLM::Tool
      def self.tool_name = 'cron'

      description <<~DESC
        Parse, validate, explain, and generate cron expressions (standard 5-field format).

        Actions:
        - 'parse'      — Parse and explain a cron expression
        - 'validate'   — Check whether a cron expression is valid
        - 'next_times' — List the next N execution times (default 5)
        - 'generate'   — Generate a cron expression from a natural language description

        Cron format: minute hour day month weekday
          - Each field accepts: number, range (1-5), list (1,3,5), step (*/15), or wildcard (*)
          - Weekday: 0-7 (0 and 7 both mean Sunday)

        Generate examples: 'every day at 9am', 'every monday at noon', 'every 15 minutes',
                           'every weekday', 'first day of every month at midnight'
      DESC

      parameters do
        string  :action,      description: "Action: 'parse', 'validate', 'next_times', 'generate'"
        string  :expression,  required: false, description: "5-field cron expression. Required for parse, validate, next_times."
        integer :count,       required: false, description: "Number of next execution times. Default: 5."
        string  :description, required: false, description: "Natural language schedule description. Required for generate."
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param action      [String]       action to perform
      # @param expression  [String, nil]  cron expression
      # @param count       [Integer, nil] number of times for next_times
      # @param description [String, nil]  natural language description for generate
      # @return [Hash] result
      def execute(action:, expression: nil, count: nil, description: nil)
        @logger.info("CronTool#execute action=#{action}")

        case action.to_s.downcase
        when 'parse'      then parse_expression(expression)
        when 'validate'   then validate_expression(expression)
        when 'next_times' then next_times(expression, (count || 5).to_i)
        when 'generate'   then generate_expression(description)
        else
          { success: false, error: "Unknown action '#{action}'. Use: parse, validate, next_times, generate" }
        end
      rescue => e
        @logger.error("CronTool error: #{e.message}")
        { success: false, error: e.message }
      end

      private

      FIELD_NAMES   = %w[minute hour day month weekday].freeze
      FIELD_RANGES  = {
        'minute'  => 0..59,
        'hour'    => 0..23,
        'day'     => 1..31,
        'month'   => 1..12,
        'weekday' => 0..7
      }.freeze
      DAY_NAMES     = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze
      MONTH_NAMES   = %w[January February March April May June July August
                         September October November December].freeze

      # -------------------------------------------------------------------------
      # Action implementations
      # -------------------------------------------------------------------------

      def parse_expression(expr)
        require_expr!(expr)
        parts = split_expr(expr)
        fields = {}
        FIELD_NAMES.zip(parts).each do |name, raw|
          fields[name] = { raw: raw, values: expand_field(raw, FIELD_RANGES[name]) }
        end
        { success: true, valid: true, expression: expr, fields: fields, explanation: explain(parts) }
      rescue ArgumentError => e
        { success: false, valid: false, expression: expr, error: e.message }
      end

      def validate_expression(expr)
        require_expr!(expr)
        parts = split_expr(expr)
        FIELD_NAMES.zip(parts).each { |name, raw| expand_field(raw, FIELD_RANGES[name]) }
        { success: true, valid: true, expression: expr, explanation: explain(parts) }
      rescue ArgumentError => e
        { success: true, valid: false, expression: expr, error: e.message }
      end

      def next_times(expr, count)
        require_expr!(expr)
        parts = split_expr(expr)

        sets = FIELD_NAMES.map.with_index { |name, i| expand_field(parts[i], FIELD_RANGES[name]) }
        mins_set, hrs_set, days_set, months_set, wdays_set = sets

        # Normalise Sunday: weekday 7 == 0
        wdays_set = wdays_set.map { |d| d == 7 ? 0 : d }.uniq.sort

        times  = []
        t      = next_minute(Time.now)
        limit  = 527_040 # 1 year of minutes — safety cap

        while times.size < count && limit > 0
          limit -= 1
          if months_set.include?(t.month) &&
             day_matches?(t, days_set, wdays_set, parts[2], parts[4]) &&
             hrs_set.include?(t.hour) &&
             mins_set.include?(t.min)
            times << t.strftime('%Y-%m-%d %H:%M (%A)')
          end
          t += 60
        end

        { success: true, expression: expr, explanation: explain(parts), next_times: times }
      end

      def generate_expression(desc)
        raise ArgumentError, "description is required for the generate action" if desc.nil? || desc.strip.empty?

        d    = desc.downcase
        expr = match_pattern(d)

        if expr
          parts = expr.split
          { success: true, description: desc, expression: expr, explanation: explain(parts) }
        else
          {
            success: false,
            description: desc,
            error: "Could not generate an expression from that description. " \
                   "Try: 'every day at 9am', 'every monday at noon', 'every 15 minutes', " \
                   "'every weekday', 'first day of every month at midnight'."
          }
        end
      end

      # -------------------------------------------------------------------------
      # Pattern matching for generate
      # -------------------------------------------------------------------------

      def match_pattern(d)
        return '* * * * *' if d.include?('every minute')

        if (m = d.match(/every\s+(\d+)\s+minutes?/))
          return "*/#{m[1]} * * * *"
        end

        if d.match?(/every\s+hour\b/) && !d.match?(/\d+\s+hours?/)
          return '0 * * * *'
        end

        if (m = d.match(/every\s+(\d+)\s+hours?/))
          return "0 */#{m[1]} * * *"
        end

        return '0 9 * * 1-5' if d.include?('weekday')
        return '0 0 * * 0,6' if d.include?('weekend')

        day_pattern = DAY_NAMES.map(&:downcase).join('|')

        if (m = d.match(/every\s+(#{day_pattern})\s+at\s+(\d+)(?::(\d+))?\s*(am|pm)?/))
          day_num = DAY_NAMES.map(&:downcase).index(m[1])
          return "#{hm_to_cron(m[2], m[3], m[4])} * * #{day_num}"
        end

        if (m = d.match(/every\s+(#{day_pattern})\s+at\s+noon/))
          day_num = DAY_NAMES.map(&:downcase).index(m[1])
          return "0 12 * * #{day_num}"
        end

        if (m = d.match(/every\s+(#{day_pattern})/))
          day_num = DAY_NAMES.map(&:downcase).index(m[1])
          return "0 0 * * #{day_num}"
        end

        return '0 12 * * *'  if d.include?('noon')
        return '0 0 * * *'   if d.include?('midnight')

        if (m = d.match(/every\s+day\s+at\s+(\d+)(?::(\d+))?\s*(am|pm)?/))
          return "#{hm_to_cron(m[1], m[2], m[3])} * * *"
        end

        if (m = d.match(/first\s+day\s+(?:of\s+(?:every\s+)?month\s+)?at\s+(\d+)(?::(\d+))?\s*(am|pm)?/))
          return "#{hm_to_cron(m[1], m[2], m[3])} 1 * *"
        end

        return '0 0 1 * *' if d.match?(/first\s+day/)

        nil
      end

      # Convert hour/minute/ampm strings to "min hour" cron tokens.
      def hm_to_cron(h, m, ap)
        hour = h.to_i
        min  = (m || '0').to_i
        hour += 12 if ap == 'pm' && hour != 12
        hour  = 0  if ap == 'am' && hour == 12
        "#{min} #{hour}"
      end

      # -------------------------------------------------------------------------
      # Field expansion
      # -------------------------------------------------------------------------

      # Expand one cron field to a sorted array of integers.
      def expand_field(value, range)
        return range.to_a if value == '*'

        result = []
        value.split(',', -1).each do |part|
          if part.include?('/')
            base_str, step_str, extra = part.split('/', -1)
            raise ArgumentError, "Invalid step expression '#{part}'" if extra
            step = parse_number(step_str)
            raise ArgumentError, "Step must be >= 1, got #{step}" if step < 1
            base_set = base_str == '*' ? range.to_a : expand_range_part(base_str, range)
            result.concat(base_set.each_with_index.filter_map { |v, i| v if (i % step).zero? })
          elsif part.include?('-')
            result.concat(expand_range_part(part, range))
          else
            v = parse_number(part)
            unless range_with_sunday(range).cover?(v)
              raise ArgumentError, "Value #{v} is out of range #{range}"
            end
            result << v
          end
        end

        result.uniq.sort
      end

      # Expand "a-b" to a..b, or a bare start "a" (the base of "a/step") to
      # a..range.last. Both ends must be in bounds and a must not exceed b.
      def expand_range_part(str, range)
        bounds = range_with_sunday(range)

        if str.include?('-')
          a_str, b_str, extra = str.split('-', -1)
          raise ArgumentError, "Invalid range '#{str}'" if extra
          a = parse_number(a_str)
          b = parse_number(b_str)
          unless bounds.cover?(a) && bounds.cover?(b)
            raise ArgumentError, "Range #{str} is out of bounds for #{range}"
          end
          raise ArgumentError, "Range #{str} is reversed; the start must not exceed the end" if a > b
          (a..b).to_a
        else
          v = parse_number(str)
          raise ArgumentError, "Value #{v} is out of range #{range}" unless bounds.cover?(v)
          (v..range.last).to_a
        end
      end

      # Parse a decimal cron number. Anything else, such as "MON", "1x" or an
      # empty string, raises ArgumentError instead of quietly becoming 0.
      def parse_number(str)
        unless str.is_a?(String) && str.match?(/\A\d+\z/)
          raise ArgumentError, "Invalid number '#{str}' in cron field; only numeric values are supported"
        end
        Integer(str, 10)
      end

      # Day-of-month and day-of-week follow Vixie cron: when both fields are
      # restricted (neither starts with '*'), a day matches if EITHER does;
      # otherwise both must match (the '*' side matches every day anyway).
      def day_matches?(time, days_set, wdays_set, day_field, weekday_field)
        dom = days_set.include?(time.day)
        dow = wdays_set.include?(time.wday)

        if day_field.start_with?('*') || weekday_field.start_with?('*')
          dom && dow
        else
          dom || dow
        end
      end

      # Allow weekday 7 (Sunday alias)
      def range_with_sunday(range)
        range == FIELD_RANGES['weekday'] ? (0..7) : range
      end

      # -------------------------------------------------------------------------
      # Human-readable explanation
      # -------------------------------------------------------------------------

      def explain(parts)
        min, hour, day, month, weekday = parts
        segments = []

        segments << if min == '*'           then 'every minute'
                    elsif min.start_with?('*/') then "every #{min[2..]} minutes"
                    else                         "at minute #{min}"
                    end

        segments << if hour == '*'            then 'of every hour'
                    elsif hour.start_with?('*/') then "every #{hour[2..]} hours"
                    else                           "at #{fmt_hour(hour)}"
                    end

        segments << "on day #{day} of the month"  unless day == '*'
        segments << "in #{fmt_month(month)}"       unless month == '*'
        segments << "on #{fmt_weekday(weekday)}"   unless weekday == '*'

        segments.join(', ')
      end

      def fmt_hour(h)
        return h if h.match?(/[,\-\/]/)
        n    = h.to_i
        disp = n == 0 ? 12 : (n > 12 ? n - 12 : n)
        ampm = n < 12 ? 'AM' : 'PM'
        "#{disp}:00 #{ampm}"
      end

      def fmt_month(m)
        return m if m.match?(/[,\-\/]/)
        MONTH_NAMES[m.to_i - 1] || m
      end

      def fmt_weekday(w)
        return 'weekdays (Mon–Fri)' if w == '1-5'
        return w if w.match?(/[,\/]/)
        return w if w.include?('-')
        DAY_NAMES[w.to_i % 7] || w
      end

      # -------------------------------------------------------------------------
      # Helpers
      # -------------------------------------------------------------------------

      # The start of the minute after +time+. Works from epoch seconds, so
      # hh:59 rolls over to the next hour (and day, month, year).
      def next_minute(time)
        Time.at((time.to_i / 60 + 1) * 60)
      end

      def require_expr!(expr)
        raise ArgumentError, "expression is required for this action" if expr.nil? || expr.strip.empty?
      end

      def split_expr(expr)
        parts = expr.strip.split(/\s+/)
        raise ArgumentError, "Cron expression must have 5 fields, got #{parts.size}" unless parts.size == 5
        parts
      end
    end
  end
end
