# shared_tools/mcp/imcp.rb
#
# iMCP Client Configuration for ruby_llm-mcp >= 0.7.0
#
# iMCP is a macOS application that provides MCP access to:
#   - Notes
#   - Calendar
#   - Contacts
#   - Reminders
#   - And other macOS native applications
#
# Installation:
#   brew install --cask loopwork/tap/iMCP
#
# Documentation:
#   https://github.com/loopwork/iMCP
#
# Compatible with ruby_llm-mcp v0.7.0+

require 'ruby_llm/mcp'

RubyLLM::MCP.add_client(
  name: "imcp-server",
  transport_type: :stdio,
  config: {
    command: "/Applications/iMCP.app/Contents/MacOS/imcp-server 2> /dev/null"
  }
)
