# frozen_string_literal: true

require "test_helper"

class WeatherToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::WeatherTool.new
    @has_api_key = ENV['OPENWEATHER_API_KEY'] && !ENV['OPENWEATHER_API_KEY'].empty?
  end

  def test_tool_name
    assert_equal 'weather_tool', SharedTools::Tools::WeatherTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_successful_current_weather_lookup
    skip_without_api_key

    result = @tool.execute(city: "London,UK", units: "metric")

    assert result[:success]
    assert_equal "London,UK", result[:city]
    assert_equal "metric", result[:units]
    assert result[:current]
    assert result[:current][:temperature]
    assert result[:current][:description]
    assert result[:timestamp]
  end

  def test_weather_lookup_with_imperial_units
    skip_without_api_key

    result = @tool.execute(city: "New York,US", units: "imperial")

    assert result[:success]
    assert_equal "imperial", result[:units]
    assert result[:current][:temperature]
  end

  def test_weather_lookup_with_forecast
    skip_without_api_key

    result = @tool.execute(city: "Paris,FR", units: "metric", include_forecast: true)

    assert result[:success]
    assert result[:current]
    assert result[:forecast]
    assert result[:forecast].length >= 1

    first_day = result[:forecast].first
    assert first_day[:date]
    assert first_day[:temp_min]
    assert first_day[:temp_max]
    assert first_day[:temp_avg]
    assert first_day[:conditions]
  end

  def test_missing_api_key
    original_key = ENV['OPENWEATHER_API_KEY']

    begin
      ENV.delete('OPENWEATHER_API_KEY')

      tool = SharedTools::Tools::WeatherTool.new
      result = tool.execute(city: "London,UK")

      refute result[:success]
      assert_includes result[:error], "API key not configured"
      assert_equal "London,UK", result[:city]
      assert result[:suggestion]
    ensure
      ENV['OPENWEATHER_API_KEY'] = original_key if original_key
    end
  end

  def test_api_error_city_not_found
    skip_without_api_key

    result = @tool.execute(city: "InvalidCity999XYZ123")

    refute result[:success]
    assert result[:error]
    assert result[:suggestion]
  end

  def test_default_units_is_metric
    skip_without_api_key

    result = @tool.execute(city: "Tokyo,JP")

    assert result[:success]
    assert_equal "metric", result[:units]
  end

  def test_default_include_forecast_is_false
    skip_without_api_key

    result = @tool.execute(city: "Berlin,DE")

    assert result[:success]
    refute result.key?(:forecast)
  end

  def test_current_weather_includes_all_fields
    skip_without_api_key

    result = @tool.execute(city: "Sydney,AU")

    assert result[:success]
    current = result[:current]

    assert current[:temperature]
    assert current[:feels_like]
    assert current[:description]
    assert current[:humidity]
    assert current[:pressure]
    assert current.key?(:wind_speed)
    assert current.key?(:wind_direction)
    assert current.key?(:cloudiness)
    assert current.key?(:visibility)
  end

  def test_forecast_calculates_daily_averages
    skip_without_api_key

    result = @tool.execute(city: "Rome,IT", include_forecast: true)

    assert result[:success]

    result[:forecast].each do |day|
      assert day[:temp_min] <= day[:temp_avg]
      assert day[:temp_avg] <= day[:temp_max]
      assert day[:avg_humidity] >= 0
      assert day[:avg_humidity] <= 100
    end
  end

  private

  def skip_without_api_key
    skip "Set OPENWEATHER_API_KEY environment variable to run weather tool tests" unless @has_api_key
  end
end
