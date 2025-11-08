#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using DocTool with LLM Integration
#
# This example demonstrates how an LLM can use the DocTool to read and
# extract information from PDF documents through natural language prompts.

require_relative 'ruby_llm_config'

begin
  require 'pdf-reader'
  require 'shared_tools/tools/doc'
rescue LoadError => e
  title "ERROR: Missing required dependencies for DocTool"

  puts <<~ERROR_MSG

    This example requires the 'pdf-reader' gem:
      gem install pdf-reader

    Or add to your Gemfile:
      gem 'pdf-reader'

    Then run: bundle install
    #{'=' * 80}
  ERROR_MSG

  exit 1
end

title "DocTool Example - LLM-Powered PDF Processing"

# Path to a sample PDF (using the test fixture)
sample_pdf = File.expand_path('../test/fixtures/test.pdf', __dir__)

unless File.exist?(sample_pdf)
  puts "ERROR: Sample PDF not found at #{sample_pdf}"
  puts "Please ensure a PDF file exists at that location to run this example."
  exit 1
end

puts "Using sample PDF: #{sample_pdf}"
puts

# Register the PdfReaderTool with RubyLLM
tools = [
  SharedTools::Tools::Doc::PdfReaderTool.new
]

# Create a chat instance using ollama_chat helper
@chat = ollama_chat()

# Add tools to the chat
tools.each { |tool| @chat = @chat.with_tool(tool) }

# Example 1: Extract content from first page
title "Example 1: Read First Page", bc: '-'
prompt = "Please read the first page of the PDF document at '#{sample_pdf}' and tell me what it's about."
test_with_prompt prompt

# Example 2: Search for specific information
title "Example 2: Search for Specific Content", bc: '-'
prompt = "Read pages 1-3 of '#{sample_pdf}' and tell me if there are any section headers or important titles."
test_with_prompt prompt

# Example 3: Count pages
title "Example 3: Document Statistics", bc: '-'
prompt = "How many total pages are in the PDF document at '#{sample_pdf}'?"
test_with_prompt prompt

# Example 4: Extract and summarize
title "Example 4: Content Summarization", bc: '-'
prompt = "Read the first 2 pages of '#{sample_pdf}' and give me a brief summary of the main topics."
test_with_prompt prompt

# Example 5: Find specific keywords
title "Example 5: Keyword Search", bc: '-'
prompt = "Search the first 3 pages of '#{sample_pdf}' for any mentions of numbers or statistics."
test_with_prompt prompt

# Example 6: Conversational context
title "Example 6: Multi-Turn Conversation", bc: '-'

prompt = "Read page 1 of '#{sample_pdf}' for me."
test_with_prompt prompt

prompt = "Based on what you just read, what are the key takeaways?"
test_with_prompt prompt

# Example 7: Compare pages
title "Example 7: Compare Content Across Pages", bc: '-'
prompt = "Read pages 1 and 2 of '#{sample_pdf}' and tell me how they differ in content or structure."
test_with_prompt prompt

title "Example completed!"

puts <<~TAKEAWAYS

  Key Takeaways:
  - The LLM can extract and understand PDF content through natural language
  - Complex document analysis tasks are simplified with conversational prompts
  - The LLM maintains context about the document across multiple queries
  - Page-specific or multi-page extraction is handled intelligently
  - Document understanding goes beyond simple text extraction

TAKEAWAYS
