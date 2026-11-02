# frozen_string_literal: true

# shared_tools/mcp/tavily_client.rb
#
# Tavily MCP Server — Remote Streamable HTTP (no local installation required)
#
# Connects directly to Tavily's hosted MCP endpoint.
# No npx, no Node.js, no local binary required — only a Tavily API key.
#
# Provides:
#   - AI-optimized web search
#   - Research-grade content extraction
#   - Real-time news and current events
#
# Configuration:
#   export TAVILY_API_KEY=your_api_key_here
#   Get a free key at: https://tavily.com
#
# Usage:
#   require 'shared_tools/mcp/tavily_client'
#   chat  = RubyLLM.chat.with_mcp(SharedTools::MCP::Tavily)
#   robot = RobotLab.build(name: "researcher", mcp: [SharedTools::MCP::Tavily])
#
# Requires ruby_llm >= 2.1 (built-in RubyLLM::MCP). No request is made until
# the server's tools are first requested.

require_relative "client_support"

module SharedTools
  module MCP
    class Tavily < ::RubyLLM::MCP
      extend ClientSupport

      description "Tavily web search and page extraction for research and current events"

      requires_envars "TAVILY_API_KEY"

      url "https://mcp.tavily.com/mcp/"
      bearer_token { ENV.fetch("TAVILY_API_KEY", "") }
      timeout 30
    end
  end
end
