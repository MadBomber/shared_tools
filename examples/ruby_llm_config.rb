# frozen_string_literal: true

# Configuration file for RubyLLM with local Ollama server
#
# This file sets up RubyLLM to work with a local Ollama server
# running an open-source GPT model (gpt-oss or equivalent).
#
# Ollama Installation:
#   - Download from: https://ollama.com
#   - Install models: ollama pull gpt-oss:20b
#
# Usage in examples:
#   require_relative 'ruby_llm_config'

# Add the parent lib directory to the load path
# This allows examples to use 'require shared_tools' as if the gem were installed
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'shared_tools'
require 'ruby_llm'
require 'logger'

# Configure RubyLLM to use local Ollama server
RubyLLM.configure do |config|
  # Ollama server configuration - must include /v1 for OpenAI-compatible API
  config.ollama_api_base = ENV.fetch('OLLAMA_URL', 'http://localhost:11434/v1')

  # Set default model (can be overridden per chat)
  config.default_model = ENV.fetch('OLLAMA_MODEL', 'gpt-oss:20b')

  # Connection configuration
  config.request_timeout = 300
  config.max_retries = 3

  # Enable debug logging (optional)
  config.log_level = ENV.fetch('RUBY_LLM_DEBUG', 'false') == 'true' ? Logger::DEBUG : Logger::INFO
end

# Helper to create an Ollama chat
def ollama_chat(model: nil)
  model_to_use = model || RubyLLM.config.default_model
  RubyLLM.chat(model: model_to_use, provider: :ollama, assume_model_exists: true)
end

def title(a_string, bc: '=')
  b  = bc * (a_string.size + 6)
  b2 = bc + bc

  puts
  puts b
  puts b2 + " #{a_string} " + b2
  puts b
  puts
end

def test_with_prompt(a_prompt, model: nil)
  puts "\nPrompt:"
  puts a_prompt
  puts

  @chat   ||= ollama_chat(model:)
  @response = @chat.ask(a_prompt)

  puts "\nLLM Response:"
  puts @response.pretty_inspect

  puts "\nContent:"
  puts @response.content
  puts
  @response
end

title('RubyLLM Configuration Loaded')

puts <<~USAGE
  Ollama Base URL: #{RubyLLM.config.ollama_api_base}
  Default Model: #{RubyLLM.config.default_model}
  Request Timeout: #{RubyLLM.config.request_timeout}s
  Log Level: #{RubyLLM.config.log_level}
  Auto-execute: enabled (for demo purposes only)
  #{'=' * 80}

  Usage: chat = ollama_chat(model: 'model-name') # or use default model
         chat.with_tool(Tool).ask('Your question')

USAGE
