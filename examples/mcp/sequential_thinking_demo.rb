#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: Sequential Thinking MCP Client
#
# Structured chain-of-thought reasoning — the LLM breaks complex problems
# into numbered steps, revises earlier steps, and branches reasoning paths
# before committing to a conclusion.
# Requires Node.js/npx (package auto-downloads on first use).
#
# Prerequisites:
#   Node.js / npx  — https://nodejs.org
#
# Run:
#   bundle exec ruby -I lib -I examples examples/mcp/sequential_thinking_demo.rb

require_relative 'common'

title "Sequential Thinking MCP Client Demo"

begin
  require 'shared_tools/mcp/sequential_thinking_client'
rescue LoadError => e
  puts "unable to load the client: #{e.message}"
  exit
end

client = RubyLLM::MCP.clients['sequential-thinking']
@chat  = new_chat.with_tools(*client.tools)

title "Cross-platform Design Problem", char: '-'
ask <<~PROMPT
  Use sequential thinking to work through this problem step by step:
  A Ruby gem needs to support both macOS and Linux. It uses system commands
  for notifications, package installation, and browser automation.
  What are the key concerns to address and in what order should they be tackled?
PROMPT

title "Architectural Decision", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask <<~PROMPT
  Use sequential thinking to decide: should a Ruby gem that wraps external CLI
  tools use Thor or OptionParser for its own CLI interface? Walk through the
  trade-offs and reach a recommendation.
PROMPT

title "Debugging Strategy", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask <<~PROMPT
  Use sequential thinking to devise a debugging strategy for this situation:
  A Ruby gem works perfectly in tests but fails silently when loaded inside
  an AI agent framework. No exceptions are raised. How would you isolate the cause?
PROMPT

title "Done", char: '-'
puts "Sequential Thinking npx MCP client demonstrated."
