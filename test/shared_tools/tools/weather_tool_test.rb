# frozen_string_literal: true

require "test_helper"

class WeatherToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::WeatherTool.new
    @has_api_key = ENV['OPENWEATHER_API_KEY'] && !ENV['OPENWEATHER_API_KEY'].empty?

    # Mock OpenWeatherMap API responses
    @mock_current_weather = {
      'main' => {
        'temp' => 15.5,
        'feels_like' => 14.2,
        'humidity' => 72,
        'pressure' => 1013
      },
      'weather' => [
        {'description' => 'partly cloudy'}
      ],
      'wind' => {
        'speed' => 3.5,
        'deg' => 180
      },
      'clouds' => {
        'all' => 40
      },
      'visibility' => 10000
    }

    @mock_forecast = {
      'list' => [
        # Day 1 - 3 entries
        {
          'dt' => Time.now.to_i,
          'main' => {'temp' => 16.0, 'humidity' => 70},
          'weather' => [{'description' => 'clear sky'}],
          'wind' => {'speed' => 3.0}
        },
        {
          'dt' => Time.now.to_i + 10800,
          'main' => {'temp' => 18.5, 'humidity' => 65},
          'weather' => [{'description' => 'clear sky'}],
          'wind' => {'speed' => 3.2}
        },
        {
          'dt' => Time.now.to_i + 21600,
          'main' => {'temp' => 14.0, 'humidity' => 75},
          'weather' => [{'description' => 'few clouds'}],
          'wind' => {'speed' => 2.8}
        },
        # Day 2 - 3 entries
        {
          'dt' => (Time.now + 86400).to_i,
          'main' => {'temp' => 17.5, 'humidity' => 68},
          'weather' => [{'description' => 'scattered clouds'}],
          'wind' => {'speed' => 4.0}
        },
        {
          'dt' => (Time.now + 86400).to_i + 10800,
          'main' => {'temp' => 20.0, 'humidity' => 60},
          'weather' => [{'description' => 'scattered clouds'}],
          'wind' => {'speed' => 4.5}
        },
        {
          'dt' => (Time.now + 86400).to_i + 21600,
          'main' => {'temp' => 15.5, 'humidity' => 72},
          'weather' => [{'description' => 'scattered clouds'}],
          'wind' => {'speed' => 3.8}
        },
        # Day 3 - 2 entries
        {
          'dt' => (Time.now + 172800).to_i,
          'main' => {'temp' => 16.5, 'humidity' => 70},
          'weather' => [{'description' => 'light rain'}],
          'wind' => {'speed' => 5.0}
        },
        {
          'dt' => (Time.now + 172800).to_i + 10800,
          'main' => {'temp' => 19.0, 'humidity' => 65},
          'weather' => [{'description' => 'light rain'}],
          'wind' => {'speed' => 5.5}
        }
      ]
    }
  end

  def test_tool_name
    assert_equal 'weather_tool', SharedTools::Tools::WeatherTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_successful_current_weather_lookup
    skip_without_api_key

    mock_api = Minitest::Mock.new
    mock_api.expect(:current, @mock_current_weather, ['London,UK'])

    OpenWeatherMap::API.stub(:new, mock_api) do
      result = @tool.execute(city: "London,UK", units: "metric")

      assert result[:success]
      assert_equal "London,UK", result[:city]
      assert_equal "metric", result[:units]
      assert result[:current]
      assert result[:current][:temperature]
      assert result[:current][:description]
      assert result[:timestamp]
    end

    mock_api.verify
  end

  def test_weather_lookup_with_imperial_units
    skip_without_api_key

    mock_api = Minitest::Mock.new
    mock_api.expect(:current, @mock_current_weather, ['New York,US'])

    OpenWeatherMap::API.stub(:new, mock_api) do
      result = @tool.execute(city: "New York,US", units: "imperial")

      assert result[:success]
      assert_equal "imperial", result[:units]
      assert result[:current][:temperature]
    end

    mock_api.verify
  end

  def test_weather_lookup_with_forecast
    skip_without_api_key

    mock_api = Minitest::Mock.new
    mock_api.expect(:current, @mock_current_weather, ['Paris,FR'])
    mock_api.expect(:forecast, @mock_forecast, ['Paris,FR'])

    OpenWeatherMap::API.stub(:new, mock_api) do
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

    mock_api.verify
  end

  def test_missing_api_key
    # Save original API key
    original_key = ENV['OPENWEATHER_API_KEY']

    begin
      ENV.delete('OPENWEATHER_API_KEY')

      # Create a new tool instance to pick up the missing key
      tool = SharedTools::Tools::WeatherTool.new
      result = tool.execute(city: "London,UK")

      refute result[:success]
      assert_includes result[:error], "API key not configured"
      assert_equal "London,UK", result[:city]
      assert result[:suggestion]
    ensure
      # Restore original API key
      ENV['OPENWEATHER_API_KEY'] = original_key if original_key
    end
  end

  def test_api_error_city_not_found
    skip_without_api_key

    mock_api = Minitest::Mock.new
    mock_api.expect(:current, -> { raise "city not found" }, ['InvalidCity999XYZ123'])

    OpenWeatherMap::API.stub(:new, mock_api) do
      result = @tool.execute(city: "InvalidCity999XYZ123")

      refute result[:success]
      assert result[:error]
      assert result[:suggestion]
    end
  end

  def test_default_units_is_metric
    skip_without_api_key

    mock_api = Minitest::Mock.new
    mock_api.expect(:current, @mock_current_weather, ['Tokyo,JP'])

    OpenWeatherMap::API.stub(:new, mock_api) do
      result = @tool.execute(city: "Tokyo,JP")

      assert result[:success]
      assert_equal "metric", result[:units]
    end

    mock_api.verify
  end

  def test_default_include_forecast_is_false
    skip_without_api_key

    mock_api = Minitest::Mock.new
    mock_api.expect(:current, @mock_current_weather, ['Berlin,DE'])

    OpenWeatherMap::API.stub(:new, mock_api) do
      result = @tool.execute(city: "Berlin,DE")

      assert result[:success]
      refute result.key?(:forecast)
    end

    mock_api.verify
  end

  def test_current_weather_includes_all_fields
    skip_without_api_key

    mock_api = Minitest::Mock.new
    mock_api.expect(:current, @mock_current_weather, ['Sydney,AU'])

    OpenWeatherMap::API.stub(:new, mock_api) do
      result = @tool.execute(city: "Sydney,AU")

      assert result[:success]
      current = result[:current]

      assert current[:temperature]
      assert current[:feels_like]
      assert current[:description]
      assert current[:humidity]
      assert current[:pressure]
      assert current[:wind_speed]
      assert current[:wind_direction]
      assert current[:cloudiness]
      assert current[:visibility]
    end

    mock_api.verify
  end

  def test_forecast_calculates_daily_averages
    skip_without_api_key

    mock_api = Minitest::Mock.new
    mock_api.expect(:current, @mock_current_weather, ['Rome,IT'])
    mock_api.expect(:forecast, @mock_forecast, ['Rome,IT'])

    OpenWeatherMap::API.stub(:new, mock_api) do
      result = @tool.execute(city: "Rome,IT", include_forecast: true)

      assert result[:success]

      result[:forecast].each do |day|
        assert day[:temp_min] <= day[:temp_avg]
        assert day[:temp_avg] <= day[:temp_max]
        assert day[:avg_humidity] >= 0
        assert day[:avg_humidity] <= 100
      end
    end

    mock_api.verify
  end

  private

  def skip_without_api_key
    skip "Set OPENWEATHER_API_KEY environment variable to run weather tool tests" unless @has_api_key
  end
end
