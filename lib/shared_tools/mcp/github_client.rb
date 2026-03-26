# shared_tools/mcp/github_client.rb
#
# GitHub MCP Server Client — requires brew installation
#
# Provides full GitHub API access: repositories, issues, pull requests,
# code search, commits, branches, releases, and more.
#
# Prerequisites:
#   - Homebrew (https://brew.sh)
#   - A GitHub Personal Access Token
#   The github-mcp-server binary is installed automatically via brew if missing.
#
# Configuration:
#   export GITHUB_PERSONAL_ACCESS_TOKEN=your_token_here
#
# Usage:
#   require 'shared_tools/mcp/github_client'
#   client = RubyLLM::MCP.clients["github"]
#   chat = RubyLLM.chat.with_tools(*client.tools)
#
# Compatible with ruby_llm-mcp >= 0.7.0

require_relative "../utilities"

return unless SharedTools.verify_envars("GITHUB_PERSONAL_ACCESS_TOKEN")
return unless SharedTools.package_install("github-mcp-server")

require "ruby_llm/mcp"

RubyLLM::MCP.add_client(
  name: "github",
  transport_type: :stdio,
  config: {
    command: "github-mcp-server",
    args:    ["stdio"],
    env:     { "GITHUB_PERSONAL_ACCESS_TOKEN" => ENV.fetch("GITHUB_PERSONAL_ACCESS_TOKEN", "") },
  },
)
