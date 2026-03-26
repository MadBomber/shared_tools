#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: NotificationTool
#
# Cross-platform desktop notifications, modal alert dialogs, and text-to-speech.
# Supports macOS (osascript, say) and Linux (notify-send, zenity/terminal, espeak-ng/espeak).
#
# NOTE: This demo triggers real OS-level interactions:
#   - notify  → desktop banner notifications appear on screen
#   - alert   → a modal dialog pops up and BLOCKS until you click a button
#   - speak   → your system will speak text aloud
#
# Run:
#   bundle exec ruby -I examples examples/notification_tool_demo.rb

require_relative 'common'
require 'shared_tools/tools/notification'

title "NotificationTool Demo — Desktop notifications, modal alerts, and text-to-speech"

@chat = new_chat.with_tool(SharedTools::Tools::NotificationTool.new)

# ---------------------------------------------------------------------------
title "Notify — Non-blocking desktop banner", char: '-'
# ---------------------------------------------------------------------------

ask "Send a desktop notification with the title 'SharedTools Demo' and the message 'NotificationTool is working!'"

ask "Send a desktop notification with title 'Build Status', subtitle 'CI Pipeline', and message 'All tests passed — 600 runs, 0 failures.'"

ask "Send a notification with the title 'Reminder' and message 'Time to take a break.' Use the 'Glass' sound."

# ---------------------------------------------------------------------------
title "Speak — Text-to-speech", char: '-'
# ---------------------------------------------------------------------------

@chat = new_chat.with_tool(SharedTools::Tools::NotificationTool.new)

ask "Please speak the following message aloud: 'Hello! The SharedTools notification tool is working correctly on this system.'"

ask "Speak this message at a rate of 150 words per minute: 'Shared tools makes it easy for AI agents to interact with your operating system.'"

# ---------------------------------------------------------------------------
title "Alert — Modal dialog (will block for your input)", char: '-'
# ---------------------------------------------------------------------------

@chat = new_chat.with_tool(SharedTools::Tools::NotificationTool.new)

ask "Show an alert dialog with the title 'Demo Checkpoint' and the message 'The notification demo is running. Click OK to continue.' Use a single OK button."

ask <<~PROMPT
  Show an alert dialog asking: 'Do you want to hear another spoken message?'
  Give it the title 'Continue?' and provide two buttons: 'Yes' and 'No'.
  Report back which button was clicked.
PROMPT

# ---------------------------------------------------------------------------
title "Combined workflow", char: '-'
# ---------------------------------------------------------------------------

@chat = new_chat.with_tool(SharedTools::Tools::NotificationTool.new)

ask <<~PROMPT
  Run this three-step notification sequence:
  1. Send a desktop notification with title 'Workflow Starting' and message 'Step 1 of 3 complete.'
  2. Speak the message: 'Workflow demo is running. Please stand by.'
  3. Show an alert dialog titled 'Workflow Complete' with the message 'All three notification types demonstrated successfully.' and an OK button.
  Tell me the result of each step.
PROMPT

title "Done", char: '-'
puts "NotificationTool demonstrated desktop banners, text-to-speech, and modal alert dialogs."
