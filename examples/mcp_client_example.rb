#!/usr/bin/env ruby
# examples/mcp_client_example.rb
#
# Demonstrates how to use MCP (Model Context Protocol) clients with RubyLLM
# Compatible with ruby_llm-mcp v0.7.0+
#
# Prerequisites:
#   1. Install required gems:
#      bundle install
#
#   2. For Tavily (web search):
#      export TAVILY_API_KEY=your_api_key_here
#
#   3. For GitHub operations:
#      export GITHUB_PERSONAL_ACCESS_TOKEN=your_token_here
#      brew install github-mcp-server
#
#   4. For iMCP (macOS only):
#      brew install --cask loopwork/tap/iMCP

require 'bundler/setup'
require 'ruby_llm'

puts <<~BANNER
  ═══════════════════════════════════════════════════════════════
  MCP Client Example - ruby_llm-mcp v0.7.0+
  ═══════════════════════════════════════════════════════════════
BANNER

# Example 1: Using Tavily for Web Search
puts "\n📚 Example 1: Using Tavily MCP Client for Web Search"
puts "─" * 70

if ENV['TAVILY_API_KEY']
  begin
    # Load the Tavily MCP client
    require 'shared_tools/mcp/tavily_mcp_server'

    # Get the client (clients are automatically registered when you require the file)
    tavily_client = RubyLLM::MCP.clients["tavily"]

    puts "✓ Tavily client loaded successfully"
    puts "  Available tools: #{tavily_client.tools.count}"
    puts "  Client name: #{tavily_client.name}"

    # Example: Use with RubyLLM chat
    chat = RubyLLM.chat(
      model: "claude-sonnet-4",
      provider: :anthropic
    )

    # Add MCP tools to the chat
    chat.with_tools(*tavily_client.tools)

    puts "\n  Example query: 'What are the latest news about Ruby programming language?'"
    puts "  (Skipping actual API call to save time)"

    # Uncomment to make actual call:
    # response = chat.ask("What are the latest news about Ruby programming language?")
    # puts "\n  Response: #{response}"

  rescue => e
    puts "✗ Error loading Tavily client: #{e.message}"
  end
else
  puts "⚠️  Skipping Tavily example (TAVILY_API_KEY not set)"
  puts "  Set it with: export TAVILY_API_KEY=your_api_key"
end

# Example 2: Using GitHub MCP Server
puts "\n\n🐙 Example 2: Using GitHub MCP Server"
puts "─" * 70

if ENV['GITHUB_PERSONAL_ACCESS_TOKEN'] && File.exist?("/opt/homebrew/bin/github-mcp-server")
  begin
    require 'shared_tools/mcp/github_mcp_server'

    github_client = RubyLLM::MCP.clients["github-mcp-server"]

    puts "✓ GitHub MCP client loaded successfully"
    puts "  Available tools: #{github_client.tools.count}"
    puts "  Client name: #{github_client.name}"

    # List some available tools
    puts "\n  Sample tools available:"
    github_client.tools.take(5).each do |tool|
      puts "    • #{tool.name}"
    end

  rescue => e
    puts "✗ Error loading GitHub client: #{e.message}"
  end
elsif !ENV['GITHUB_PERSONAL_ACCESS_TOKEN']
  puts "⚠️  Skipping GitHub example (GITHUB_PERSONAL_ACCESS_TOKEN not set)"
  puts "  Set it with: export GITHUB_PERSONAL_ACCESS_TOKEN=your_token"
else
  puts "⚠️  Skipping GitHub example (github-mcp-server not installed)"
  puts "  Install it with: brew install github-mcp-server"
end

# Example 3: Using iMCP (macOS only)
puts "\n\n🍎 Example 3: Using iMCP for macOS Integration"
puts "─" * 70

if RUBY_PLATFORM.include?('darwin') && File.exist?("/Applications/iMCP.app")
  begin
    require 'shared_tools/mcp/imcp'

    imcp_client = RubyLLM::MCP.clients["imcp-server"]

    puts "✓ iMCP client loaded successfully"
    puts "  Available tools: #{imcp_client.tools.count}"
    puts "  Client name: #{imcp_client.name}"

    puts "\n  This client provides access to:"
    puts "    • macOS Notes"
    puts "    • Calendar events"
    puts "    • Contacts"
    puts "    • Reminders"

  rescue => e
    puts "✗ Error loading iMCP client: #{e.message}"
  end
elsif !RUBY_PLATFORM.include?('darwin')
  puts "⚠️  Skipping iMCP example (not running on macOS)"
else
  puts "⚠️  Skipping iMCP example (iMCP.app not installed)"
  puts "  Install it with: brew install --cask loopwork/tap/iMCP"
end

# Example 4: Working with Multiple MCP Clients
puts "\n\n🔗 Example 4: Working with Multiple MCP Clients"
puts "─" * 70

puts "You can use multiple MCP clients together in a single conversation:"
puts <<~EXAMPLE

  # Load all clients
  require 'shared_tools/mcp/tavily_mcp_server'
  require 'shared_tools/mcp/github_mcp_server'
  require 'shared_tools/mcp/imcp'

  # Create a chat with all MCP tools
  chat = RubyLLM.chat(model: "claude-sonnet-4", provider: :anthropic)

  # Add tools from all clients
  chat.with_tools(
    *RubyLLM::MCP.clients["tavily"].tools,
    *RubyLLM::MCP.clients["github-mcp-server"].tools,
    *RubyLLM::MCP.clients["imcp-server"].tools
  )

  # Now the AI can use tools from all three services!
  response = chat.ask("Search for Ruby news and add a reminder about it")
EXAMPLE

# Example 5: Accessing MCP Resources and Prompts
puts "\n\n📦 Example 5: MCP Resources and Prompts"
puts "─" * 70

puts "MCP clients can provide resources and prompts in addition to tools:"
puts <<~EXAMPLE

  client = RubyLLM::MCP.clients["tavily"]

  # Check available resources
  if client.resources.any?
    puts "Available resources:"
    client.resources.each { |r| puts "  • \#{r.name}" }
  end

  # Check available prompts
  if client.prompts.any?
    puts "Available prompts:"
    client.prompts.each { |p| puts "  • \#{p.name}" }
  end

  # Use a resource
  resource = client.resource("resource-name")

  # Use a prompt
  prompt = client.prompt("prompt-name", arg1: "value1")
EXAMPLE

puts "\n\n" + "═" * 70
puts "Example completed! Check the code for more details."
puts "Documentation: https://www.rubyllm-mcp.com"
puts "═" * 70
