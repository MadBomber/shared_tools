# frozen_string_literal: true

# shared_tools/mcp/slack_client.rb
#
# Slack MCP Server — local binary over stdio
#
# Provides Slack workspace access: read channels, messages, and threads,
# search message history, list users, and (optionally) post messages.
#
# Prerequisites:
#   - The slack-mcp-server binary on PATH. Install it with
#     SharedTools::MCP::Slack.install_packages! (Homebrew/apt/dnf) or by hand.
#   - A Slack token — at least one of the following must be set:
#       SLACK_MCP_XOXP_TOKEN — user OAuth token (xoxp-...) — full access
#       SLACK_MCP_XOXB_TOKEN — bot token (xoxb-...) — limited to invited channels, no search
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
#   chat  = RubyLLM.chat.with_mcp(SharedTools::MCP::Slack)
#   robot = RobotLab.build(name: "slacker", mcp: [SharedTools::MCP::Slack])
#
# Requires ruby_llm >= 2.1 (built-in RubyLLM::MCP). Nothing starts until the
# server's tools are first requested. Variables are read when the server
# process starts; unset ones are passed as "", which the server treats as unset.

require_relative "client_support"

module SharedTools
  module MCP
    class Slack < ::RubyLLM::MCP
      extend ClientSupport

      TOKEN_ENVARS = %w[SLACK_MCP_XOXP_TOKEN SLACK_MCP_XOXB_TOKEN].freeze

      requires_packages "slack-mcp-server"

      command "slack-mcp-server"
      env "SLACK_MCP_XOXP_TOKEN"       => env_from("SLACK_MCP_XOXP_TOKEN"),
          "SLACK_MCP_XOXB_TOKEN"       => env_from("SLACK_MCP_XOXB_TOKEN"),
          "SLACK_MCP_ADD_MESSAGE_TOOL" => env_from("SLACK_MCP_ADD_MESSAGE_TOOL")

      # Either token is enough, so this replaces the all-of requires_envars check.
      def self.missing_envars
        return [] if TOKEN_ENVARS.any? { |name| !ENV.fetch(name, "").empty? }

        ["SLACK_MCP_XOXP_TOKEN or SLACK_MCP_XOXB_TOKEN"]
      end
    end
  end
end
