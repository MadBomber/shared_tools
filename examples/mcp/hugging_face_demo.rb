#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: Hugging Face MCP Client
#
# Browse the Hugging Face Hub — search models and datasets, read model cards,
# explore trending repositories, and discover AI tools.
# Requires Homebrew (installed automatically if missing).
#
# Prerequisites:
#   Homebrew              — https://brew.sh
#   export HF_TOKEN=hf_... — create at https://huggingface.co/settings/tokens
#
# Run:
#   bundle exec ruby -I lib -I examples examples/mcp/hugging_face_demo.rb

require_relative 'common'

title "Hugging Face MCP Client Demo"

begin
  require 'shared_tools/mcp/hugging_face_client'
rescue LoadError => e
  puts "unable to load the client: #{e.message}"
  exit
end

client = RubyLLM::MCP.clients['hugging-face']
@chat  = new_chat.with_tools(*client.tools)

title "Trending Models", char: '-'
ask "What are the most popular and trending text-generation models on Hugging Face right now? List the top 5 with their descriptions, download counts, and what makes each notable."

title "Ruby / Rails Models", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask "Search Hugging Face for models or datasets related to Ruby programming, Rails, or software engineering code generation. What's available and how capable are they?"

title "Small but Capable Models", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask "Find small language models (under 8B parameters) that are highly rated for instruction following or chat. Which would be good candidates to run locally on an Apple Silicon Mac?"

title "Dataset Discovery", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask "What are the most downloaded datasets for training language models or fine-tuning on code? List the top results with their sizes and what they contain."

title "Model Card", char: '-'
@chat = new_chat.with_tools(*client.tools)
ask "Fetch the model card for 'meta-llama/Llama-3.2-3B-Instruct' and summarise its capabilities, intended use, training data, and any important limitations or safety considerations."

title "Done", char: '-'
puts "Hugging Face brew-installed MCP client demonstrated."
