#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using WeatherTool with LLM Integration
#
# This example demonstrates how an LLM can fetch weather information
# through natural language prompts using the OpenWeatherMap API.
#
# Note: This example requires:
#   - The 'openweathermap' gem: gem install openweathermap
#   - An OpenWeatherMap API key set in OPENWEATHER_API_KEY environment variable
#   - Get a free API key at: https://openweathermap.org/api

require_relative 'ruby_llm_config'

begin
  require 'openweathermap'
  require 'shared_tools/tools/weather_tool'
rescue LoadError => e
  title "ERROR: Missing required dependencies for WeatherTool"

  puts <<~ERROR_MSG

    This example requires the 'openweathermap' gem:
      gem install openweathermap

    Or add to your Gemfile:
      gem 'openweathermap'

    Then run: bundle install
    #{'=' * 80}
  ERROR_MSG

  exit 1
end

# Check for API key
unless ENV['OPENWEATHER_API_KEY']
  title "ERROR: OpenWeatherMap API key not configured"

  puts <<~ERROR_MSG

    This example requires an OpenWeatherMap API key.

    Steps to get started:
    1. Sign up for a free API key at: https://openweathermap.org/api
    2. Set the environment variable:
       export OPENWEATHER_API_KEY="your_api_key_here"

    Or add to your .bashrc or .zshrc:
       export OPENWEATHER_API_KEY="your_api_key_here"
    #{'=' * 80}
  ERROR_MSG

  exit 1
end

title "WeatherTool Example - LLM-Powered Weather Data"

# Register the WeatherTool with RubyLLM
tools = [
  SharedTools::Tools::WeatherTool.new
]

# Create a chat instance using ollama_chat helper
@chat = ollama_chat()

# Add tools to the chat
tools.each { |tool| @chat = @chat.with_tool(tool) }

# Example 1: Simple weather query
title "Example 1: Current Weather for a City", bc: '-'
prompt = "What's the current weather in London, UK?"
test_with_prompt prompt


# Example 2: Weather with specific units
title "Example 2: Weather in Imperial Units", bc: '-'
prompt = "Get the weather for New York, USA in Fahrenheit"
test_with_prompt prompt


# Example 3: Multiple cities comparison
title "Example 3: Compare Weather Across Cities", bc: '-'
prompt = "What's the temperature in Tokyo, Japan?"
test_with_prompt prompt

prompt = "Now check the temperature in Sydney, Australia"
test_with_prompt prompt


# Example 4: Detailed weather information
title "Example 4: Detailed Weather Data", bc: '-'
prompt = "Tell me about the weather in Paris, France. I want to know temperature, humidity, and wind speed."
test_with_prompt prompt


# Example 5: Weather with forecast
title "Example 5: Current Weather with 3-Day Forecast", bc: '-'
prompt = "Get the current weather for Seattle,US and include a 3-day forecast"
test_with_prompt prompt


# Example 6: Metric units
title "Example 6: Weather in Metric Units", bc: '-'
prompt = "What's the weather like in Berlin, Germany? Use metric units."
test_with_prompt prompt


# Example 7: Conversational weather queries
title "Example 7: Conversational Weather Context", bc: '-'

prompt = "Is it raining in Mumbai, India right now?"
test_with_prompt prompt

prompt = "What about the wind conditions there?"
test_with_prompt prompt

title "Example completed!"

puts <<~TAKEAWAYS

  Key Takeaways:
  - The LLM fetches real-time weather data using OpenWeatherMap API
  - Supports multiple unit systems (metric, imperial, kelvin)
  - Can retrieve current conditions and forecasts
  - Natural language queries are converted to proper API calls
  - The LLM maintains conversational context
  - Weather data includes temperature, humidity, wind, and more

  Note: This tool requires an active internet connection and valid API key.

TAKEAWAYS
