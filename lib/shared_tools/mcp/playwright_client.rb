# shared_tools/mcp/playwright_client.rb
#
# Playwright MCP Server Client — npx auto-download (no pre-installation required)
#
# Provides browser automation via Playwright: navigate pages, click elements,
# fill forms, take screenshots, extract text/HTML, and interact with web apps.
#
# Uses the official @playwright/mcp package from the Playwright team.
#
# Prerequisites:
#   - Node.js and npx (https://nodejs.org)
#   The @playwright/mcp package is downloaded automatically on first use via `npx -y`.
#
# Configuration:
#   No environment variables required.
#
# Usage:
#   require 'shared_tools/mcp/playwright_client'
#   client = RubyLLM::MCP.clients["playwright"]
#   chat = RubyLLM.chat.with_tools(*client.tools)
#
# Compatible with ruby_llm-mcp >= 0.7.0

require "ruby_llm/mcp"

RubyLLM::MCP.add_client(
  name: "playwright",
  transport_type: :stdio,
  config: {
    command: "npx",
    args:    ["-y", "@playwright/mcp"],
    env:     {},
  },
)
