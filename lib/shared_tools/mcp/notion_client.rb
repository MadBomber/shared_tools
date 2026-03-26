# shared_tools/mcp/notion_client.rb
#
# Notion MCP Server Client — requires brew installation
#
# Provides full Notion workspace access: search pages and databases,
# read and update content, create pages, and query databases.
#
# Prerequisites:
#   - Homebrew (https://brew.sh)
#   - A Notion internal integration token
#     Create one at https://www.notion.so/profile/integrations
#     then share the relevant pages/databases with the integration.
#   The notion-mcp-server binary is installed automatically via brew if missing.
#
# Configuration:
#   export NOTION_TOKEN=ntn_your_integration_token_here
#
# Usage:
#   require 'shared_tools/mcp/notion_client'
#   client = RubyLLM::MCP.clients["notion"]
#   chat = RubyLLM.chat.with_tools(*client.tools)
#
# Compatible with ruby_llm-mcp >= 0.7.0

require_relative "../utilities"

SharedTools.verify_envars("NOTION_TOKEN")
SharedTools.package_install("notion-mcp-server")

require "ruby_llm/mcp"

RubyLLM::MCP.add_client(
  name: "notion",
  transport_type: :stdio,
  config: {
    command: "notion-mcp-server",
    args:    [],
    env:     { "NOTION_TOKEN" => ENV.fetch("NOTION_TOKEN", "") },
  },
)
