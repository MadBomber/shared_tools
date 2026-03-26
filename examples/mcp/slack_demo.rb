#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: Slack MCP Client
#
# Read channels, messages, threads, and user info from a Slack workspace.
# Requires Homebrew (installed automatically if missing).
#
# Prerequisites:
#   Homebrew                          — https://brew.sh
#   export SLACK_MCP_XOXP_TOKEN=xoxp-...  # user OAuth token (recommended)
#   # OR
#   export SLACK_MCP_XOXB_TOKEN=xoxb-...  # bot token (limited access)
#
# Run:
#   bundle exec ruby -I lib -I examples examples/mcp/slack_demo.rb

require_relative 'common'

title "Slack MCP Client Demo"

begin
  require 'shared_tools/mcp/slack_client'
rescue LoadError => e
  puts "unable to load the client: #{e.message}"
  exit
end

client = RubyLLM::MCP.clients['slack']
@chat  = new_chat.with_tools(*client.tools)

title "Channel Overview", char: '-'
ask "List the channels in this Slack workspace. Group them by type (public vs private if visible) and give a brief description of what each channel appears to be used for based on its name and topic."

title "Recent Messages", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask "What has been discussed in the most active channels recently? Summarise the key topics from the last few days of messages across 2-3 channels."

title "Thread Deep-Dive", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask "Find an interesting or substantive conversation thread from the past week. Summarise the discussion, who was involved, and what conclusions (if any) were reached."

title "Team Activity", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask "Who have been the most active contributors in the workspace recently? What topics or projects are they focused on based on their messages?"

title "Done", char: '-'
puts "Slack brew-installed MCP client demonstrated."
