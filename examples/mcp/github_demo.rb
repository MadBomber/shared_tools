#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: GitHub MCP Client
#
# Full GitHub API access — repositories, issues, pull requests, code search,
# commits, branches, and releases.
# Requires Homebrew (installed automatically if missing).
#
# Prerequisites:
#   Homebrew                                — https://brew.sh
#   export GITHUB_PERSONAL_ACCESS_TOKEN=your_token
#
# Run:
#   bundle exec ruby -I lib -I examples examples/mcp/github_demo.rb

require_relative 'common'

title "GitHub MCP Client Demo"

begin
  require 'shared_tools/mcp/github_client'
rescue LoadError => e
  puts "unable to load the client: #{e.message}"
  exit
end

client = RubyLLM::MCP.clients['github']
@chat  = new_chat.with_tools(*client.tools)

title "Repository Info", char: '-'
ask "What are the most recently updated public repositories for the 'ruby' GitHub organisation? List the top 5 with their descriptions."

title "Issue Search", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask "Search for open issues labelled 'bug' in the rails/rails repository. Summarise the top 3."

title "Pull Request Activity", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask "What pull requests were merged into rails/rails in the last 7 days? Summarise what changed."

title "Code Search", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask "Search GitHub for Ruby gems that implement MCP clients. List the top results with their descriptions and star counts."

title "Done", char: '-'
puts "GitHub brew-installed MCP client demonstrated."
