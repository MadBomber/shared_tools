#!/usr/bin/env ruby
# examples/llm.rb
# This library is installed via `gem install llm.rb`
# It is required as "llm"
#
###################################################################################################
# WARNING: there is another gem named 'llm' (gem install llm) which is not compatible with llm.rb #
#          make sure you have only the llm.rb gem installed and not both llm.rb and llm.          #
###################################################################################################

# Check for API key
unless ENV["OPENAI_API_KEY"]
  puts "OPENAI_API_KEY environment variable not set"
  exit 1
end

require "debug_me"
include DebugMe

require "llm"
require_relative "../lib/shared_tools/llm_rb/run_shell_command"

llm   = LLM.openai(key: ENV["OPENAI_API_KEY"])
bot   = LLM::Bot.new(llm, tools: [SharedTools::RunShellCommand])

bot.chat "Your task is to run shell commands via a tool.", role: :system

bot.chat "What is the current date?", role: :user
bot.chat bot.functions.map(&:call) # report return value to the LLM

bot.chat "What operating system am I running? (short version please!)", role: :user
response = bot.chat bot.functions.map(&:call) # report return value to the LLM

debug_me{[
  'response.messages.map(&:content)'
]}
