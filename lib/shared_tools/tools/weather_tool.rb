# weather_tool.rb - API integration example
require 'ruby_llm/tool'
require 'openweathermap'

module SharedTools
  module Tools
    class WeatherTool < RubyLLM::Tool
      def self.name = 'weather_tool'

      description <<~'DESCRIPTION'
        Retrieve comprehensive current weather information for any city worldwide using the OpenWeatherMap API.
        This tool provides real-time weather data including temperature, atmospheric conditions, humidity,
        and wind information. It supports multiple temperature units and can optionally include extended
        forecast data. The tool requires a valid OpenWeatherMap API key to be configured in the
        OPENWEATHER_API_KEY environment variable. All weather data is fetched in real-time and includes
        timestamps for accuracy verification.

        Example usage:
          tool = SharedTools::Tools::WeatherTool.new
          result = tool.execute(city: "London,UK", units: "metric")
          puts "Temperature: #{result[:current][:temperature]}°C"
      DESCRIPTION

      params do
        string :city, description: <<~DESC.strip
          Name of the city for weather lookup. Can include city name only (e.g., 'London')
          or city with country code for better accuracy (e.g., 'London,UK' or 'Paris,FR').
          For cities with common names in multiple countries, including the country code
          is recommended to ensure accurate results. The API will attempt to find the
          closest match if an exact match is not found.
        DESC

        string :units, description: <<~DESC.strip, required: false
          Temperature unit system for the weather data. Options are:
          - 'metric': Temperature in Celsius, wind speed in m/s, pressure in hPa
          - 'imperial': Temperature in Fahrenheit, wind speed in mph, pressure in hPa
          - 'kelvin': Temperature in Kelvin (scientific standard), wind speed in m/s
          Default is 'metric' which is most commonly used internationally.
        DESC

        boolean :include_forecast, description: <<~DESC.strip, required: false
          Boolean flag to include a 3-day weather forecast in addition to current conditions.
          When set to true, the response will include forecast data with daily high/low temperatures,
          precipitation probability, and general weather conditions for the next three days.
          This requires additional API calls and may increase response time slightly.
        DESC
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # Execute weather lookup for specified city
      #
      # @param city [String] City name, optionally with country code
      # @param units [String] Unit system: metric, imperial, or kelvin
      # @param include_forecast [Boolean] Whether to include 3-day forecast
      #
      # @return [Hash] Weather data with success status
      def execute(city:, units: "metric", include_forecast: false)
        @logger.info("WeatherTool#execute city=#{city.inspect} units=#{units} include_forecast=#{include_forecast}")

        begin
          api_key = ENV['OPENWEATHER_API_KEY']
          unless api_key
            @logger.error("OpenWeather API key not configured in OPENWEATHER_API_KEY environment variable")
            raise "OpenWeather API key not configured"
          end

          # Create API client with units mapping
          api_units = map_units_to_api(units)
          api = OpenWeatherMap::API.new(api_key, 'en', api_units)

          current_weather = fetch_current_weather(api, city)
          result = {
            success:   true,
            city:      city,
            current:   current_weather,
            units:     units,
            timestamp: Time.now.iso8601
          }

          if include_forecast
            @logger.debug("Fetching forecast data for #{city}")
            forecast_data = fetch_forecast(api, city)
            result[:forecast] = forecast_data
          end

          @logger.info("Weather data retrieved successfully for #{city}")
          result
        rescue => e
          @logger.error("Weather lookup failed for #{city}: #{e.message}")
          {
            success:    false,
            error:      e.message,
            city:       city,
            suggestion: "Verify city name and API key configuration"
          }
        end
      end

      private

      # Map our unit names to OpenWeatherMap API unit names
      #
      # @param units [String] Our unit system name
      # @return [String] API unit system name
      def map_units_to_api(units)
        case units.to_s.downcase
        when 'imperial'
          'imperial'
        when 'kelvin'
          'standard'
        else
          'metric'
        end
      end

      # Fetch current weather conditions for a city
      #
      # @param api [OpenWeatherMap::API] API client
      # @param city [String] City name with optional country code
      #
      # @return [Hash] Current weather data
      def fetch_current_weather(api, city)
        @logger.debug("Fetching current weather for #{city}")

        data = api.current(city)
        @logger.debug("Current weather data received for #{city}")

        {
          temperature:    data['main']['temp'],
          feels_like:     data['main']['feels_like'],
          description:    data['weather'][0]['description'],
          humidity:       data['main']['humidity'],
          pressure:       data['main']['pressure'],
          wind_speed:     data['wind']['speed'],
          wind_direction: data['wind']['deg'],
          cloudiness:     data['clouds']['all'],
          visibility:     data['visibility']
        }
      end

      # Fetch 3-day weather forecast for a city
      #
      # @param api [OpenWeatherMap::API] API client
      # @param city [String] City name with optional country code
      #
      # @return [Array<Hash>] Array of forecast data for next 3 days
      def fetch_forecast(api, city)
        @logger.debug("Fetching 3-day forecast for #{city}")

        data = api.forecast(city)
        @logger.debug("Forecast data received for #{city}")

        # Group forecasts by date and extract daily summaries
        forecasts_by_date = {}

        data['list'].each do |forecast|
          date = Time.at(forecast['dt']).strftime('%Y-%m-%d')

          forecasts_by_date[date] ||= {
            date:         date,
            temperatures: [],
            conditions:   [],
            humidity:     [],
            wind_speeds:  []
          }

          forecasts_by_date[date][:temperatures] << forecast['main']['temp']
          forecasts_by_date[date][:conditions] << forecast['weather'][0]['description']
          forecasts_by_date[date][:humidity] << forecast['main']['humidity']
          forecasts_by_date[date][:wind_speeds] << forecast['wind']['speed']
        end

        # Calculate daily summaries
        forecasts_by_date.values.map do |day|
          temps = day[:temperatures]
          {
            date:              day[:date],
            temp_min:          temps.min.round(1),
            temp_max:          temps.max.round(1),
            temp_avg:          (temps.sum / temps.size).round(1),
            conditions:        day[:conditions].max_by { |c| day[:conditions].count(c) },
            avg_humidity:      (day[:humidity].sum / day[:humidity].size).round(0),
            avg_wind_speed:    (day[:wind_speeds].sum / day[:wind_speeds].size).round(1)
          }
        end.take(3)  # Return only 3 days
      end
    end
  end
end
