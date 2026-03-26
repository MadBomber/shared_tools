#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: CronTool
#
# Parse, validate, explain, and generate cron expressions.
#
# Run:
#   bundle exec ruby -I examples examples/cron_tool_demo.rb

ENV['RUBY_LLM_DEBUG'] = 'true'

require_relative 'common'
require 'shared_tools/tools/cron_tool'


title "CronTool Demo — parse, validate, explain, and generate cron expressions"

@chat = @chat.with_tool(SharedTools::Tools::CronTool.new)

ask "Parse and explain the cron expression '0 9 * * 1-5'."

ask "Is the expression '*/15 6-22 * * *' valid? If so, what does it mean?"

ask "What are the next 5 execution times for the cron expression '0 * * * *'?"

ask "Generate a cron expression for 'every day at 9am'."

ask "Generate a cron expression for 'every monday at noon'."

ask "Parse the expression '30 8,12,18 * * 1-5' and describe when it runs."

ask "Show me the next 3 execution times for '0 0 1 * *' and explain what schedule that represents."

title "Done", char: '-'
puts "CronTool demonstrated parsing, validation, next-execution calculation, and expression generation."
