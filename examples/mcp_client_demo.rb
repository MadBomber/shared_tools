#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: MCP Client Integration
#
# Shows how to use MCP (Model Context Protocol) clients with RubyLLM.
# Demonstrates Tavily (web search), GitHub, and iMCP (macOS) clients.
#
# Prerequisites:
#   export TAVILY_API_KEY=your_key             # for Tavily web search
#   export GITHUB_PERSONAL_ACCESS_TOKEN=token  # for GitHub MCP
#   brew install github-mcp-server             # for GitHub MCP
#   brew install --cask loopwork/tap/iMCP      # for iMCP (macOS only)
#
# Run:
#   bundle exec ruby -I examples examples/mcp_client_demo.rb

require_relative 'common'


title "MCP Client Demo — Model Context Protocol Integration"

title "Example 1: Tavily Web Search MCP Client", char: '-'
if ENV['TAVILY_API_KEY']
  begin
    require 'shared_tools/mcp/tavily_mcp_server'
    client = RubyLLM::MCP.clients["tavily"]
    puts "Tavily client loaded — #{client.tools.count} tools available."
  rescue => e
    puts "Error loading Tavily client: #{e.message}"
  end
else
  puts "Skipping — TAVILY_API_KEY not set. Export it to enable this example."
end

title "Example 2: GitHub MCP Server", char: '-'
if ENV['GITHUB_PERSONAL_ACCESS_TOKEN'] && File.exist?("/opt/homebrew/bin/github-mcp-server")
  begin
    require 'shared_tools/mcp/github_mcp_server'
    client = RubyLLM::MCP.clients["github-mcp-server"]
    puts "GitHub MCP client loaded — #{client.tools.count} tools available."
    puts "Sample tools: #{client.tools.take(5).map(&:name).join(', ')}"
  rescue => e
    puts "Error loading GitHub client: #{e.message}"
  end
else
  puts "Skipping — GITHUB_PERSONAL_ACCESS_TOKEN not set or github-mcp-server not installed."
end

title "Example 3: iMCP — macOS Integration", char: '-'
if RUBY_PLATFORM.include?('darwin') && File.exist?("/Applications/iMCP.app")
  begin
    require 'shared_tools/mcp/imcp'
    client = RubyLLM::MCP.clients["imcp-server"]
    puts "iMCP client loaded — #{client.tools.count} tools available (Notes, Calendar, Contacts, Reminders)."
  rescue => e
    puts "Error loading iMCP client: #{e.message}"
  end
else
  puts "Skipping — iMCP.app not installed or not running on macOS."
end

title "Example 4: MCP Tools with LLM Chat", char: '-'
loaded = %w[tavily github-mcp-server imcp-server].filter_map do |name|
  RubyLLM::MCP.clients[name] rescue nil
end

if loaded.any?
  @chat = @chat.with_tools(*loaded.flat_map(&:tools))
  ask "What MCP tools are available and what can you do with them?"
else
  puts "No MCP clients loaded — set API keys and install servers to run this example."
end

title "Done", char: '-'
puts "MCP clients let the LLM reach external services via the Model Context Protocol."
