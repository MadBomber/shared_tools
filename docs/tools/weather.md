# WeatherTool

Real-time weather data retrieval from the OpenWeatherMap API.

## Overview

The WeatherTool provides access to current weather conditions and forecasts for any city worldwide through the OpenWeatherMap API. It supports multiple unit systems and can optionally include extended forecast data.

## Features

- **Current Weather**: Real-time temperature, conditions, and atmospheric data
- **3-Day Forecast**: Optional extended forecast with daily summaries
- **Multiple Units**: Metric (Celsius), Imperial (Fahrenheit), or Kelvin
- **Comprehensive Data**: Temperature, feels-like, humidity, pressure, wind, cloudiness, visibility
- **Global Coverage**: Weather data for cities worldwide
- **Forecast Analysis**: Aggregated daily min/max/average values

## Installation

The WeatherTool requires the `openweathermap` gem, which is included in SharedTools dependencies:

```ruby
gem 'shared_tools'
```

### API Key Setup

You need a free API key from [OpenWeatherMap](https://openweathermap.org/api):

1. Sign up at https://openweathermap.org/
2. Get your API key from the API keys section
3. Set the environment variable:

```bash
export OPENWEATHER_API_KEY="your_api_key_here"
```

Or in Ruby:

```ruby
ENV['OPENWEATHER_API_KEY'] = 'your_api_key_here'
```

## Basic Usage

### Current Weather

```ruby
require 'shared_tools'

weather = SharedTools::Tools::WeatherTool.new

# Get current weather for a city
result = weather.execute(city: "London")
puts "Temperature: #{result[:current][:temperature]}°C"
puts "Conditions: #{result[:current][:description]}"
```

### With Country Code

For cities with common names, include the country code:

```ruby
# London, UK
result = weather.execute(city: "London,UK", units: "metric")

# Paris, France
result = weather.execute(city: "Paris,FR", units: "metric")

# Portland, Oregon, USA
result = weather.execute(city: "Portland,US", units: "imperial")
```

## Unit Systems

### Metric (Default)

```ruby
result = weather.execute(city: "Tokyo,JP", units: "metric")
# Temperature in Celsius
# Wind speed in m/s
# Pressure in hPa
```

### Imperial

```ruby
result = weather.execute(city: "New York,US", units: "imperial")
# Temperature in Fahrenheit
# Wind speed in mph
# Pressure in hPa
```

### Kelvin

```ruby
result = weather.execute(city: "Moscow,RU", units: "kelvin")
# Temperature in Kelvin (scientific standard)
# Wind speed in m/s
# Pressure in hPa
```

## Forecast Data

### Including Forecasts

```ruby
result = weather.execute(
  city: "London,UK",
  units: "metric",
  include_forecast: true
)

# Access forecast data
result[:forecast].each do |day|
  puts "#{day[:date]}: #{day[:temp_min]}°C - #{day[:temp_max]}°C"
  puts "Conditions: #{day[:conditions]}"
end
```

### Forecast Data Structure

Each forecast day includes:
- `date`: Date string (YYYY-MM-DD)
- `temp_min`: Minimum temperature for the day
- `temp_max`: Maximum temperature for the day
- `temp_avg`: Average temperature
- `conditions`: Most common weather condition
- `avg_humidity`: Average humidity percentage
- `avg_wind_speed`: Average wind speed

## Response Format

### Successful Response (Current Weather Only)

```ruby
{
  success: true,
  city: "London,UK",
  current: {
    temperature: 15.5,
    feels_like: 14.2,
    description: "partly cloudy",
    humidity: 72,
    pressure: 1013,
    wind_speed: 5.2,
    wind_direction: 180,
    cloudiness: 40,
    visibility: 10000
  },
  units: "metric",
  timestamp: "2025-01-15T10:30:00Z"
}
```

### With Forecast

```ruby
{
  success: true,
  city: "London,UK",
  current: { ... },
  forecast: [
    {
      date: "2025-01-15",
      temp_min: 12.5,
      temp_max: 16.8,
      temp_avg: 14.6,
      conditions: "partly cloudy",
      avg_humidity: 70,
      avg_wind_speed: 4.8
    },
    # ... 2 more days
  ],
  units: "metric",
  timestamp: "2025-01-15T10:30:00Z"
}
```

### Error Response

```ruby
{
  success: false,
  error: "City not found or API error message",
  city: "InvalidCity",
  suggestion: "Verify city name and API key configuration"
}
```

## Current Weather Fields

### Temperature Data

| Field | Description | Units |
|-------|-------------|-------|
| `temperature` | Current temperature | °C / °F / K |
| `feels_like` | Perceived temperature | °C / °F / K |

### Atmospheric Data

| Field | Description | Units |
|-------|-------------|-------|
| `humidity` | Relative humidity | % |
| `pressure` | Atmospheric pressure | hPa |
| `visibility` | Visibility distance | meters |
| `cloudiness` | Cloud coverage | % |

### Wind Data

| Field | Description | Units |
|-------|-------------|-------|
| `wind_speed` | Wind speed | m/s or mph |
| `wind_direction` | Wind direction | degrees |

### Weather Description

| Field | Description |
|-------|-------------|
| `description` | Human-readable weather description (e.g., "partly cloudy", "light rain") |

## Advanced Examples

### Multiple Cities

```ruby
cities = ["London,UK", "Paris,FR", "Berlin,DE", "Rome,IT"]

cities.each do |city|
  result = weather.execute(city: city, units: "metric")

  if result[:success]
    temp = result[:current][:temperature]
    desc = result[:current][:description]
    puts "#{city}: #{temp}°C - #{desc}"
  else
    puts "#{city}: Error - #{result[:error]}"
  end
end
```

### Weather Comparison

```ruby
def compare_weather(city1, city2)
  weather = SharedTools::Tools::WeatherTool.new

  result1 = weather.execute(city: city1, units: "metric")
  result2 = weather.execute(city: city2, units: "metric")

  if result1[:success] && result2[:success]
    temp1 = result1[:current][:temperature]
    temp2 = result2[:current][:temperature]

    diff = (temp1 - temp2).round(1)
    warmer = diff > 0 ? city1 : city2

    puts "#{warmer} is #{diff.abs}°C warmer"
  end
end

compare_weather("Miami,US", "Seattle,US")
```

### Detailed Forecast Analysis

```ruby
result = weather.execute(
  city: "San Francisco,US",
  units: "imperial",
  include_forecast: true
)

if result[:success] && result[:forecast]
  puts "3-Day Forecast for #{result[:city]}:"
  puts "-" * 50

  result[:forecast].each do |day|
    puts "\n#{day[:date]}:"
    puts "  Temperature: #{day[:temp_min]}°F - #{day[:temp_max]}°F"
    puts "  Conditions: #{day[:conditions]}"
    puts "  Humidity: #{day[:avg_humidity]}%"
    puts "  Wind: #{day[:avg_wind_speed]} mph"
  end
end
```

## Integration with LLM Agents

```ruby
require 'ruby_llm'

agent = RubyLLM::Agent.new(
  tools: [
    SharedTools::Tools::WeatherTool.new
  ]
)

# Let the LLM fetch weather data
response = agent.process("What's the weather like in Tokyo right now?")
response = agent.process("Give me a 3-day forecast for London")
response = agent.process("Is it warmer in Miami or Seattle today?")
```

## Configuration

### Custom Logger

```ruby
require 'logger'

custom_logger = Logger.new($stdout)
custom_logger.level = Logger::DEBUG

weather = SharedTools::Tools::WeatherTool.new(logger: custom_logger)
```

## Error Handling

### API Key Not Configured

```ruby
result = weather.execute(city: "London")
# Without OPENWEATHER_API_KEY set:
# {
#   success: false,
#   error: "OpenWeather API key not configured",
#   ...
# }
```

### City Not Found

```ruby
result = weather.execute(city: "InvalidCityName12345")
# {
#   success: false,
#   error: "City not found",
#   city: "InvalidCityName12345",
#   suggestion: "Verify city name and API key configuration"
# }
```

### API Request Failure

```ruby
# Network error, rate limit, or API issue
result = weather.execute(city: "London")
# {
#   success: false,
#   error: "API request failed: [error details]",
#   ...
# }
```

## Rate Limits

OpenWeatherMap free tier has rate limits:

- **Free Plan**: 60 calls/minute, 1,000,000 calls/month
- **Startup Plan**: Higher limits available

Monitor your usage at https://openweathermap.org/price

## Performance Considerations

- **API Latency**: Network request time varies (typically 100-500ms)
- **Forecast Data**: Including forecasts requires an additional API call
- **Caching**: Consider caching results for frequently requested cities
- **Batch Requests**: Space out multiple requests to respect rate limits

## Best Practices

### Use Country Codes

```ruby
# Good - specific
weather.execute(city: "Portland,US")  # Oregon, USA
weather.execute(city: "Portland,AU")  # Victoria, Australia

# Less reliable
weather.execute(city: "Portland")  # Which Portland?
```

### Handle Errors Gracefully

```ruby
result = weather.execute(city: user_input)

if result[:success]
  # Use weather data
  process_weather(result)
else
  # Show user-friendly error
  puts "Unable to fetch weather: #{result[:error]}"
  puts "Suggestion: #{result[:suggestion]}"
end
```

### Cache Results

```ruby
class WeatherCache
  def initialize
    @weather = SharedTools::Tools::WeatherTool.new
    @cache = {}
    @cache_duration = 10 * 60  # 10 minutes
  end

  def get_weather(city, units: "metric")
    cache_key = "#{city}:#{units}"
    cached = @cache[cache_key]

    if cached && (Time.now - cached[:time]) < @cache_duration
      return cached[:data]
    end

    result = @weather.execute(city: city, units: units)
    @cache[cache_key] = {data: result, time: Time.now}
    result
  end
end
```

## Security Considerations

- ✅ API key stored in environment variable (not in code)
- ✅ No arbitrary code execution
- ✅ Input validation on city parameter
- ✅ Safe HTTP requests via openweathermap gem
- ⚠️ Protect API key (don't commit to version control)
- ⚠️ Monitor API usage to prevent unexpected charges

## Limitations

- **Free Tier**: Limited to 60 calls/minute
- **Forecast Period**: Only 3-day forecast provided
- **Historical Data**: Not available (current and future only)
- **City Resolution**: Some obscure locations may not be found
- **Update Frequency**: Weather data updates vary by location

## Troubleshooting

### API Key Issues

**Problem**: "API key not configured" error

**Solution**:
```bash
# Set environment variable
export OPENWEATHER_API_KEY="your_key_here"

# Or in Ruby before using the tool
ENV['OPENWEATHER_API_KEY'] = 'your_key_here'
```

### City Not Found

**Problem**: Valid city returns "not found" error

**Solution**: Try adding country code or checking spelling
```ruby
# Instead of
weather.execute(city: "Muenchen")

# Try
weather.execute(city: "Munich,DE")
```

### Rate Limit Errors

**Problem**: "Rate limit exceeded" error

**Solution**: Space out requests or upgrade API plan
```ruby
cities.each do |city|
  result = weather.execute(city: city)
  sleep(1)  # Wait between requests
end
```

## Related Tools

- [CompositeAnalysisTool](index.md) - Can incorporate weather data in analysis
- [WorkflowManagerTool](index.md) - For multi-step workflows involving weather data

## References

- [OpenWeatherMap API Documentation](https://openweathermap.org/api)
- [OpenWeatherMap Ruby Gem](https://github.com/lucaswinningham/openweathermap)
- [API Pricing](https://openweathermap.org/price)
