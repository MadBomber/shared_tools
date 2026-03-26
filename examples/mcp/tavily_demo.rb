#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: Tavily MCP Client
#
# AI-optimized web search via Tavily's remote HTTP MCP endpoint.
# No Node.js required — only a Tavily API key.
#
# Prerequisites:
#   export TAVILY_API_KEY=your_key    # https://tavily.com (free tier)
#
# Run:
#   bundle exec ruby -I lib -I examples examples/mcp/tavily_demo.rb

require_relative 'common'

title "Tavily MCP Client Demo"

begin
  require 'shared_tools/mcp/tavily_client'
rescue LoadError => e
  puts "unable to load the client: #{e.message}"
  exit
end

client = RubyLLM::MCP.clients['tavily']
@chat  = new_chat.with_tools(*client.tools)

title "Web Search", char: '-'
ask "Search for the most recent Ruby language release and summarise what's new."

title "News Search", char: '-'
ask "Search for recent news about the Model Context Protocol (MCP) and summarise the top stories."

title "Research", char: '-'
ask "Search for and summarise the key differences between Anthropic Claude and OpenAI GPT-4 for use in coding assistants."

title "Done", char: '-'
puts "Tavily remote HTTP MCP client demonstrated — no local installation required."
