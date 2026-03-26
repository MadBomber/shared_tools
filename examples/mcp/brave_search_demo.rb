#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: Brave Search MCP Client
#
# Web and news search via the Brave Search API.
# Requires Node.js/npx (package auto-downloads on first use).
#
# Prerequisites:
#   Node.js / npx             — https://nodejs.org
#   export BRAVE_API_KEY=your_key   # https://brave.com/search/api/ (free tier)
#
# Run:
#   bundle exec ruby -I lib -I examples examples/mcp/brave_search_demo.rb

require_relative 'common'

title "Brave Search MCP Client Demo"

begin
  require 'shared_tools/mcp/brave_search_client'
rescue LoadError => e
  puts "unable to load the client: #{e.message}"
  exit
end

client = RubyLLM::MCP.clients['brave-search']
@chat  = new_chat.with_tools(*client.tools)

title "Web Search", char: '-'
ask "Search the web for the latest Homebrew release and summarise what changed."

title "News Search", char: '-'
ask "Search for recent news about Ruby on Rails and summarise the top stories."

title "Done", char: '-'
puts "Brave Search npx MCP client demonstrated."
