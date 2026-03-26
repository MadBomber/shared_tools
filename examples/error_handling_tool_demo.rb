#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: ErrorHandlingTool
#
# Shows comprehensive error handling patterns: input validation, network
# retries with exponential backoff, authorization checks, and operation
# tracking — through natural language prompts.
#
# Run:
#   bundle exec ruby -I examples examples/error_handling_tool_demo.rb

require_relative 'common'
require 'shared_tools/error_handling_tool'


title "ErrorHandlingTool Demo — Robust Error Handling Patterns"

@chat = @chat.with_tool(SharedTools::Tools::ErrorHandlingTool.new)

title "Example 1: Successful Data Validation", char: '-'
ask "Validate data with name: 'Product Alpha', value: 100 using the 'validate' operation."

title "Example 2: Process Data Successfully", char: '-'
ask "Process data with name: 'Customer Record', value: 250 using the 'process' operation."

title "Example 3: Validation Error Handling", char: '-'
ask "Simulate a validation error using operation 'validate' with simulate_error: 'validation'"

title "Example 4: Network Error with Retry", char: '-'
ask "Process data but simulate a network error to test retry logic. Use max_retries: 3"

title "Example 5: Authorization Error Handling", char: '-'
ask "Test authorization error handling using operation 'authorize' with simulate_error: 'authorization'"

title "Example 6: Retryable Error Pattern", char: '-'
ask "Test retryable error handling with exponential backoff. Simulate a retryable error with 5 max retries."

title "Example 7: Resource Not Found", char: '-'
ask "Simulate a resource not found error to demonstrate how the tool handles missing resources."

title "Example 8: Operation with Metadata Tracking", char: '-'
ask "Validate data with name: 'Financial Transaction', value: 5000, optional_field: 'Quarterly Report'"

title "Example 9: Conversational Error Recovery", char: '-'
ask "Validate data with name: 'Test Item' and value: 75"
ask "Now try to process that same data"
ask "What happens if we simulate a network error?"
ask "Process the data successfully without errors"

title "Done", char: '-'
puts "ErrorHandlingTool demonstrated validation, retry, and error categorisation patterns."
