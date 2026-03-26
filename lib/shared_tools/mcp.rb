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
#   require 'shared_tools/mcp/tavily_client'      # Web search (TAVILY_API_KEY)
#
# NPX AUTO-DOWNLOAD (transport: :stdio via npx -y)
#   The npm package is downloaded on first use. Requires Node.js / npx.
#
#   require 'shared_tools/mcp/memory_client'              # Persistent knowledge graph
#   require 'shared_tools/mcp/sequential_thinking_client' # Chain-of-thought reasoning
#   require 'shared_tools/mcp/chart_client'               # Chart / visualisation generation
#   require 'shared_tools/mcp/brave_search_client'        # Web search (BRAVE_API_KEY)
#
# Requiring this file loads ALL available clients concurrently using threads.
# Each client's transport connection is established in parallel, so total startup
# time equals the slowest single client rather than the sum of all clients.
#
# Clients whose API keys are missing are silently skipped.
#
# After loading, access clients via:
#   client = RubyLLM::MCP.clients["client-name"]
#   chat   = RubyLLM.chat.with_tools(*client.tools)

require "ruby_llm/mcp"

threads = Dir[File.join(__dir__, "mcp", "*_client.rb")].map do |path|
  Thread.new do
    require path
  rescue => e
    warn "SharedTools::MCP — failed to load #{File.basename(path)}: #{e.message}"
  end
end

threads.each(&:join)
