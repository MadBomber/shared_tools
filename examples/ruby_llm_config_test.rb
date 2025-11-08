#!/usr/bin/env ruby

require 'amazing_print'

require_relative 'ruby_llm_config'
chat = ollama_chat

puts "saying hello to ollama ..."
response = chat.ask("hello")

# Pretty print the response object
puts response.pretty_inspect

# Or if you just want the content:
puts "\nResponse content:"
puts response.content
puts
