#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: BrowserTool
#
# Shows how an LLM automates web browser interactions through natural language
# using the BrowserTool (requires Ferrum + Chrome; no chromedriver binary needed).
#
# Run:
#   bundle exec ruby -I examples examples/browser_tool_demo.rb

require_relative 'common'
require 'shared_tools/browser_tool'
require 'ferrum'

unless defined?(Ferrum)
  puts "ERROR: Ferrum gem not loaded. Install with: gem install ferrum"
  exit 1
end

title "BrowserTool Demo — LLM-Powered Web Automation"
puts "NOTE: Requires Chrome/Chromium browser installed. No chromedriver needed — uses Ferrum (CDP)."
puts

begin
  # All tools must share one driver so navigation in VisitTool is visible to
  # InspectTool, ClickTool, etc. — each pointing at the same browser session.
  driver = SharedTools::Tools::Browser::FerrumDriver.new
rescue => e
  puts "ERROR: Could not initialise Ferrum browser: #{e.message}"
  puts "Make sure Chrome/Chromium is installed."
  exit 1
end

# Rebuild the chat with browser tools, resetting context between examples to
# prevent tool-response HTML from accumulating and overflowing the context window.
def browser_chat(driver)
  new_chat.with_tools(
    SharedTools::Tools::Browser::VisitTool.new(driver: driver),
    SharedTools::Tools::Browser::InspectTool.new(driver: driver),
    SharedTools::Tools::Browser::ClickTool.new(driver: driver),
    SharedTools::Tools::Browser::TextFieldAreaSetTool.new(driver: driver),
    SharedTools::Tools::Browser::PageScreenshotTool.new(driver: driver)
  )
end

begin
  title "Example 1: Navigate and Read Title", char: '-'
  @chat = browser_chat(driver)
  ask <<~PROMPT
    Use browser_visit to go to https://example.com.
    Then use browser_inspect with text_content "Example Domain" to read the page.
    What is the page title and main heading?
  PROMPT

  title "Example 2: Find a Specific Link", char: '-'
  @chat = browser_chat(driver)
  ask <<~PROMPT
    Use browser_visit to go to https://example.com.
    Then use browser_inspect with text_content "Learn more" to find the link on the page.
    What does the link say and what URL does it point to?
  PROMPT

  title "Example 3: Click a Link and Read the Result", char: '-'
  @chat = browser_chat(driver)
  ask <<~PROMPT
    Use browser_visit to go to https://example.com.
    Then use browser_click with selector "a" to click the only link on the page.
    Then use browser_inspect with text_content "IANA" to read the resulting page.
    What page did the click take you to?
  PROMPT

  title "Example 4: Compare Two Pages", char: '-'
  @chat = browser_chat(driver)
  ask <<~PROMPT
    Use browser_visit to go to https://example.org.
    Then use browser_inspect with text_content "Example" to read the page.
    How does the content compare to example.com?
  PROMPT

  title "Example 5: Capture Screenshot", char: '-'
  @chat = browser_chat(driver)
  ask <<~PROMPT
    Use browser_visit to go to https://example.com.
    Then use browser_page_screenshot with path "example_com.png" to save a screenshot.
    What file path was it saved to?
  PROMPT

rescue => e
  puts "Error during browser automation: #{e.message}"
end

title "Done", char: '-'
puts "BrowserTool let the LLM control a real browser through natural language."
