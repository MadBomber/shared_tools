# frozen_string_literal: true

require "test_helper"

class CronToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::CronTool.new
  end

  def test_tool_name
    assert_equal 'cron_tool', SharedTools::Tools::CronTool.name
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
