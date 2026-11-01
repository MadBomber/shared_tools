# frozen_string_literal: true

# shared_tools/mcp/notion_client.rb
#
# Notion MCP Server — local binary over stdio
#
# Provides full Notion workspace access: search pages and databases,
# read and update content, create pages, and query databases.
#
# Prerequisites:
#   - The notion-mcp-server binary on PATH. Install it with
#     SharedTools::MCP::Notion.install_packages! (Homebrew/apt/dnf) or by hand.
#   - A Notion internal integration token
#     Create one at https://www.notion.so/profile/integrations
#     then share the relevant pages/databases with the integration.
#
# Configuration:
#   export NOTION_TOKEN=ntn_your_integration_token_here
#
# Usage:
#   require 'shared_tools/mcp/notion_client'
#   chat  = RubyLLM.chat.with_mcp(SharedTools::MCP::Notion)
#   robot = RobotLab.build(name: "notes", mcp: [SharedTools::MCP::Notion])
#
# Requires ruby_llm >= 2.1 (built-in RubyLLM::MCP). Nothing starts until the
# server's tools are first requested.

require_relative "client_support"

module SharedTools
  module MCP
    class Notion < ::RubyLLM::MCP
      extend ClientSupport

      requires_envars   "NOTION_TOKEN"
      requires_packages "notion-mcp-server"

      command "notion-mcp-server"
      env "NOTION_TOKEN" => env_from("NOTION_TOKEN")
    end
  end
end
