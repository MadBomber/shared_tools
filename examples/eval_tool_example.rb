#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using EvalTool for code evaluation
#
# This example demonstrates how to use the EvalTool facade to evaluate
# Ruby, Python, and shell commands safely with user authorization.

require 'bundler/setup'
require 'shared_tools'

puts "=" * 80
puts "EvalTool Example - Code Evaluation"
puts "=" * 80
puts

# Enable auto-execution for this demo (bypass authorization prompts)
# In production, you would typically leave this false for security
SharedTools.auto_execute(true)

# Initialize the eval tool
eval_tool = SharedTools::Tools::EvalTool.new

puts "Note: Auto-execution is enabled for this demo."
puts "In production, each execution would require user confirmation."
puts

begin
  # Example 1: Evaluate Ruby code
  puts "1. Evaluating Ruby Code"
  puts "-" * 40

  result = eval_tool.execute(
    action: SharedTools::Tools::EvalTool::Action::RUBY,
    code: "2 + 2"
  )

  puts "Code: 2 + 2"
  puts "Result: #{result[:result]}"
  puts "Success: #{result[:success]}"
  puts

  # Example 2: Ruby code with output
  puts "2. Ruby Code with Console Output"
  puts "-" * 40

  result = eval_tool.execute(
    action: SharedTools::Tools::EvalTool::Action::RUBY,
    code: "puts 'Hello from Ruby!'; 42"
  )

  puts "Code: puts 'Hello from Ruby!'; 42"
  puts "Display:\n#{result[:display]}"
  puts

  # Example 3: Ruby code with variables
  puts "3. Ruby Code with Variables"
  puts "-" * 40

  code = <<~RUBY
    x = 10
    y = 20
    x * y
  RUBY

  result = eval_tool.execute(
    action: SharedTools::Tools::EvalTool::Action::RUBY,
    code: code
  )

  puts "Code:"
  puts code
  puts "Result: #{result[:result]}"
  puts

  # Example 4: Python code evaluation (if python3 is available)
  puts "4. Evaluating Python Code"
  puts "-" * 40

  if system("which python3 > /dev/null 2>&1")
    result = eval_tool.execute(
      action: SharedTools::Tools::EvalTool::Action::PYTHON,
      code: "2 ** 10"
    )

    puts "Code: 2 ** 10 (Python power operator)"
    puts "Result: #{result[:result]}"
    puts "Python Type: #{result[:python_type]}"
    puts
  else
    puts "Python3 not available, skipping Python examples"
    puts
  end

  # Example 5: Python with imports and libraries
  if system("which python3 > /dev/null 2>&1")
    puts "5. Python with Standard Library"
    puts "-" * 40

    python_code = <<~PYTHON
      import math
      math.sqrt(16) + math.pi
    PYTHON

    result = eval_tool.execute(
      action: SharedTools::Tools::EvalTool::Action::PYTHON,
      code: python_code
    )

    puts "Code:"
    puts python_code
    puts "Result: #{result[:result]}"
    puts
  end

  # Example 6: Shell command execution
  puts "6. Executing Shell Commands"
  puts "-" * 40

  result = eval_tool.execute(
    action: SharedTools::Tools::EvalTool::Action::SHELL,
    command: "echo 'Hello from Shell!'"
  )

  puts "Command: echo 'Hello from Shell!'"
  puts "Output: #{result[:stdout].strip}"
  puts "Exit Status: #{result[:exit_status]}"
  puts

  # Example 7: Shell command with pipes
  puts "7. Shell Command with Pipes"
  puts "-" * 40

  result = eval_tool.execute(
    action: SharedTools::Tools::EvalTool::Action::SHELL,
    command: "echo 'apple\nbanana\ncherry' | grep 'ban'"
  )

  puts "Command: echo 'apple\\nbanana\\ncherry' | grep 'ban'"
  puts "Output: #{result[:stdout].strip}"
  puts

  # Example 8: Handling errors in Ruby
  puts "8. Handling Ruby Errors"
  puts "-" * 40

  result = eval_tool.execute(
    action: SharedTools::Tools::EvalTool::Action::RUBY,
    code: "1 / 0"
  )

  puts "Code: 1 / 0"
  puts "Success: #{result[:success]}"
  puts "Error: #{result[:error]}" if result[:error]
  puts

  # Example 9: Using individual tool directly
  puts "9. Using Individual Tool Directly"
  puts "-" * 40
  puts "You can also use individual eval tools directly:"
  puts

  ruby_tool = SharedTools::Tools::Eval::RubyEvalTool.new
  result = ruby_tool.execute(code: "'Direct tool call'.upcase")

  puts "Tool: RubyEvalTool"
  puts "Code: 'Direct tool call'.upcase"
  puts "Result: #{result[:result]}"
  puts

  # Example 10: Practical use case - Calculator
  puts "10. Practical Example - Simple Calculator"
  puts "-" * 40

  expressions = [
    "10 + 5",
    "20 - 8",
    "6 * 7",
    "100 / 4"
  ]

  expressions.each do |expr|
    result = eval_tool.execute(
      action: SharedTools::Tools::EvalTool::Action::RUBY,
      code: expr
    )
    puts "#{expr} = #{result[:result]}"
  end
  puts

rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.first(5)
ensure
  # Restore default authorization behavior
  SharedTools.auto_execute(false)
end

puts "=" * 80
puts "Example completed!"
puts "=" * 80
puts
puts "Key Takeaways:"
puts "- EvalTool provides a unified interface for Ruby, Python, and Shell execution"
puts "- Each execution type has built-in safety with user authorization (when enabled)"
puts "- Results include success status, output, and error information"
puts "- Individual tools can be used directly for more control"
puts "- Always use auto_execute(false) in production for security"
