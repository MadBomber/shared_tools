#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: CurrentDateTimeTool
#
# Returns the current date, time, timezone, and related calendar metadata from the system.
#
# Run:
#   bundle exec ruby -I examples examples/current_date_time_tool_demo.rb

require_relative 'common'
require 'shared_tools/tools/current_date_time_tool'


title "CurrentDateTimeTool Demo — system date, time, and timezone information"

@chat = @chat.with_tool(SharedTools::Tools::CurrentDateTimeTool.new)

ask "What is the current date and time?"

ask "What day of the week is it today, and what week number of the year is this?"

ask "Give me only the date-related information: year, month, day, and quarter."

ask "Give me only the time-related information including the UTC offset."

ask "What is the current datetime in ISO 8601 format, and what is the equivalent UTC time?"

ask "What is the current Unix timestamp?"

ask "Is daylight saving time currently in effect on this system?"

title "Done", char: '-'
puts "CurrentDateTimeTool demonstrated full, date-only, time-only, ISO 8601, and UTC offset output formats."
