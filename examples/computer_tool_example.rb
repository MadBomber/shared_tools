#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using ComputerTool with LLM Integration
#
# This example demonstrates how an LLM can automate computer interactions
# like mouse movements, clicks, and keyboard input through natural language.
#
# Note: Requires platform-specific automation capabilities (macOS, Linux, Windows)

require_relative 'ruby_llm_config'

begin
  require 'shared_tools/tools/computer'
rescue LoadError => e
  title "ERROR: Missing required dependencies for ComputerTool"

  if RUBY_PLATFORM.include?('darwin')
    puts <<~ERROR_MSG

      This example requires the 'macos' gem for macOS:
        gem install macos

      Note: You may also need to grant accessibility permissions
            System Preferences > Security & Privacy > Privacy > Accessibility
      #{'=' * 80}
    ERROR_MSG
  else
    puts <<~ERROR_MSG

      ComputerTool currently only supports macOS.
      Manual driver implementation required for other platforms.
      #{'=' * 80}
    ERROR_MSG
  end

  exit 1
end

# Check if MacOS automation is available
if RUBY_PLATFORM.include?('darwin') && !defined?(MacOS)
  title "ERROR: MacOS gem not loaded"

  puts <<~ERROR_MSG

    Please install: gem install macos
    #{'=' * 80}
  ERROR_MSG

  exit 1
end

title "ComputerTool Example - LLM-Powered Desktop Automation"

puts <<~NOTE

  NOTE: This example requires accessibility permissions on macOS
        System Preferences > Security & Privacy > Privacy > Accessibility

NOTE

# Register the ComputerTool with RubyLLM
# Note: ComputerTool is a single tool that handles all computer actions
tools = [
  SharedTools::Tools::ComputerTool.new
]

# Create a chat instance using ollama_chat helper
@chat = ollama_chat()

# Add tools to the chat
tools.each { |tool| @chat = @chat.with_tool(tool) }

begin
  # Example 1: Get mouse position
  title "Example 1: Check Mouse Position", bc: '-'
  prompt = "Where is my mouse cursor currently located?"
  test_with_prompt prompt

  # Example 2: Move and click
  title "Example 2: Move Mouse and Click", bc: '-'
  prompt = "Move the mouse to coordinates (500, 300) and click there."
  test_with_prompt prompt

  # Example 3: Type text
  title "Example 3: Automated Typing", bc: '-'
  prompt = "Type 'Hello, World!' for me."
  test_with_prompt prompt

  # Example 4: Keyboard shortcuts
  title "Example 4: Keyboard Shortcuts", bc: '-'
  prompt = "Press Command+C to copy the selected text."
  test_with_prompt prompt

  # Example 5: Form filling workflow
  title "Example 5: Automated Form Filling", bc: '-'
  prompt = <<~PROMPT
    I need to fill out a form:
    1. Click at position (400, 200) to focus the first field
    2. Type "John Doe"
    3. Press Tab to move to the next field
    4. Type "john@example.com"
    5. Press Enter to submit
  PROMPT
  test_with_prompt prompt

  # Example 6: Text selection
  title "Example 6: Text Selection", bc: '-'
  prompt = "Double-click at position (300, 400) to select a word, then copy it with Cmd+C."
  test_with_prompt prompt

  # Example 7: Scrolling
  title "Example 7: Page Scrolling", bc: '-'
  prompt = "Scroll down the page by 5 clicks, then scroll back up by 2 clicks."
  test_with_prompt prompt

  # Example 8: Right-click context menu
  title "Example 8: Context Menu", bc: '-'
  prompt = "Right-click at position (600, 400) to open the context menu."
  test_with_prompt prompt

  # Example 9: Drag and drop
  title "Example 9: Drag and Drop", bc: '-'
  prompt = <<~PROMPT
    Perform a drag and drop operation:
    1. Press the mouse button down at (100, 100)
    2. Drag to position (300, 300)
    3. Release the mouse button
  PROMPT
  test_with_prompt prompt

  # Example 10: Conversational automation
  title "Example 10: Conversational Desktop Control", bc: '-'

  prompt = "Click at position (500, 500)"
  test_with_prompt prompt

  prompt = "Now type 'test message' there"
  test_with_prompt prompt

  prompt = "Press Enter to submit"
  test_with_prompt prompt

rescue => e
  puts "\nError during computer automation: #{e.message}"
  puts "Make sure you have the necessary platform permissions and dependencies."
  puts e.backtrace.first(3)
end

title "Example completed!"

puts <<~TAKEAWAYS

  Key Takeaways:
  - The LLM can control mouse and keyboard through natural language
  - Complex desktop automation workflows are simplified
  - Form filling and data entry become conversational
  - Keyboard shortcuts and text manipulation are intuitive
  - Desktop automation is accessible without scripting

  Note: Platform-specific permissions may be required for automation

TAKEAWAYS
