#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: SystemInfoTool
#
# Retrieve OS, CPU, memory, disk, and network information from the local system.
#
# Run:
#   bundle exec ruby -I examples examples/system_info_tool_demo.rb

require_relative 'common'
require 'shared_tools/tools/system_info_tool'


title "SystemInfoTool Demo — OS, CPU, memory, disk, and network details"

@chat = @chat.with_tool(SharedTools::Tools::SystemInfoTool.new)

ask "What operating system and version is this machine running?"

ask "Tell me about the CPU: model, core count, and current load average."

ask "How much total RAM does this machine have, and how much is currently available?"

ask "What disks are mounted on this system and how much space is used vs available on each?"

ask "List the active network interfaces and their IP addresses."

ask "What version of Ruby is running, and on what platform?"

ask "Give me a full system summary covering OS, CPU, memory, and disk at once."

title "Done", char: '-'
puts "SystemInfoTool demonstrated OS, CPU, memory, disk, network, Ruby runtime, and full-summary queries."
