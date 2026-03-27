#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: Playwright MCP Client
#
# Browser automation via Playwright — navigate pages, click elements,
# fill forms, take screenshots, and extract content from web apps.
# Requires Node.js/npx (package auto-downloads on first use).
#
# Prerequisites:
#   Node.js / npx   — https://nodejs.org
#
# Run:
#   bundle exec ruby -I lib -I examples examples/mcp/playwright_demo.rb

require_relative 'common'

title "Playwright MCP Client Demo"

begin
  require 'shared_tools/mcp/playwright_client'
rescue LoadError => e
  puts "unable to load the client: #{e.message}"
  exit
end

client = RubyLLM::MCP.clients['playwright']

title "Page Navigation & Text Extraction", char: '-'
begin
  @chat = new_chat.with_tools(*client.tools)
  ask "Navigate to https://example.com and tell me the full text content of the page."
rescue => e
  puts "  Error: #{e.message}"
end

title "Screenshot", char: '-'
begin
  @chat = new_chat.with_tools(*client.tools)
  ask "Navigate to https://example.org, take a screenshot, and describe what you see on the page."
rescue => e
  puts "  Error: #{e.message}"
end

title "Link Extraction", char: '-'
begin
  @chat = new_chat.with_tools(*client.tools)
  ask "Navigate to https://www.ruby-lang.org and list all the navigation links you find on the page."
rescue => e
  puts "  Error: #{e.message}"
end

title "Done", char: '-'
puts "Playwright npx MCP client demonstrated."
