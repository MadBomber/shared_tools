#!/usr/bin/env ruby
# examples/llm.rb

require "shared_tools/llm/run_shell_command"

llm   = LLM.openai(key: ENV["OPENAI_API_KEY"])
bot   = LLM::Bot.new(llm, tools: [SharedTools::RunShellCommand])

bot.chat "Your task is to run shell commands via a tool.", role: :system

bot.chat "What is the current date?", role: :user
bot.chat bot.functions.map(&:call) # report return value to the LLM

bot.chat "What operating system am I running? (short version please!)", role: :user
bot.chat bot.functions.map(&:call) # report return value to the LLM
