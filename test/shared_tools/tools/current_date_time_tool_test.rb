# frozen_string_literal: true

require "test_helper"

class CurrentDateTimeToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::CurrentDateTimeTool.new
  end

  def test_tool_name
    assert_equal 'current_date_time', SharedTools::Tools::CurrentDateTimeTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_can_instantiate_without_arguments
    tool = SharedTools::Tools::CurrentDateTimeTool.new
    assert_instance_of SharedTools::Tools::CurrentDateTimeTool, tool
  end

  def test_full_format_returns_all_fields
    result = @tool.execute(format: 'full')

    assert result[:success]
    assert_match(/\d{4}-\d{2}-\d{2}/, result[:date])
    assert_match(/\d{2}:\d{2}:\d{2}/, result[:time])
    assert result[:datetime]
    assert result[:timezone]
    assert result[:timezone_name]
    assert_match(/[+-]\d{2}:\d{2}/, result[:utc_offset])
    assert_kind_of Integer, result[:unix_timestamp]
    assert_includes %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday], result[:day_of_week]
    assert_kind_of Integer, result[:day_of_year]
    assert_kind_of Integer, result[:week_number]
    assert_includes [true, false], result[:is_dst]
    assert_includes [1, 2, 3, 4], result[:quarter]
  end

  def test_default_format_is_full
    result = @tool.execute

    assert result[:success]
    assert result[:date]
    assert result[:time]
    assert result[:timezone]
  end

  def test_date_only_format
    result = @tool.execute(format: 'date_only')

    assert result[:success]
    assert result[:date]
    assert result[:year]
    assert result[:month]
    assert result[:month_name]
    assert result[:day]
    assert result[:day_of_week]
    assert result[:day_of_year]
    assert result[:week_number]
    assert result[:quarter]

    # Should not include time fields
    refute result[:time]
    refute result[:unix_timestamp]
  end

  def test_time_only_format
    result = @tool.execute(format: 'time_only')

    assert result[:success]
    assert result[:time]
    assert result[:time_12h]
    assert_kind_of Integer, result[:hour]
    assert_kind_of Integer, result[:minute]
    assert_kind_of Integer, result[:second]
    assert result[:timezone]
    assert result[:unix_timestamp]

    # Should not include date fields
    refute result[:date]
    refute result[:day_of_week]
  end

  def test_iso8601_format
    result = @tool.execute(format: 'iso8601')

    assert result[:success]
    assert result[:datetime]
    assert result[:utc]

    # Verify ISO 8601 format
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, result[:datetime])
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/, result[:utc])
  end

  def test_format_is_case_insensitive
    result_lower = @tool.execute(format: 'date_only')
    result_upper = @tool.execute(format: 'DATE_ONLY')
    result_mixed = @tool.execute(format: 'Date_Only')

    assert result_lower[:success]
    assert result_upper[:success]
    assert result_mixed[:success]

    # All should have same keys
    assert_equal result_lower.keys.sort, result_upper.keys.sort
    assert_equal result_lower.keys.sort, result_mixed.keys.sort
  end

  def test_unknown_format_defaults_to_full
    result = @tool.execute(format: 'unknown_format')

    assert result[:success]
    assert result[:date]
    assert result[:time]
    assert result[:timezone]
    assert result[:unix_timestamp]
  end

  def test_date_matches_current_date
    now = Time.now
    result = @tool.execute

    assert_equal now.strftime('%Y-%m-%d'), result[:date]
    assert_equal now.year, result[:date].split('-')[0].to_i
  end

  def test_unix_timestamp_is_reasonable
    result = @tool.execute
    now = Time.now.to_i

    # Should be within 1 second of current time
    assert_in_delta now, result[:unix_timestamp], 1
  end

  def test_quarter_calculation
    # Test that quarter is calculated correctly based on month
    result = @tool.execute(format: 'date_only')
    month = Time.now.month
    expected_quarter = ((month - 1) / 3) + 1

    assert_equal expected_quarter, result[:quarter]
  end

  def test_week_number_is_valid
    result = @tool.execute(format: 'date_only')

    assert result[:week_number] >= 1
    assert result[:week_number] <= 53
  end

  def test_day_of_year_is_valid
    result = @tool.execute(format: 'date_only')

    assert result[:day_of_year] >= 1
    assert result[:day_of_year] <= 366
  end

  def test_hour_minute_second_ranges
    result = @tool.execute(format: 'time_only')

    assert result[:hour] >= 0 && result[:hour] <= 23
    assert result[:minute] >= 0 && result[:minute] <= 59
    assert result[:second] >= 0 && result[:second] <= 59
  end

  def test_utc_offset_format
    result = @tool.execute

    # Should match +HH:MM or -HH:MM format
    assert_match(/^[+-]\d{2}:\d{2}$/, result[:utc_offset])
  end

  def test_12_hour_time_format
    result = @tool.execute(format: 'time_only')

    # Should match HH:MM:SS AM/PM format
    assert_match(/^\d{2}:\d{2}:\d{2} [AP]M$/, result[:time_12h])
  end
end
