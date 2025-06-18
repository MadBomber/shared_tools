#!/usr/bin/env ruby
# examples/ruby_llm.rb

require 'ruby_llm'
require 'shared_tools/ruby_llm/run_shell_command'

RubyLLM.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY']
end

chat            = RubyLLM.chat(model: 'gpt-4o')
rsc_tool  = SharedTools::RunShellCommand.new

chat.with_tool(rsc_tool)


response  = chat.ask "Run a shell command to find the largest file in the current directory"

print "\nThe answer is:  "
puts response.content
puts
