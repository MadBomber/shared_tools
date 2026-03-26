# shared_tools/mcp/tavily_mcp_server.rb
#
# Tavily MCP Server Client — Remote HTTP (no local installation required)
#
# Connects directly to Tavily's hosted MCP endpoint via Streamable HTTP transport.
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
#   require 'shared_tools/mcp/tavily_mcp_server'
#   client = RubyLLM::MCP.clients["tavily"]
#   chat = RubyLLM.chat.with_tools(*client.tools)
#
# Compatible with ruby_llm-mcp >= 0.7.0

require "ruby_llm/mcp"

RubyLLM::MCP.add_client(
  name: "tavily",
  transport_type: :streamable,
  config: {
    url:     "https://mcp.tavily.com/mcp/",
    headers: { "Authorization" => "Bearer #{ENV.fetch('TAVILY_API_KEY', '')}" },
  },
)
