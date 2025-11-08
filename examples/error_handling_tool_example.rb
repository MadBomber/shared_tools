#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using ErrorHandlingTool with LLM Integration
#
# This example demonstrates comprehensive error handling patterns and
# resilience strategies through natural language prompts.

require_relative 'ruby_llm_config'
require 'shared_tools/tools/error_handling_tool'

title "ErrorHandlingTool Example - Robust Error Handling Patterns"

# Register the ErrorHandlingTool with RubyLLM
tools = [
  SharedTools::Tools::ErrorHandlingTool.new
]

# Create a chat instance using ollama_chat helper
@chat = ollama_chat()

# Add tools to the chat
tools.each { |tool| @chat = @chat.with_tool(tool) }

# Example 1: Successful validation
title "Example 1: Successful Data Validation", bc: '-'
prompt = <<~PROMPT
  Validate this data using the error handling tool:
  - name: "Product Alpha"
  - value: 100
  Use the 'validate' operation.
PROMPT
test_with_prompt prompt


# Example 2: Successful processing
title "Example 2: Process Data Successfully", bc: '-'
prompt = <<~PROMPT
  Process this data:
  - name: "Customer Record"
  - value: 250
  Use the 'process' operation.
PROMPT
test_with_prompt prompt


# Example 3: Simulate validation error
title "Example 3: Validation Error Handling", bc: '-'
prompt = <<~PROMPT
  Test error handling by simulating a validation error.
  Use operation 'validate' and simulate_error: 'validation'
PROMPT
test_with_prompt prompt


# Example 4: Simulate network error
title "Example 4: Network Error with Retry", bc: '-'
prompt = <<~PROMPT
  Process data but simulate a network error to test retry logic.
  Use operation 'process', simulate_error: 'network', with max_retries: 3
PROMPT
test_with_prompt prompt


# Example 5: Simulate authorization error
title "Example 5: Authorization Error Handling", bc: '-'
prompt = <<~PROMPT
  Test authorization error handling.
  Use operation 'authorize' with simulate_error: 'authorization'
PROMPT
test_with_prompt prompt


# Example 6: Simulate retryable error
title "Example 6: Retryable Error Pattern", bc: '-'
prompt = <<~PROMPT
  Test retryable error handling with exponential backoff.
  Simulate a retryable error with 5 max retries.
PROMPT
test_with_prompt prompt


# Example 7: Resource not found error
title "Example 7: Resource Not Found", bc: '-'
prompt = <<~PROMPT
  Simulate a resource not found error scenario.
  This demonstrates how the tool handles missing resources.
PROMPT
test_with_prompt prompt


# Example 8: Normal operation with metadata
title "Example 8: Operation with Metadata Tracking", bc: '-'
prompt = <<~PROMPT
  Perform a normal validation with detailed data:
  - name: "Financial Transaction"
  - value: 5000
  - optional_field: "Quarterly Report"
PROMPT
test_with_prompt prompt


# Example 9: Zero retries configuration
title "Example 9: Disable Retry Mechanism", bc: '-'
prompt = <<~PROMPT
  Process data with retries disabled (max_retries: 0).
  This shows immediate failure without retry attempts.
PROMPT
test_with_prompt prompt


# Example 10: Conversational error handling
title "Example 10: Conversational Error Recovery", bc: '-'

prompt = "Validate data with name: 'Test Item' and value: 75"
test_with_prompt prompt

prompt = "Now try to process that same data"
test_with_prompt prompt

prompt = "What happens if we simulate a network error?"
test_with_prompt prompt

prompt = "Process the data successfully without errors"
test_with_prompt prompt

title "Example completed!"

puts <<~TAKEAWAYS

  Key Takeaways:
  - Demonstrates comprehensive error handling patterns
  - Shows input validation with helpful error suggestions
  - Implements retry mechanism with exponential backoff
  - Provides detailed error categorization and messages
  - Includes proper resource cleanup in ensure blocks
  - Tracks operation metadata for debugging
  - Generates unique reference IDs for error tracking
  - The LLM understands different error types and responses
  - Perfect reference for building robust tools

  Error Handling Patterns Demonstrated:
  - Input validation with suggestions
  - Network retry with backoff
  - Authorization checks
  - Resource cleanup
  - Detailed error messages
  - Operation tracking
  - Configurable retry limits
  - Different error type categorization

  This tool serves as a reference implementation for
  building robust, production-ready AI tools.

TAKEAWAYS
