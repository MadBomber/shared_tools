# frozen_string_literal: true

# shared_tools/mcp/memory_client.rb
#
# MCP Memory Server — npx auto-download (no pre-installation required)
#
# Provides a persistent knowledge graph that the LLM can read and write across
# conversations: create/update/delete entities, add relations, search memories.
#
# Prerequisites:
#   - Node.js and npx (https://nodejs.org)
#   The @modelcontextprotocol/server-memory package is downloaded automatically
#   the first time the server is started, via `npx -y`.
#
# Configuration (all optional):
#   export MEMORY_FILE_PATH=/path/to/memory.jsonl   # default: the server's own default
#
# Usage:
#   require 'shared_tools/mcp/memory_client'
#   chat  = RubyLLM.chat.with_mcp(SharedTools::MCP::Memory)
#   robot = RobotLab.build(name: "assistant", mcp: [SharedTools::MCP::Memory])
#
# Requires ruby_llm >= 2.1 (built-in RubyLLM::MCP). Nothing starts until the
# server's tools are first requested.

require_relative "client_support"

module SharedTools
  module MCP
    class Memory < ::RubyLLM::MCP
      extend ClientSupport

      description "Persistent knowledge graph memory: remember and recall facts, entities, and relations across conversations"

      command "npx", "-y", "@modelcontextprotocol/server-memory"
      # An unset MEMORY_FILE_PATH resolves to "", which the server treats as unset.
      env "MEMORY_FILE_PATH" => env_from("MEMORY_FILE_PATH")
    end
  end
end
