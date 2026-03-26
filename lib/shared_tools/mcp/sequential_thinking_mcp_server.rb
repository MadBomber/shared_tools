# shared_tools/mcp/sequential_thinking_mcp_server.rb
#
# MCP Sequential Thinking Server — npx auto-download (no pre-installation required)
#
# Provides a structured chain-of-thought reasoning tool. The LLM can break complex
# problems into numbered steps, revise earlier steps, and branch reasoning paths
# before committing to a conclusion.
#
# Prerequisites:
#   - Node.js and npx (https://nodejs.org)
#   The @modelcontextprotocol/server-sequential-thinking package is downloaded
#   automatically on first use via `npx -y`.
#
# No API key required.
#
# Usage:
#   require 'shared_tools/mcp/sequential_thinking_mcp_server'
#   client = RubyLLM::MCP.clients["sequential-thinking"]
#   chat = RubyLLM.chat.with_tools(*client.tools)
#
# Compatible with ruby_llm-mcp >= 0.7.0

require "ruby_llm/mcp"

RubyLLM::MCP.add_client(
  name: "sequential-thinking",
  transport_type: :stdio,
  config: {
    command: "npx",
    args:    ["-y", "@modelcontextprotocol/server-sequential-thinking"],
    env:     {},
  },
)
