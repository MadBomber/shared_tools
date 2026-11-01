# frozen_string_literal: true

# shared_tools/mcp/sequential_thinking_client.rb
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
#   automatically the first time the server is started, via `npx -y`.
#
# No API key required.
#
# Usage:
#   require 'shared_tools/mcp/sequential_thinking_client'
#   chat  = RubyLLM.chat.with_mcp(SharedTools::MCP::SequentialThinking)
#   robot = RobotLab.build(name: "thinker", mcp: [SharedTools::MCP::SequentialThinking])
#
# Requires ruby_llm >= 2.1 (built-in RubyLLM::MCP). Nothing starts until the
# server's tools are first requested.

require_relative "client_support"

module SharedTools
  module MCP
    class SequentialThinking < ::RubyLLM::MCP
      extend ClientSupport

      command "npx", "-y", "@modelcontextprotocol/server-sequential-thinking"
    end
  end
end
