# frozen_string_literal: true
#
# Common setup for all SharedTools demo applications.
#
# Provides:
#   - Load path configuration (lib/ and examples/ directories)
#   - RubyLLM configuration via configure! (defaults to Ollama + gpt-oss:latest)
#   - Shared helper methods used by every demo
#
# Usage — run from anywhere (two equivalent forms):
#   cd examples && ./calculator_tool_demo.rb
#   bundle exec ruby -I examples examples/<tool_name>_demo.rb
#
# Each demo file needs exactly two require statements:
#   require_relative 'common'
#   require 'shared_tools/<tool_name>'
#
# To override the provider/model in a demo, call configure! after the requires:
#   configure!(provider: :anthropic, model: 'claude-sonnet-4-6')
#   configure!(model: 'claude-sonnet-4-6')   # provider auto-detected from model name
#   configure!                                # Ollama + gpt-oss:latest (default)
#
# Environment variables (all optional):
#   OLLAMA_URL        Ollama server base URL  (default: http://localhost:11434/v1)
#   DEMO_MODEL        Default model name      (default: claude-haiku-4-5)
#   RUBY_LLM_DEBUG    Set to 'true' for verbose LLM logging

# ---------------------------------------------------------------------------
# Load path — makes 'require shared_tools/...' work without gem installation
# ---------------------------------------------------------------------------
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift __dir__

require 'shared_tools'
require 'ruby_llm'
require 'logger'

# Allow all tool operations without prompting — appropriate for demos only.
SharedTools.auto_execute(true)

# Active provider and model — updated by configure!
@_provider = nil
@_model    = nil

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Print a decorated section banner.
#
# @param text [String]  banner text
# @param char [String]  border fill character
def title(text, char: '=')
  border = char * (text.size + 6)
  puts
  puts border
  puts "#{char * 2} #{text} #{char * 2}"
  puts border
  puts
end

# Configure RubyLLM with the given provider and model.
# Call this at the top of a demo to override the defaults.
#
# @param provider [Symbol, nil]  :ollama, :anthropic, :openai, etc.
#                                nil lets RubyLLM infer the provider from the model name
# @param model    [String]       model name (defaults to DEMO_MODEL env var or claude-haiku-4-5)
def configure!(provider: nil, model: ENV.fetch('DEMO_MODEL', 'claude-haiku-4-5'))
  @_provider = provider
  @_model    = model

  RubyLLM.configure do |config|
    config.anthropic_api_key = ENV['ANTHROPIC_API_KEY'] if ENV['ANTHROPIC_API_KEY']
    config.openai_api_key    = ENV['OPENAI_API_KEY']    if ENV['OPENAI_API_KEY']
    config.gemini_api_key    = ENV['GEMINI_API_KEY']    if ENV['GEMINI_API_KEY']
    config.ollama_api_base   = ENV.fetch('OLLAMA_URL', 'http://localhost:11434/v1')
    config.default_model     = model
    config.request_timeout   = 300
    config.max_retries       = 3
    config.log_level         = ENV.fetch('RUBY_LLM_DEBUG', 'false') == 'true' \
                                 ? Logger::DEBUG \
                                 : Logger::WARN
  end

  @chat = new_chat
end

# Create a new RubyLLM chat instance using the active provider and model.
#
# @param model    [String, nil]  override the active model for this chat
# @param provider [Symbol, nil]  override the active provider for this chat
# @return [RubyLLM::Chat]
def new_chat(model: nil, provider: nil)
  m = model    || @_model
  p = provider || @_provider

  opts = { model: m }
  opts[:provider]            = p    unless p.nil?
  opts[:assume_model_exists] = true if     p == :ollama

  RubyLLM.chat(**opts)
end

# Build a chat instance pre-loaded with one or more tool objects.
# Sets the module-level @chat used by ask().
#
# @param tools    [Array<RubyLLM::Tool>]  tool instances to register
# @param model    [String, nil]           model override
# @param provider [Symbol, nil]           provider override
# @return [RubyLLM::Chat]
def build_chat(*tools, model: nil, provider: nil)
  @chat = new_chat(model: model, provider: provider)
  tools.flatten.each { |t| @chat = @chat.with_tool(t) }
  @chat
end

# Send a prompt to @chat, print the exchange, and return the response.
# Creates a plain chat (no tools) if build_chat has not been called yet.
#
# @param prompt   [String]       the user message
# @param model    [String, nil]  model override when @chat is not yet initialised
# @param provider [Symbol, nil]  provider override when @chat is not yet initialised
# @return [RubyLLM::Response]
def ask(prompt, model: nil, provider: nil)
  @chat ||= new_chat(model: model, provider: provider)

  puts "Prompt:"
  puts "  #{prompt.strip.gsub("\n", "\n  ")}"
  puts

  @response = @chat.ask(prompt)

  puts "Response:"
  puts "  #{@response.content.to_s.strip.gsub("\n", "\n  ")}"
  puts

  @response
end

# Convenience alias matching the naming used in the existing example files.
alias test_with_prompt ask

# ---------------------------------------------------------------------------
# Default configuration — Ollama provider with gpt-oss:latest
# Override in demo files by calling configure! after require_relative 'common'
# ---------------------------------------------------------------------------
configure!

# ---------------------------------------------------------------------------
# Startup banner
# ---------------------------------------------------------------------------
title "SharedTools Demo Runner"
puts <<~INFO
  Provider      : #{@_provider || '(auto-detect from model name)'}
  Model         : #{@_model}
  Timeout       : #{RubyLLM.config.request_timeout}s
  Auto-execute  : enabled (demo mode — never use in production)
INFO
