#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: BrowserTool
#
# Shows how an LLM automates web browser interactions through natural language
# using the BrowserTool (requires Watir + Chrome).
#
# Run:
#   bundle exec ruby -I examples examples/browser_tool_demo.rb

require_relative 'common'
require 'shared_tools/browser_tool'


unless defined?(Watir)
  puts "ERROR: Watir gem not loaded. Install with: gem install watir webdrivers"
  exit 1
end

title "BrowserTool Demo — LLM-Powered Web Automation"
puts "NOTE: Requires Watir with Chrome driver and Chrome browser installed."
puts

@chat = @chat.with_tools(
  SharedTools::Tools::Browser::VisitTool.new,
  SharedTools::Tools::Browser::InspectTool.new,
  SharedTools::Tools::Browser::ClickTool.new,
  SharedTools::Tools::Browser::TextFieldAreaSetTool.new,
  SharedTools::Tools::Browser::PageScreenshotTool.new
)

begin
  title "Example 1: Navigate to Website", char: '-'
  ask "Visit the example.com website using a headless Chrome browser."

  title "Example 2: Inspect Page Content", char: '-'
  ask "What's the main heading on this page?"

  title "Example 3: Search Workflow", char: '-'
  ask <<~PROMPT
    Go to duckduckgo.com and search for "Ruby programming language".
    Tell me what the first result is.
  PROMPT

  title "Example 4: Capture Screenshot", char: '-'
  ask "Take a screenshot of the current page and save it as 'search_results.png'."

  title "Example 5: Multi-Step Navigation", char: '-'
  ask <<~PROMPT
    1. Go to example.org
    2. Find and click on the "More information..." link
    3. Tell me what page you end up on
  PROMPT

  title "Example 6: Form Interaction", char: '-'
  ask <<~PROMPT
    Go to httpbin.org/forms/post and fill out the form:
    - Customer name: John Doe
    - Telephone: 555-1234
    - Comments: Testing browser automation
    Then submit the form.
  PROMPT

  title "Example 7: Conversational Browsing", char: '-'
  ask "Navigate to github.com"
  ask "Click on the 'Explore' link in the navigation."
  ask "What's the page title now?"

rescue => e
  puts "Error during browser automation: #{e.message}"
end

title "Done", char: '-'
puts "BrowserTool let the LLM control a real browser through natural language."
