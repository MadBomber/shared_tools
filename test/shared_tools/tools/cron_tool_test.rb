# frozen_string_literal: true

require "test_helper"

class CronToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::CronTool.new
  end

  def test_tool_name
    assert_equal 'cron', SharedTools::Tools::CronTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_can_instantiate_without_arguments
    tool = SharedTools::Tools::CronTool.new
    assert_instance_of SharedTools::Tools::CronTool, tool
  end

  # Parse action tests

  def test_parse_simple_expression
    result = @tool.execute(action: 'parse', expression: '0 9 * * *')

    assert result[:success]
    assert_equal '0 9 * * *', result[:expression]
    assert result[:fields]
    assert_equal '0', result[:fields][:minute]
    assert_equal '9', result[:fields][:hour]
    assert result[:description]
  end

  def test_parse_weekday_expression
    result = @tool.execute(action: 'parse', expression: '0 9 * * 1-5')

    assert result[:success]
    assert_includes result[:description].downcase, 'weekday'
  end

  def test_parse_returns_expanded_fields
    result = @tool.execute(action: 'parse', expression: '*/15 * * * *')

    assert result[:success]
    assert result[:expanded]
    assert_equal [0, 15, 30, 45], result[:expanded][:minutes]
  end

  def test_parse_without_expression_returns_error
    result = @tool.execute(action: 'parse', expression: nil)

    refute result[:success]
    assert_includes result[:error], "required"
  end

  def test_parse_invalid_expression_returns_error
    result = @tool.execute(action: 'parse', expression: 'invalid')

    refute result[:valid] || result[:success]
  end

  # Validate action tests

  def test_validate_valid_expression
    result = @tool.execute(action: 'validate', expression: '0 9 * * *')

    assert result[:valid]
  end

  def test_validate_every_minute_expression
    result = @tool.execute(action: 'validate', expression: '* * * * *')

    assert result[:valid]
  end

  def test_validate_complex_expression
    result = @tool.execute(action: 'validate', expression: '0,30 9-17 * * 1-5')

    assert result[:valid]
  end

  def test_validate_step_expression
    result = @tool.execute(action: 'validate', expression: '*/5 */2 * * *')

    assert result[:valid]
  end

  def test_validate_invalid_field_count
    result = @tool.execute(action: 'validate', expression: '0 9 * *')

    refute result[:valid]
    assert_includes result[:error], 'expected 5 fields'
  end

  def test_validate_out_of_range_minute
    result = @tool.execute(action: 'validate', expression: '60 9 * * *')

    refute result[:valid]
  end

  def test_validate_out_of_range_hour
    result = @tool.execute(action: 'validate', expression: '0 25 * * *')

    refute result[:valid]
  end

  def test_validate_without_expression_returns_error
    result = @tool.execute(action: 'validate', expression: nil)

    refute result[:valid]
    assert_includes result[:error], "required"
  end

  # Next action tests

  def test_next_returns_execution_times
    result = @tool.execute(action: 'next', expression: '* * * * *', count: 3)

    assert result[:success]
    assert_equal 3, result[:count]
    assert_equal 3, result[:next_executions].length
  end

  def test_next_default_count_is_five
    result = @tool.execute(action: 'next', expression: '* * * * *')

    assert result[:success]
    assert_equal 5, result[:count]
  end

  def test_next_respects_max_count
    result = @tool.execute(action: 'next', expression: '* * * * *', count: 100)

    assert result[:success]
    assert result[:count] <= 20
  end

  def test_next_times_are_in_future
    result = @tool.execute(action: 'next', expression: '* * * * *', count: 1)

    assert result[:success]
    next_time = Time.parse(result[:next_executions].first)
    assert next_time > Time.now
  end

  def test_next_times_are_sequential
    result = @tool.execute(action: 'next', expression: '0 * * * *', count: 3)

    assert result[:success]
    times = result[:next_executions].map { |t| Time.parse(t) }
    assert times[0] < times[1]
    assert times[1] < times[2]
  end

  def test_next_without_expression_returns_error
    result = @tool.execute(action: 'next', expression: nil)

    refute result[:success]
    assert_includes result[:error], "required"
  end

  # Generate action tests

  def test_generate_every_minute
    result = @tool.execute(action: 'generate', description: 'every minute')

    assert result[:success]
    assert_equal '* * * * *', result[:expression]
  end

  def test_generate_every_five_minutes
    result = @tool.execute(action: 'generate', description: 'every 5 minutes')

    assert result[:success]
    assert_equal '*/5 * * * *', result[:expression]
  end

  def test_generate_every_hour
    result = @tool.execute(action: 'generate', description: 'every hour')

    assert result[:success]
    assert_equal '0 * * * *', result[:expression]
  end

  def test_generate_daily_at_time
    result = @tool.execute(action: 'generate', description: 'every day at 9am')

    assert result[:success]
    assert_equal '0 9 * * *', result[:expression]
  end

  def test_generate_daily_at_pm_time
    result = @tool.execute(action: 'generate', description: 'every day at 3pm')

    assert result[:success]
    assert_equal '0 15 * * *', result[:expression]
  end

  def test_generate_at_noon
    result = @tool.execute(action: 'generate', description: 'at noon')

    assert result[:success]
    assert_equal '0 12 * * *', result[:expression]
  end

  def test_generate_at_midnight
    result = @tool.execute(action: 'generate', description: 'at midnight')

    assert result[:success]
    assert_equal '0 0 * * *', result[:expression]
  end

  def test_generate_weekdays
    result = @tool.execute(action: 'generate', description: 'weekdays at 9am')

    assert result[:success]
    assert_equal '0 9 * * 1-5', result[:expression]
  end

  def test_generate_weekends
    result = @tool.execute(action: 'generate', description: 'weekends at 10am')

    assert result[:success]
    assert_equal '0 10 * * 0,6', result[:expression]
  end

  def test_generate_specific_day
    result = @tool.execute(action: 'generate', description: 'every monday at 9am')

    assert result[:success]
    assert_equal '0 9 * * 1', result[:expression]
  end

  def test_generate_monthly
    result = @tool.execute(action: 'generate', description: 'monthly')

    assert result[:success]
    assert_equal '0 0 1 * *', result[:expression]
  end

  def test_generate_yearly
    result = @tool.execute(action: 'generate', description: 'yearly')

    assert result[:success]
    assert_equal '0 0 1 1 *', result[:expression]
  end

  def test_generate_without_description_returns_error
    result = @tool.execute(action: 'generate', description: nil)

    refute result[:success]
    assert_includes result[:error], "required"
  end

  def test_generate_unparseable_description_returns_error
    result = @tool.execute(action: 'generate', description: 'gibberish text here')

    refute result[:success]
    assert_includes result[:error], "Could not parse"
  end

  # Unknown action test

  def test_unknown_action_returns_error
    result = @tool.execute(action: 'unknown')

    refute result[:success]
    assert_includes result[:error], "Unknown action"
    assert_includes result[:error], "Valid actions"
  end

  # Case insensitivity tests

  def test_action_is_case_insensitive
    result_lower = @tool.execute(action: 'validate', expression: '* * * * *')
    result_upper = @tool.execute(action: 'VALIDATE', expression: '* * * * *')
    result_mixed = @tool.execute(action: 'Validate', expression: '* * * * *')

    assert result_lower[:valid]
    assert result_upper[:valid]
    assert result_mixed[:valid]
  end
end
