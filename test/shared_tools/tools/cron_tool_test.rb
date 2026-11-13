# frozen_string_literal: true

require "test_helper"

class CronToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::CronTool.new
  end

  def test_tool_name
    assert_equal 'cron', SharedTools::Tools::CronTool.tool_name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  # parse action
  def test_parse_valid_expression
    result = @tool.execute(action: 'parse', expression: '0 9 * * 1-5')
    assert result[:success]
    assert result[:expression]
    assert result[:explanation]
  end

  def test_parse_every_minute
    result = @tool.execute(action: 'parse', expression: '* * * * *')
    assert result[:success]
    assert_includes result[:explanation].downcase, 'minute'
  end

  def test_parse_missing_expression_returns_error
    result = @tool.execute(action: 'parse', expression: nil)
    refute result[:success]
    assert result[:error]
  end

  def test_parse_invalid_expression_returns_error
    result = @tool.execute(action: 'parse', expression: 'not a cron')
    refute result[:success]
    assert result[:error]
  end

  # validate action
  def test_validate_valid_expression
    result = @tool.execute(action: 'validate', expression: '*/15 * * * *')
    assert result[:success]
    assert result[:valid]
    assert_equal '*/15 * * * *', result[:expression]
  end

  def test_validate_invalid_expression
    result = @tool.execute(action: 'validate', expression: '99 99 99 99 99')
    assert result[:success]   # validate always returns success:true; valid: is the flag
    refute result[:valid]
    assert result[:error]     # singular :error, not :errors
  end

  def test_validate_missing_expression_returns_error
    # nil expression: require_expr! raises, rescued inside validate_expression
    result = @tool.execute(action: 'validate', expression: nil)
    # validate rescues to {success: true, valid: false} when expression is missing
    refute result[:valid]
  end

  # next_times action
  def test_next_times_returns_list
    result = @tool.execute(action: 'next_times', expression: '0 * * * *', count: 3)
    assert result[:success]
    assert result[:next_times]
    assert_equal 3, result[:next_times].length
  end

  def test_next_times_default_count_is_5
    result = @tool.execute(action: 'next_times', expression: '0 * * * *')
    assert result[:success]
    assert_equal 5, result[:next_times].length
  end

  def test_next_times_are_in_future
    result = @tool.execute(action: 'next_times', expression: '0 * * * *', count: 2)
    assert result[:success]
    result[:next_times].each do |t|
      assert Time.parse(t) > Time.now, "Expected #{t} to be in the future"
    end
  end

  def test_next_times_are_sorted_ascending
    result = @tool.execute(action: 'next_times', expression: '*/30 * * * *', count: 4)
    assert result[:success]
    times = result[:next_times].map { |t| Time.parse(t) }
    assert_equal times.sort, times
  end

  # field parsing (#26)
  def test_validate_rejects_non_numeric_weekday
    result = @tool.execute(action: 'validate', expression: '0 9 * * MON')
    refute result[:valid]
    assert_includes result[:error], 'MON'
  end

  def test_validate_rejects_non_numeric_tokens_in_any_field
    ['x * * * *', '0 9a * * *', '0 9 1, * *', '*/x * * * *', '1-x * * * *'].each do |expr|
      refute @tool.execute(action: 'validate', expression: expr)[:valid], "expected #{expr.inspect} to be invalid"
    end
  end

  def test_validate_rejects_out_of_bounds_stepped_range
    result = @tool.execute(action: 'validate', expression: '0-99/5 * * * *')
    refute result[:valid]
    assert_includes result[:error], 'out of bounds'
  end

  def test_validate_rejects_out_of_bounds_step_start
    refute @tool.execute(action: 'validate', expression: '75/5 * * * *')[:valid]
  end

  def test_validate_rejects_reversed_range
    result = @tool.execute(action: 'validate', expression: '5-1 * * * *')
    refute result[:valid]
    assert_includes result[:error], 'reversed'
    refute @tool.execute(action: 'validate', expression: '30-10/5 * * * *')[:valid]
  end

  def test_validate_still_accepts_valid_ranges_and_steps
    ['0-30/5 * * * *', '5/15 * * * *', '0 9-17 * * 1-5', '0 0 * * 7', '1,2,3 * * * *'].each do |expr|
      assert @tool.execute(action: 'validate', expression: expr)[:valid], "expected #{expr.inspect} to be valid"
    end
  end

  def test_next_times_matches_day_of_month_or_weekday_when_both_restricted
    Time.stub(:now, Time.new(2026, 1, 1, 0, 0, 30)) do
      result = @tool.execute(action: 'next_times', expression: '0 0 1 * 1', count: 6)
      assert result[:success], result[:error]
      assert_equal ['2026-01-05', '2026-01-12', '2026-01-19', '2026-01-26', '2026-02-01', '2026-02-02'],
                   result[:next_times].map { |t| t[0, 10] }
    end
  end

  def test_day_matches_or_when_both_restricted_and_when_a_field_starts_with_star
    first_sunday = Time.new(2026, 2, 1) # the 1st, a Sunday
    # Day-of-month matches, weekday (Monday) does not.
    assert @tool.send(:day_matches?, first_sunday, [1], [1], '1', '1')
    refute @tool.send(:day_matches?, first_sunday, [1], [1], '1', '*/3')
    assert @tool.send(:day_matches?, first_sunday, (1..31).to_a, [0], '*', '0')
    refute @tool.send(:day_matches?, first_sunday, (1..31).to_a, [1], '*', '1')
  end

  def test_parse_number
    assert_equal 7, @tool.send(:parse_number, '07')
    assert_raises(ArgumentError) { @tool.send(:parse_number, 'MON') }
    assert_raises(ArgumentError) { @tool.send(:parse_number, '') }
    assert_raises(ArgumentError) { @tool.send(:parse_number, nil) }
    assert_raises(ArgumentError) { @tool.send(:parse_number, '-1') }
  end

  # generate action
  def test_generate_returns_expression
    result = @tool.execute(action: 'generate', description: 'every day at 9am')
    assert result[:success]
    assert result[:expression]
    # Should look like a valid cron expression (5 fields)
    assert_match(/\A\S+ \S+ \S+ \S+ \S+\z/, result[:expression])
  end

  def test_generate_missing_description_returns_error
    result = @tool.execute(action: 'generate', description: nil)
    refute result[:success]
    assert result[:error]
  end

  # unknown action
  def test_unknown_action_returns_error
    result = @tool.execute(action: 'explode', expression: '* * * * *')
    refute result[:success]
    assert result[:error]
    assert_includes result[:error], 'Unknown action'
  end
end
