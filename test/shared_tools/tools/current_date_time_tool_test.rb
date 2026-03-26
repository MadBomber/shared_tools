# frozen_string_literal: true

require "test_helper"

class CurrentDateTimeToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::CurrentDateTimeTool.new
  end

  def test_tool_name
    assert_equal 'current_date_time_tool', SharedTools::Tools::CurrentDateTimeTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_full_format_includes_all_sections
    result = @tool.execute(format: 'full')

    assert result[:success]
    # date fields
    assert result[:year]
    assert result[:month]
    assert result[:day]
    assert result[:day_of_week]
    # time fields
    assert result.key?(:hour)
    assert result.key?(:minute)
    assert result.key?(:second)
    # iso fields
    assert result[:iso8601]
    assert result[:unix_timestamp]
  end

  def test_date_format_returns_date_fields
    result = @tool.execute(format: 'date')

    assert result[:success]
    assert result[:year]
    assert result[:month]
    assert result[:day]
    assert result[:day_of_week]
    assert result[:quarter]
    assert result[:ordinal_day]
    refute result.key?(:hour)
  end

  def test_time_format_returns_time_fields
    result = @tool.execute(format: 'time')

    assert result[:success]
    assert result.key?(:hour)
    assert result.key?(:minute)
    assert result.key?(:second)
    assert result[:timezone]
    refute result.key?(:year)
  end

  def test_iso8601_format_returns_iso_fields
    result = @tool.execute(format: 'iso8601')

    assert result[:success]
    assert result[:iso8601]
    assert result[:iso8601_utc]
    assert result[:unix_timestamp]
    refute result.key?(:year)
  end

  def test_default_format_is_full
    result = @tool.execute

    assert result[:success]
    assert result[:year]
    assert result.key?(:hour)
    assert result[:iso8601]
  end

  def test_unknown_format_falls_back_to_full
    result = @tool.execute(format: 'bogus')

    assert result[:success]
    assert result[:year]
    assert result[:iso8601]
  end

  def test_year_is_current_year
    result = @tool.execute(format: 'date')
    assert_equal Time.now.year, result[:year]
  end

  def test_day_of_week_is_a_string
    result = @tool.execute(format: 'date')
    assert_kind_of String, result[:day_of_week]
    assert_includes %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday], result[:day_of_week]
  end

  def test_iso8601_format_is_valid
    result = @tool.execute(format: 'iso8601')
    assert_match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, result[:iso8601])
  end

  def test_unix_timestamp_is_positive_integer
    result = @tool.execute(format: 'iso8601')
    assert_kind_of Integer, result[:unix_timestamp]
    assert result[:unix_timestamp] > 0
  end

  def test_quarter_is_between_1_and_4
    result = @tool.execute(format: 'date')
    assert_includes 1..4, result[:quarter]
  end
end
