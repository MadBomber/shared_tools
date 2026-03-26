# lib/shared_tools/mcp.rb
#
# MCP (Model Context Protocol) client support for SharedTools.
# Requires the ruby_llm-mcp gem >= 0.7.0 and RubyLLM >= 1.9.0.
#
# @see https://github.com/patvice/ruby_llm-mcp
# @see https://www.rubyllm-mcp.com
#
# Two categories of client are provided, both requiring no pre-installed binaries:
#
# REMOTE HTTP (transport: :streamable)
#   Connect to cloud-hosted MCP servers. Requires only an API key.
#
#   require 'shared_tools/mcp/tavily_mcp_server'      # Web search (TAVILY_API_KEY)
#
# NPX AUTO-DOWNLOAD (transport: :stdio via npx -y)
#   The npm package is downloaded on first use. Requires Node.js / npx.
#
#   require 'shared_tools/mcp/memory_mcp_server'              # Persistent knowledge graph
#   require 'shared_tools/mcp/sequential_thinking_mcp_server' # Chain-of-thought reasoning
#   require 'shared_tools/mcp/chart_mcp_server'               # Chart / visualisation generation
#   require 'shared_tools/mcp/brave_search_mcp_server'        # Web search (BRAVE_API_KEY)
#
# After requiring a client file, access it via:
#   client = RubyLLM::MCP.clients["client-name"]
#   chat   = RubyLLM.chat.with_tools(*client.tools)
