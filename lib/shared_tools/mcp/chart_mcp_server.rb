# shared_tools/mcp/chart_mcp_server.rb
#
# AntV Chart MCP Server — npx auto-download (no pre-installation required)
#
# Generates charts and data visualisations (bar, line, pie, scatter, heatmap, etc.)
# from structured data. Returns chart URLs or base64-encoded images.
#
# Prerequisites:
#   - Node.js and npx (https://nodejs.org)
#   The @antv/mcp-server-chart package is downloaded automatically on first use
#   via `npx -y`.
#
# No API key required.
#
# Usage:
#   require 'shared_tools/mcp/chart_mcp_server'
#   client = RubyLLM::MCP.clients["chart"]
#   chat = RubyLLM.chat.with_tools(*client.tools)
#
# Compatible with ruby_llm-mcp >= 0.7.0

require "ruby_llm/mcp"

RubyLLM::MCP.add_client(
  name: "chart",
  transport_type: :stdio,
  config: {
    command: "npx",
    args:    ["-y", "@antv/mcp-server-chart"],
    env:     {},
  },
)
