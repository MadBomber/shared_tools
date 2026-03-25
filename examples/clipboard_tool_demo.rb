#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: ClipboardTool
#
# Read from and write to the system clipboard (macOS/Linux/Windows).
#
# Run:
#   bundle exec ruby -I examples examples/clipboard_tool_demo.rb

require_relative 'common'
require 'shared_tools/tools/clipboard_tool'


title "ClipboardTool Demo — cross-platform clipboard read/write/clear"

@chat = @chat.with_tool(SharedTools::Tools::ClipboardTool.new)

ask "Write the text 'Hello from SharedTools!' to the clipboard."

ask "Read the current clipboard contents and tell me what is there."

ask "Now write a multi-line note to the clipboard with this exact content: 'Line 1: Ruby is great\nLine 2: SharedTools makes it easier\nLine 3: ClipboardTool bridges the gap'."

ask "Read the clipboard again and confirm all three lines are present."

ask "How many characters are currently stored in the clipboard?"

ask "Clear the clipboard, then immediately read it back and confirm it is now empty."

ask "Write today's date in ISO 8601 format (YYYY-MM-DD) to the clipboard."

title "Done", char: '-'
puts "ClipboardTool demonstrated write, read, multi-line storage, length reporting, and clear operations."
