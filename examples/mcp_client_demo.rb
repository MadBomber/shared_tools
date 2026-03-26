#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: MCP Client Integration
#
# Demonstrates MCP clients that require NO pre-installed binaries:
#
#   Remote HTTP (API key only — no Node.js, no local binary):
#     Tavily web search
#
#   npx auto-download (Node.js required — package downloads on first use):
#     Memory, Sequential Thinking, Chart (no API key)
#     Brave Search (BRAVE_API_KEY)
#
# Prerequisites:
#   Node.js / npx  — for all npx-based clients (https://nodejs.org)
#
#   export TAVILY_API_KEY=your_key      # Tavily web search (https://tavily.com)
#   export BRAVE_API_KEY=your_key       # Brave web search  (https://brave.com/search/api/)
#
# Run:
#   bundle exec ruby -I examples examples/mcp_client_demo.rb

require_relative 'common'

def npx_available?
  system("which npx > /dev/null 2>&1")
end

# Open every https:// URL found in a response string using the OS default browser.
# macOS uses `open`, Linux uses `xdg-open`.
def extract_urls(text)
  text.scan(/https?:\/\/\S+/)
      .map { |u| u.gsub(/[.,;:)\]"']+$/, '') }
      .uniq
end

# Open chart URLs — checks the LLM response text first, then falls back to
# scanning tool result messages on @chat directly. The LLM often summarises
# charts in plain English without repeating the URL, so the fallback is needed.
def open_chart_urls(response)
  urls = extract_urls(response.content.to_s)

  if urls.empty? && @chat.respond_to?(:messages)
    tool_text = @chat.messages
                     .select { |m| m.role.to_s == 'tool' }
                     .map    { |m| m.content.to_s }
                     .join("\n")
    urls = extract_urls(tool_text)
  end

  if urls.empty?
    puts "  (no chart URLs found)"
    return
  end

  urls.each do |url|
    puts "  Opening: #{url}"
    system('open', url)
  end
end

def load_client(require_path, client_name, &check)
  return false unless check.nil? || check.call
  require require_path
  client = RubyLLM::MCP.clients[client_name]
  return false if client.nil?
  puts "  Loaded '#{client_name}' — #{client.tools.count} tools: #{client.tools.map(&:name).join(', ')}"
  true
rescue => e
  puts "  Error loading '#{client_name}': #{e.message}"
  false
end

title "MCP Client Demo — Zero-install MCP Servers"

puts <<~INFO
  Two types of MCP client are shown:
    Remote HTTP  — connects to a hosted endpoint; only an API key required
    npx          — package auto-downloads on first use; requires Node.js

INFO

# ---------------------------------------------------------------------------
title "Remote HTTP Clients (API key only)", char: '-'
# ---------------------------------------------------------------------------

puts "Tavily web search:"
tavily_loaded = load_client('shared_tools/mcp/tavily_client', 'tavily') { ENV['TAVILY_API_KEY'] && !ENV['TAVILY_API_KEY'].empty? }
puts "  Skipped — set TAVILY_API_KEY to enable" unless tavily_loaded

# ---------------------------------------------------------------------------
title "npx Auto-download Clients (no API key)", char: '-'
# ---------------------------------------------------------------------------

unless npx_available?
  puts "Node.js / npx not found in PATH — skipping all npx-based clients."
  puts "Install Node.js from https://nodejs.org to enable these clients."
else
  puts "Memory (persistent knowledge graph):"
  memory_loaded = load_client('shared_tools/mcp/memory_client', 'memory')

  puts "\nSequential Thinking (chain-of-thought reasoning):"
  thinking_loaded = load_client('shared_tools/mcp/sequential_thinking_client', 'sequential-thinking')

  puts "\nChart generation (AntV):"
  chart_loaded = load_client('shared_tools/mcp/chart_client', 'chart')

  puts "\nBrave Search (web + news):"
  brave_loaded = load_client('shared_tools/mcp/brave_search_client', 'brave-search') { ENV['BRAVE_API_KEY'] && !ENV['BRAVE_API_KEY'].empty? }
  puts "  Skipped — set BRAVE_API_KEY to enable" unless brave_loaded
end

# ---------------------------------------------------------------------------
title "LLM Chat with Loaded MCP Tools", char: '-'
# ---------------------------------------------------------------------------

all_tools = %w[tavily memory sequential-thinking chart brave-search].filter_map do |name|
  RubyLLM::MCP.clients[name]&.tools
rescue
  nil
end.flatten

if all_tools.empty?
  puts "No MCP clients loaded. Set API keys and/or install Node.js, then re-run."
else
  puts "Building chat with #{all_tools.size} MCP tools across #{all_tools.map(&:class).uniq.size} clients...\n\n"
  @chat = new_chat.with_tools(*all_tools)

  ask "What MCP tools do you have available? List each one with a one-line description of what it does."

  # Run a demo task for whichever clients loaded
  if tavily_loaded || brave_loaded
    title "Web Search", char: '-'
    @chat = new_chat.with_tools(*all_tools)
    ask "Search for the most recent Ruby language release and summarise what's new."
  end

  if memory_loaded
    title "Memory — Store and Recall", char: '-'
    @chat = new_chat.with_tools(*all_tools)
    ask "Remember that this project is called 'shared_tools', it is a Ruby gem providing LLM-callable tools, and today's demo ran successfully. Then confirm what you stored."
    ask "What do you remember about this project?"
  end

  if thinking_loaded
    title "Sequential Thinking", char: '-'
    @chat = new_chat.with_tools(*all_tools)
    ask <<~PROMPT
      Use sequential thinking to work through this problem step by step:
      A Ruby gem needs to support both macOS and Linux. It uses system commands
      for notifications. What are the key concerns to address and in what order
      should they be tackled?
    PROMPT
  end

  if chart_loaded
    title "Chart Generation", char: '-'
    @chat = new_chat.with_tools(*all_tools)

    response = ask <<~PROMPT
      Generate a bar chart showing these monthly active users:
      Jan: 1200, Feb: 1450, Mar: 1800, Apr: 2100, May: 1950, Jun: 2400
      Title it "Monthly Active Users — H1 2026".
    PROMPT
    open_chart_urls(response)

    response = ask <<~PROMPT
      Generate a line chart showing the same data as a trend over time.
      Title it "MAU Trend — H1 2026".
    PROMPT
    open_chart_urls(response)
  end
end

title "Done", char: '-'
puts "Remote HTTP and npx-based MCP clients demonstrated — no brew installs required."
