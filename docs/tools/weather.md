# WeatherTool

Real-time weather data retrieval from the OpenWeatherMap API, including current conditions, forecasts, and location-aware lookups.

## Overview

WeatherTool provides access to current weather conditions and forecasts for any city worldwide through the OpenWeatherMap API. It supports multiple unit systems and optional extended forecast data. Pair it with **DnsTool** and **CurrentDateTimeTool** for fully automatic local forecasts that detect your location from your IP address.

## Features

- **Current Weather**: Real-time temperature, conditions, and atmospheric data
- **3-Day Forecast**: Optional extended forecast with daily summaries
- **Multiple Units**: Metric (Celsius), Imperial (Fahrenheit), or Kelvin
- **Comprehensive Data**: Temperature, feels-like, humidity, pressure, wind, cloudiness, visibility
- **Global Coverage**: Weather data for cities worldwide
- **Local Forecast**: Combine with DnsTool to auto-detect your location

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

## Basic Usage

### Current Weather

```ruby
require 'shared_tools'

weather = SharedTools::Tools::WeatherTool.new

result = weather.execute(city: "London,UK", units: "metric")
puts "Temperature: #{result[:current][:temperature]}°C"
puts "Conditions: #{result[:current][:description]}"
```

### With Forecast

```ruby
result = weather.execute(
  city: "Tokyo,JP",
  units: "metric",
  include_forecast: true
)

result[:forecast].each do |day|
  puts "#{day[:date]}: #{day[:temp_min]}°C - #{day[:temp_max]}°C"
end
```

## Unit Systems

| Unit | Temperature | Wind Speed |
|------|-------------|------------|
| `"metric"` | Celsius | m/s |
| `"imperial"` | Fahrenheit | mph |
| `"kelvin"` | Kelvin | m/s |

## Response Format

### Current Weather

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
  timestamp: "2026-03-25T10:30:00Z"
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
      date: "2026-03-25",
      temp_min: 12.5,
      temp_max: 16.8,
      temp_avg: 14.6,
      conditions: "partly cloudy",
      avg_humidity: 70,
      avg_wind_speed: 4.8
    }
    # ... 2 more days
  ],
  units: "metric",
  timestamp: "2026-03-25T10:30:00Z"
}
```

## Local Forecast (Auto-Detect Location)

Combine **WeatherTool**, **DnsTool**, and **CurrentDateTimeTool** to automatically detect your location from your IP address and fetch an accurate local forecast — including the correct day of week from the clock, not the LLM's training data.

```ruby
require 'ruby_llm'
require 'shared_tools/tools/dns_tool'
require 'shared_tools/tools/weather_tool'
require 'shared_tools/tools/current_date_time_tool'

chat = RubyLLM.chat.with_tools(
  SharedTools::Tools::DnsTool.new,
  SharedTools::Tools::WeatherTool.new,
  SharedTools::Tools::CurrentDateTimeTool.new
)

chat.ask(<<~PROMPT)
  I want to know the weather where I currently am.

  Use these tools in order:
  1. current_date_time_tool (format: 'date') — get today's actual date and day of week
  2. dns_tool (action: 'external_ip') — get my public IP address
  3. dns_tool (action: 'ip_location') — geolocate that IP to find my city and country
  4. weather_tool — fetch current weather and a 3-day forecast for that city (imperial units)

  Use the real date and day of week from the tool when labelling today and
  the following days. Tell me: where am I, what are the current conditions,
  and what should I expect over the next three days?
PROMPT
```

## Integration with LLM Agents

```ruby
require 'ruby_llm'

agent = RubyLLM::Agent.new(
  tools: [SharedTools::Tools::WeatherTool.new]
)

agent.process("What's the weather like in Tokyo right now?")
agent.process("Give me a 3-day forecast for London in metric units.")
agent.process("I'm planning a trip. Fetch weather for Paris, Barcelona, and Amsterdam and recommend the best destination for outdoor sightseeing.")
```

## Error Handling

```ruby
result = weather.execute(city: "InvalidCity12345", units: "metric")

unless result[:success]
  puts "Error: #{result[:error]}"
  puts "Suggestion: #{result[:suggestion]}"
end
```

Common errors:

| Error | Cause | Fix |
|-------|-------|-----|
| `"API key not configured"` | `OPENWEATHER_API_KEY` not set | Export the env var |
| `"City not found"` | Typo or ambiguous city name | Add country code: `"Portland,US"` |
| `"API request failed"` | Network or rate limit | Check connectivity; wait and retry |

## Rate Limits

- **Free Plan**: 60 calls/minute, 1,000,000 calls/month
- Monitor usage at https://openweathermap.org/price

## Best Practices

- Always include a country code: `"London,UK"` not just `"London"`
- Including forecast data requires a second API call — omit `include_forecast` when not needed
- For the most accurate day-of-week labelling, pair with **CurrentDateTimeTool** rather than relying on the LLM's training data

## References

- [OpenWeatherMap API Documentation](https://openweathermap.org/api)
- [API Pricing](https://openweathermap.org/price)

## Related Tools

- [DnsTool](dns_tool.md) - IP geolocation for automatic location detection
- [CurrentDateTimeTool](index.md) - Real date and day of week for accurate forecast labels
