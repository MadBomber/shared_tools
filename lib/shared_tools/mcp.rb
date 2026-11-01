# frozen_string_literal: true

# lib/shared_tools/mcp.rb
#
# MCP (Model Context Protocol) server definitions for SharedTools.
# Requires ruby_llm >= 2.1, whose built-in RubyLLM::MCP is the client.
# (The separate ruby_llm-mcp gem is not used and cannot be loaded alongside it.)
#
# Each server is a RubyLLM::MCP subclass under SharedTools::MCP. Requiring a
# definition has no side effects — nothing is started, downloaded or connected
# until a chat or robot first asks the server for its tools.
#
# REMOTE HTTP (Streamable HTTP)
#   SharedTools::MCP::Tavily              # Web search (TAVILY_API_KEY)
#
# LOCAL BINARY (stdio; install with Klass.install_packages!)
#   SharedTools::MCP::GitHub              # GITHUB_PERSONAL_ACCESS_TOKEN
#   SharedTools::MCP::Notion              # NOTION_TOKEN
#   SharedTools::MCP::Slack               # SLACK_MCP_XOXP_TOKEN or SLACK_MCP_XOXB_TOKEN
#   SharedTools::MCP::HuggingFace         # HF_TOKEN
#
# NPX AUTO-DOWNLOAD (stdio via npx -y; requires Node.js)
#   SharedTools::MCP::Memory              # Persistent knowledge graph
#   SharedTools::MCP::SequentialThinking  # Chain-of-thought reasoning
#   SharedTools::MCP::Chart               # Chart / visualisation generation
#   SharedTools::MCP::BraveSearch         # Web search (BRAVE_API_KEY)
#   SharedTools::MCP::Playwright          # Browser automation
#
# Requiring this file loads every definition and records, per server, whether
# its required environment variables are set (see SharedTools.mcp_status).
#
#   require 'shared_tools/mcp'
#   chat  = RubyLLM.chat.with_mcp(*SharedTools::MCP.available)
#   robot = RobotLab.build(name: "bot", mcp: SharedTools::MCP.available)

require_relative "mcp/client_support"

Dir[File.join(__dir__, "mcp", "*_client.rb")].sort.each { |path| require path }

SharedTools::MCP.clients.each do |klass|
  missing = klass.missing_envars
  error   = missing.empty? ? nil : LoadError.new("Missing envars: #{missing.join(', ')}")
  SharedTools.record_mcp_result(klass.default_name, error: error)
end
