#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using BrowserTool with LLM Integration
#
# This example demonstrates how an LLM can automate web browser interactions
# through natural language prompts using the BrowserTool.

require_relative 'ruby_llm_config'

begin
  require 'shared_tools/tools/browser'
rescue LoadError => e
  title "ERROR: Missing required dependencies for BrowserTool"

  puts <<~ERROR_MSG

    This example requires the 'watir' and 'webdrivers' gems:
      gem install watir webdrivers

    Or add to your Gemfile:
      gem 'watir'
      gem 'webdrivers'

    Then run: bundle install
    #{'=' * 80}
  ERROR_MSG

  exit 1
end

# Check if Watir is available
unless defined?(Watir)
  puts <<~WATIR_ERROR
    #{'=' * 80}
    ERROR: Watir gem not loaded
    #{'=' * 80}

    Please install: gem install watir webdrivers
    #{'=' * 80}
  WATIR_ERROR

  exit 1
end

title("BrowserTool Example - LLM-Powered Web Automation")
puts
puts "NOTE: This example uses Watir with Chrome driver"
puts "      Make sure Chrome browser is installed"
puts

# Register the BrowserTools with RubyLLM
tools = [
  SharedTools::Tools::Browser::VisitTool.new,
  SharedTools::Tools::Browser::InspectTool.new,
  SharedTools::Tools::Browser::ClickTool.new,
  SharedTools::Tools::Browser::TextFieldAreaSetTool.new,
  SharedTools::Tools::Browser::PageScreenshotTool.new
]

# Create a chat instance using ollama_chat helper
@chat = ollama_chat()

# Add tools to the chat
tools.each { |tool| @chat = @chat.with_tool(tool) }

begin
  # Example 1: Visit a website
  title "Example 1: Navigate to Website", bc: '-'
  prompt = "Visit the example.com website using a headless Chrome browser."
  test_with_prompt prompt


  # Example 2: Inspect page content
  title "Example 2: Inspect Page Content", bc: '-'
  prompt = "What's the main heading on this page?"
  test_with_prompt prompt


  # Example 3: Search workflow
  title "Example 3: Search Workflow", bc: '-'
  prompt = <<~PROMPT
    Go to duckduckgo.com and search for "Ruby programming language".
    Tell me what the first result is.
  PROMPT
  test_with_prompt prompt


  # Example 4: Take screenshot
  title "Example 4: Capture Screenshot", bc: '-'
  prompt = "Take a screenshot of the current page and save it as 'search_results.png'."
  test_with_prompt prompt


  # Example 5: Multi-step navigation
  title "Example 5: Multi-Step Navigation", bc: '-'
  prompt = <<~PROMPT
    I need you to:
    1. Go to example.org
    2. Find and click on the "More information..." link
    3. Tell me what page you end up on
  PROMPT
  test_with_prompt prompt


  # Example 6: Form interaction
  title "Example 6: Form Interaction", bc: '-'
  prompt = <<~PROMPT
    Go to httpbin.org/forms/post and fill out the form:
    - Customer name: John Doe
    - Telephone: 555-1234
    - Comments: Testing browser automation
    Then submit the form.
  PROMPT
  test_with_prompt prompt


  # Example 7: Conversational browsing
  title "Example 7: Conversational Browsing", bc: '-'
  prompt = "Navigate to github.com"
  test_with_prompt prompt


  prompt = "Click on the 'Explore' link in the navigation."
  test_with_prompt prompt

  prompt = "What's the page title now?"
  test_with_prompt prompt

rescue => e
  puts "Error during browser automation: #{e.message}"
  puts "Make sure you have a compatible browser and webdriver installed."
end

title "Example completed!"

puts <<~TAKEAWAYS

  Key Takeaways:
  - The LLM can control web browsers through natural language
  - Complex multi-step workflows are automated intelligently
  - Page inspection and interaction happen seamlessly
  - Screenshots and data extraction are conversational
  - Browser automation becomes accessible without writing code

TAKEAWAYS
