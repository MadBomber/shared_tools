# shared_tools/mcp/brave_search_mcp_server.rb
#
# Brave Search MCP Server — npx auto-download (no pre-installation required)
#
# Provides web search and news search via the Brave Search API.
#
# Prerequisites:
#   - Node.js and npx (https://nodejs.org)
#   - A Brave Search API key (free tier available at https://brave.com/search/api/)
#   The @modelcontextprotocol/server-brave-search package is downloaded
#   automatically on first use via `npx -y`.
#
# Configuration:
#   export BRAVE_API_KEY=your_api_key_here
#
# Usage:
#   require 'shared_tools/mcp/brave_search_mcp_server'
#   client = RubyLLM::MCP.clients["brave-search"]
#   chat = RubyLLM.chat.with_tools(*client.tools)
#
# Compatible with ruby_llm-mcp >= 0.7.0

require "ruby_llm/mcp"

RubyLLM::MCP.add_client(
  name: "brave-search",
  transport_type: :stdio,
  config: {
    command: "npx",
    args:    ["-y", "@modelcontextprotocol/server-brave-search"],
    env:     { "BRAVE_API_KEY" => ENV.fetch("BRAVE_API_KEY", "") },
  },
)
