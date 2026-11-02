# frozen_string_literal: true

# shared_tools/mcp/github_client.rb
#
# GitHub MCP Server — local binary over stdio
#
# Provides full GitHub API access: repositories, issues, pull requests,
# code search, commits, branches, releases, and more.
#
# Prerequisites:
#   - The github-mcp-server binary on PATH. Install it with
#     SharedTools::MCP::GitHub.install_packages! (Homebrew/apt/dnf) or by hand.
#   - A GitHub Personal Access Token
#
# Configuration:
#   export GITHUB_PERSONAL_ACCESS_TOKEN=your_token_here
#
# Usage:
#   require 'shared_tools/mcp/github_client'
#   chat  = RubyLLM.chat.with_mcp(SharedTools::MCP::GitHub)
#   robot = RobotLab.build(name: "dev", mcp: [SharedTools::MCP::GitHub])
#
# Requires ruby_llm >= 2.1 (built-in RubyLLM::MCP). Nothing starts until the
# server's tools are first requested.

require_relative "client_support"

module SharedTools
  module MCP
    class GitHub < ::RubyLLM::MCP
      extend ClientSupport

      description "GitHub repositories, issues, pull requests, code search, commits, branches, and releases"

      self.default_name = "github"

      requires_envars   "GITHUB_PERSONAL_ACCESS_TOKEN"
      requires_packages "github-mcp-server"

      command "github-mcp-server", "stdio"
      env "GITHUB_PERSONAL_ACCESS_TOKEN" => env_from("GITHUB_PERSONAL_ACCESS_TOKEN")
    end
  end
end
