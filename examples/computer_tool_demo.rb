#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: ComputerTool
#
# Shows how an LLM automates mouse movements, clicks, and keyboard input
# through natural language (macOS only — requires accessibility permissions).
#
# Run:
#   bundle exec ruby -I examples examples/computer_tool_demo.rb

require_relative 'common'
require 'shared_tools/computer_tool'


unless RUBY_PLATFORM.include?('darwin')
  puts "ERROR: ComputerTool currently only supports macOS."
  exit 1
end

title "ComputerTool Demo — LLM-Powered Desktop Automation"
puts "NOTE: Requires accessibility permissions."
puts "      System Preferences > Security & Privacy > Privacy > Accessibility"
puts

@chat = @chat.with_tool(SharedTools::Tools::ComputerTool.new)

begin
  title "Example 1: Check Mouse Position", char: '-'
  ask "Where is my mouse cursor currently located?"

  title "Example 2: Move Mouse and Click", char: '-'
  ask "Move the mouse to coordinates (500, 300) and click there."

  title "Example 3: Automated Typing", char: '-'
  ask "Type 'Hello, World!' for me."

  title "Example 4: Keyboard Shortcuts", char: '-'
  ask "Press Command+C to copy the selected text."

  title "Example 5: Automated Form Filling", char: '-'
  ask <<~PROMPT
    Fill out a form:
    1. Click at position (400, 200) to focus the first field
    2. Type "John Doe"
    3. Press Tab to move to the next field
    4. Type "john@example.com"
    5. Press Enter to submit
  PROMPT

  title "Example 6: Text Selection", char: '-'
  ask "Double-click at position (300, 400) to select a word, then copy it with Cmd+C."

  title "Example 7: Page Scrolling", char: '-'
  ask "Scroll down the page by 5 clicks, then scroll back up by 2 clicks."

  title "Example 8: Drag and Drop", char: '-'
  ask <<~PROMPT
    Perform a drag and drop:
    1. Press the mouse button down at (100, 100)
    2. Drag to position (300, 300)
    3. Release the mouse button
  PROMPT

  title "Example 9: Conversational Desktop Control", char: '-'
  ask "Click at position (500, 500)"
  ask "Now type 'test message' there"
  ask "Press Enter to submit"

rescue => e
  puts "\nError during computer automation: #{e.message}"
end

title "Done", char: '-'
puts "ComputerTool let the LLM control mouse and keyboard through natural language."
