#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: Memory MCP Client
#
# Persistent knowledge graph — the LLM can store and recall entities,
# relations, and observations across conversations.
# Requires Node.js/npx (package auto-downloads on first use).
#
# Prerequisites:
#   Node.js / npx  — https://nodejs.org
#
# Optional:
#   export MEMORY_FILE_PATH=/path/to/memory.jsonl   # default: memory.jsonl in cwd
#
# Run:
#   bundle exec ruby -I lib -I examples examples/mcp/memory_demo.rb

require_relative 'common'

title "Memory MCP Client Demo"

begin
  require 'shared_tools/mcp/memory_client'
rescue LoadError => e
  puts "unable to load the client: #{e.message}"
  exit
end

client = RubyLLM::MCP.clients['memory']
@chat  = new_chat.with_tools(*client.tools)

title "Store Facts", char: '-'
ask "Remember the following facts: " \
    "(1) This project is called 'shared_tools'. " \
    "(2) It is a Ruby gem that provides LLM-callable tools. " \
    "(3) It supports MCP clients for web search, memory, and chart generation. " \
    "Confirm what you stored."

title "Recall Facts", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask "What do you know about the shared_tools project?"

title "Add a Relation", char: '-'
ask "Remember that shared_tools is maintained by a developer who uses a MacStudio with an M2 Max chip. " \
    "Link this to the shared_tools entity you already know about."

title "Query the Graph", char: '-'
ask "Summarise everything you know about shared_tools and its developer."

title "Done", char: '-'
puts "Memory npx MCP client demonstrated."
