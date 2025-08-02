# shared_tools/ruby_llm/mcp/tavily_mcp_server.rb

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
