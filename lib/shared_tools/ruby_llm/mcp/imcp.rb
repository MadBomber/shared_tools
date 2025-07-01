# shared_tools/ruby_llm/mcp/imcp.rb
# iMCP is a MacOS program that provides access to notes,calendar,contacts, etc.
# See: https://github.com/loopwork/iMCP
# brew install --cask loopwork/tap/iMCP
#
# CAUTION: AIA is getting an exception when trying to use this MCP client.  Its returning to
#          do a to_sym on a nil value.  This is due to a lack of a nil guard in the
#          version 0.3.1 of the ruby_llm-mpc Parameter#item_type method.

require 'debug_me'
include DebugMe

require 'ruby_llm'
require 'ruby_llm/mcp'

require_relative '../../../shared_tools'

module SharedTools
  verify_gem :ruby_llm

  mcp_servers << RubyLLM::MCP.client(
    name: "imcp-server",
    transport_type: :stdio,
    config: {
      command: "/Applications/iMCP.app/Contents/MacOS/imcp-server"
    }
  )
end
