#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: Notion MCP Client
#
# Full Notion workspace access — search pages and databases, read content,
# create and update pages, query databases.
# Requires Homebrew (installed automatically if missing).
#
# Prerequisites:
#   Homebrew                    — https://brew.sh
#   export NOTION_TOKEN=ntn_... — create at https://www.notion.so/profile/integrations
#   Share relevant pages/databases with the integration before running.
#
# Run:
#   bundle exec ruby -I lib -I examples examples/mcp/notion_demo.rb

require_relative 'common'

title "Notion MCP Client Demo"

begin
  require 'shared_tools/mcp/notion_client'
rescue LoadError => e
  puts "unable to load the client: #{e.message}"
  exit
end

client = RubyLLM::MCP.clients['notion']
@chat  = new_chat.with_tools(*client.tools)

title "Search Pages", char: '-'
ask "Search my Notion workspace for any pages or documents. List up to 5 results with their titles and a brief description of what each contains."

title "Explore Databases", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask "Find any databases in my Notion workspace. For each one, describe what kind of data it tracks and list a few sample entries if available."

title "Recent Activity", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask "Find the most recently edited pages in my Notion workspace. What were the last few things that were worked on?"

title "Content Summary", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask "Pick the most interesting or content-rich page you can find in my Notion workspace and give me a detailed summary of what it contains."

title "Done", char: '-'
puts "Notion brew-installed MCP client demonstrated."
