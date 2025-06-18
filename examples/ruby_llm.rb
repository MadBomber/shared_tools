#!/usr/bin/env ruby
# examples/ruby_llm.rb

require 'ruby_llm'
require 'shared_tools/ruby_llm/read_file'

RubyLLM.configure do |config|
  config.openai_api_key = ENV['OPENAI_API_KEY']
end

chat            = RubyLLM.chat(model: 'gpt-4o')
read_file_tool  = SharedTools::ReadFile.new

chat.with_tool(read_file_tool)

here      = File.dirname(__FILE__)
file_path = File.join(here, 'wood_chuck.txt')
response  = chat.ask "Please answer the question written in the file located at: #{file_path}"

print "\nThe answer is:  "
puts response.content
puts
