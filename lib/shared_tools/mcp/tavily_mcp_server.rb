# shared_tools/mcp/tavily_mcp_server.rb
#
# Tavily MCP Server Client Configuration for ruby_llm-mcp >= 0.7.0
#
# Provides AI-powered web search and research capabilities:
#   - Web search with AI-optimized results
#   - Research-grade content extraction
#   - Real-time information gathering
#   - News and current events search
#
# Installation:
#   Requires Node.js and npx (comes with Node.js)
#   The mcp-remote package will be installed automatically via npx
#
# Configuration:
#   Set environment variable: TAVILY_API_KEY
#   export TAVILY_API_KEY=your_api_key_here
#   Get your API key at: https://tavily.com
#
# Compatible with ruby_llm-mcp v0.7.0+

require "ruby_llm/mcp"

RubyLLM::MCP.add_client(
  name: "tavily",
  transport_type: :stdio,
  config: {
    command: "npx -y mcp-remote https://mcp.tavily.com/mcp/?tavilyApiKey=#{ENV.fetch('TAVILY_API_KEY')}",
    env: {}
  }
)


__END__


# {
#   "mcpServers": {
#     "tavily-remote-mcp": {
#       "command": "npx -y mcp-remote https://mcp.tavily.com/mcp/?tavilyApiKey=$TAVILY_API_KEY",
#       "env": {}
#     }
#   }
# }
