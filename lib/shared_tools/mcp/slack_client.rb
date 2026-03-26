# shared_tools/mcp/slack_client.rb
#
# Slack MCP Server Client — requires brew installation
#
# Provides Slack workspace access: read channels, messages, and threads,
# search message history, list users, and (optionally) post messages.
#
# Prerequisites:
#   - Homebrew (https://brew.sh)
#   - A Slack token — at least one of the following must be set:
#       SLACK_MCP_XOXP_TOKEN — user OAuth token (xoxp-...) — full access
#       SLACK_MCP_XOXB_TOKEN — bot token (xoxb-...) — limited to invited channels, no search
#   The slack-mcp-server binary is installed automatically via brew if missing.
#
# Configuration:
#   export SLACK_MCP_XOXP_TOKEN=xoxp-your-user-token   # recommended
#   # OR
#   export SLACK_MCP_XOXB_TOKEN=xoxb-your-bot-token
#
# Optional — posting messages is disabled by default for safety:
#   export SLACK_MCP_ADD_MESSAGE_TOOL=true              # enable for all channels
#   export SLACK_MCP_ADD_MESSAGE_TOOL=C012AB3CD,C98765  # enable for specific channels only
#
# Usage:
#   require 'shared_tools/mcp/slack_client'
#   client = RubyLLM::MCP.clients["slack"]
#   chat = RubyLLM.chat.with_tools(*client.tools)
#
# Compatible with ruby_llm-mcp >= 0.7.0

require_relative "../utilities"

xoxp = ENV.fetch("SLACK_MCP_XOXP_TOKEN", "")
xoxb = ENV.fetch("SLACK_MCP_XOXB_TOKEN", "")
raise LoadError, "SLACK_MCP_XOXP_TOKEN or SLACK_MCP_XOXB_TOKEN must be set" if xoxp.empty? && xoxb.empty?

SharedTools.package_install("slack-mcp-server")

require "ruby_llm/mcp"

slack_env = {}
slack_env["SLACK_MCP_XOXP_TOKEN"] = xoxp unless xoxp.empty?
slack_env["SLACK_MCP_XOXB_TOKEN"] = xoxb unless xoxb.empty?
slack_env["SLACK_MCP_ADD_MESSAGE_TOOL"] = ENV["SLACK_MCP_ADD_MESSAGE_TOOL"] if ENV["SLACK_MCP_ADD_MESSAGE_TOOL"]

RubyLLM::MCP.add_client(
  name: "slack",
  transport_type: :stdio,
  config: {
    command: "slack-mcp-server",
    args:    [],
    env:     slack_env,
  },
)
