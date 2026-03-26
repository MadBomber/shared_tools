#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: Chart MCP Client
#
# Chart and data visualisation generation via AntV.
# Returns chart URLs that are opened automatically in the default browser.
# Requires Node.js/npx (package auto-downloads on first use).
#
# Prerequisites:
#   Node.js / npx  — https://nodejs.org
#
# Run:
#   bundle exec ruby -I lib -I examples examples/mcp/chart_demo.rb

require_relative 'common'

title "Chart MCP Client Demo"

begin
  require 'shared_tools/mcp/chart_client'
rescue LoadError => e
  puts "unable to load the client: #{e.message}"
  exit
end

client = RubyLLM::MCP.clients['chart']
@chat  = new_chat.with_tools(*client.tools)

title "Bar Chart", char: '-'
response = ask <<~PROMPT
  Generate a bar chart showing these monthly active users:
  Jan: 1200, Feb: 1450, Mar: 1800, Apr: 2100, May: 1950, Jun: 2400
  Title it "Monthly Active Users — H1 2026".
PROMPT
open_chart_urls(response)

title "Line Chart", char: '-'
@chat = new_chat.with_tools(*client.tools)
response = ask <<~PROMPT
  Generate a line chart showing the same monthly active user data as a trend over time.
  Title it "MAU Trend — H1 2026".
PROMPT
open_chart_urls(response)

title "Pie Chart", char: '-'
@chat = new_chat.with_tools(*client.tools)
response = ask <<~PROMPT
  Generate a pie chart showing this breakdown of tool usage in the shared_tools gem:
  ShellCommand: 35%, FileRead: 25%, FileEdit: 20%, WebSearch: 12%, Other: 8%
  Title it "Tool Usage Distribution".
PROMPT
open_chart_urls(response)

title "Done", char: '-'
puts "Chart npx MCP client demonstrated."
