#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: WeatherTool
#
# Shows how an LLM uses the WeatherTool to answer weather-related questions
# and make recommendations — a travel planning assistant that retrieves
# live data for multiple cities.
#
# Also demonstrates combining the DnsTool (for IP geolocation) with the
# WeatherTool to auto-detect the user's location and fetch a local forecast.
#
# Requires: OPENWEATHER_API_KEY environment variable
#   export OPENWEATHER_API_KEY=your_key_here
#   (free tier key at https://openweathermap.org/api)
#
# Run:
#   OPENWEATHER_API_KEY=xxx bundle exec ruby -I examples examples/weather_tool_demo.rb

ENV['RUBY_LLM_DEBUG'] = 'true'

require_relative 'common'
require 'shared_tools/weather_tool'
require 'shared_tools/tools/dns_tool'
require 'shared_tools/tools/current_date_time_tool'


title "WeatherTool Demo"

unless ENV['OPENWEATHER_API_KEY']
  puts "WARNING: OPENWEATHER_API_KEY is not set."
  puts "Set it with: export OPENWEATHER_API_KEY=your_api_key"
  puts "The demo will run but weather lookups will fail."
  puts
end

@chat = @chat.with_tool(SharedTools::Tools::WeatherTool.new)

title "Current Conditions — New York", char: '-'
ask "What is the current weather in New York, US? Use imperial units."

title "Metric Lookup — London", char: '-'
ask "What are the current conditions in London, UK? Use metric units."

title "With Forecast", char: '-'
ask "Get the current weather and a 3-day forecast for Tokyo, JP using metric units."

title "Travel Recommendation", char: '-'
ask <<~PROMPT
  I am planning a weekend trip and considering three cities:
  - Paris, FR
  - Barcelona, ES
  - Amsterdam, NL

  Fetch the current weather for each city (metric units) and recommend
  which destination has the best weather for outdoor sightseeing.
  Explain your reasoning.
PROMPT

title "Packing Advice", char: '-'
ask <<~PROMPT
  I'm travelling to Sydney, AU tomorrow. Get the current weather with a
  3-day forecast and advise me what to pack: clothing layers,
  whether to bring an umbrella, and any other weather-related tips.
PROMPT

title "Temperature Comparison", char: '-'
ask <<~PROMPT
  Fetch the current temperature in metric units for:
  - Reykjavik, IS
  - Dubai, AE
  - Singapore, SG

  What is the temperature difference between the coldest and warmest city?
PROMPT

title "My Local Forecast", char: '-'
@chat = new_chat.with_tools(
  SharedTools::Tools::DnsTool.new,
  SharedTools::Tools::WeatherTool.new,
  SharedTools::Tools::CurrentDateTimeTool.new
)
ask <<~PROMPT
  I want to know the weather where I currently am.

  Use these tools in order:
  1. current_date_time_tool (format: 'date') — get today's actual date and day of week
  2. dns_tool (action: 'external_ip') — get my public IP address
  3. dns_tool (action: 'ip_location') — geolocate that IP to find my city and country
  4. weather_tool — fetch current weather and a 3-day forecast for that city, imperial units

  In your response, use the real date and day of week from the tool (not your training data)
  when labelling today, tomorrow, and the following days.

  Tell me: where am I, what are the current conditions, and what should I expect
  over the next three days?
PROMPT

title "Done", char: '-'
puts "WeatherTool retrieved live weather data and enabled real-world travel planning."
