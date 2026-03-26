# shared_tools/mcp/memory_mcp_server.rb
#
# MCP Memory Server — npx auto-download (no pre-installation required)
#
# Provides a persistent knowledge graph that the LLM can read and write across
# conversations: create/update/delete entities, add relations, search memories.
#
# Prerequisites:
#   - Node.js and npx (https://nodejs.org)
#   The @modelcontextprotocol/server-memory package is downloaded automatically
#   on first use via `npx -y`.
#
# Configuration (all optional):
#   export MEMORY_FILE_PATH=/path/to/memory.jsonl   # default: memory.jsonl in cwd
#
# Usage:
#   require 'shared_tools/mcp/memory_mcp_server'
#   client = RubyLLM::MCP.clients["memory"]
#   chat = RubyLLM.chat.with_tools(*client.tools)
#
# Compatible with ruby_llm-mcp >= 0.7.0

require "ruby_llm/mcp"

RubyLLM::MCP.add_client(
  name: "memory",
  transport_type: :stdio,
  config: {
    command: "npx",
    args:    ["-y", "@modelcontextprotocol/server-memory"],
    env:     ENV['MEMORY_FILE_PATH'] ? { "MEMORY_FILE_PATH" => ENV['MEMORY_FILE_PATH'] } : {},
  },
)
