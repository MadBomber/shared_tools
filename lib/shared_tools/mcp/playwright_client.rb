# frozen_string_literal: true

# shared_tools/mcp/playwright_client.rb
#
# Playwright MCP Server — npx auto-download (no pre-installation required)
#
# Provides browser automation via Playwright: navigate pages, click elements,
# fill forms, take screenshots, extract text/HTML, and interact with web apps.
#
# Uses the official @playwright/mcp package from the Playwright team.
#
# Prerequisites:
#   - Node.js and npx (https://nodejs.org)
#   The @playwright/mcp package is downloaded automatically the first time the
#   server is started, via `npx -y`.
#
# Configuration:
#   No environment variables required.
#
# Usage:
#   require 'shared_tools/mcp/playwright_client'
#   chat  = RubyLLM.chat.with_mcp(SharedTools::MCP::Playwright)
#   robot = RobotLab.build(name: "browser", mcp: [SharedTools::MCP::Playwright])
#
# Requires ruby_llm >= 2.1 (built-in RubyLLM::MCP). Nothing starts until the
# server's tools are first requested.

require_relative "client_support"

module SharedTools
  module MCP
    class Playwright < ::RubyLLM::MCP
      extend ClientSupport

      command "npx", "-y", "@playwright/mcp"
    end
  end
end
