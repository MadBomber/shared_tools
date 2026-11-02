# frozen_string_literal: true

# shared_tools/mcp/brave_search_client.rb
#
# Brave Search MCP Server — npx auto-download (no pre-installation required)
#
# Provides web search and news search via the Brave Search API.
#
# Prerequisites:
#   - Node.js and npx (https://nodejs.org)
#   - A Brave Search API key (free tier available at https://brave.com/search/api/)
#   The @modelcontextprotocol/server-brave-search package is downloaded
#   automatically the first time the server is started, via `npx -y`.
#
# Configuration:
#   export BRAVE_API_KEY=your_api_key_here
#
# Usage:
#   require 'shared_tools/mcp/brave_search_client'
#   chat  = RubyLLM.chat.with_mcp(SharedTools::MCP::BraveSearch)
#   robot = RobotLab.build(name: "researcher", mcp: [SharedTools::MCP::BraveSearch])
#
# Requires ruby_llm >= 2.1 (built-in RubyLLM::MCP). Nothing starts until the
# server's tools are first requested.

require_relative "client_support"

module SharedTools
  module MCP
    class BraveSearch < ::RubyLLM::MCP
      extend ClientSupport

      description "Brave web search: current web pages, news, and local results"

      requires_envars "BRAVE_API_KEY"

      command "npx", "-y", "@modelcontextprotocol/server-brave-search"
      env "BRAVE_API_KEY" => env_from("BRAVE_API_KEY")
    end
  end
end
