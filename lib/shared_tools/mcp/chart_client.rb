# frozen_string_literal: true

# shared_tools/mcp/chart_client.rb
#
# AntV Chart MCP Server — npx auto-download (no pre-installation required)
#
# Generates charts and data visualisations (bar, line, pie, scatter, heatmap, etc.)
# from structured data. Returns chart URLs or base64-encoded images.
#
# Prerequisites:
#   - Node.js and npx (https://nodejs.org)
#   The @antv/mcp-server-chart package is downloaded automatically the first
#   time the server is started, via `npx -y`.
#
# No API key required.
#
# Usage:
#   require 'shared_tools/mcp/chart_client'
#   chat  = RubyLLM.chat.with_mcp(SharedTools::MCP::Chart)
#   robot = RobotLab.build(name: "analyst", mcp: [SharedTools::MCP::Chart])
#
# Requires ruby_llm >= 2.1 (built-in RubyLLM::MCP). Nothing starts until the
# server's tools are first requested.

require_relative "client_support"

module SharedTools
  module MCP
    class Chart < ::RubyLLM::MCP
      extend ClientSupport

      command "npx", "-y", "@antv/mcp-server-chart"
    end
  end
end
