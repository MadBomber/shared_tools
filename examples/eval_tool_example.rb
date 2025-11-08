#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using EvalTool with LLM Integration
#
# This example demonstrates how an LLM can use the EvalTool to evaluate
# Ruby, Python, and shell commands through natural language prompts.

require_relative 'ruby_llm_config'

title "EvalTool Example - LLM-Powered Code Evaluation"

# Register the EvalTool with RubyLLM
tools = [
  SharedTools::Tools::Eval::RubyEvalTool.new,
  SharedTools::Tools::Eval::PythonEvalTool.new,
  SharedTools::Tools::Eval::ShellEvalTool.new
]

# Create a chat instance using ollama_chat helper
@chat = ollama_chat()

# Add tools to the chat
tools.each { |tool| @chat = @chat.with_tool(tool) }

# Example 1: Simple arithmetic via Ruby
title "Example 1: Simple Math Calculation", bc: '-'
prompt = "What is 15 multiplied by 23? Use Ruby to calculate this."
test_with_prompt prompt


# Example 2: Python for mathematical operations
title "Example 2: Scientific Calculation with Python", bc: '-'
prompt = "Calculate the square root of 144 plus pi. Use Python with the math library."
test_with_prompt prompt


# Example 3: Shell command for system information
title "Example 3: System Information via Shell", bc: '-'
prompt = "What is the current date and time? Use a shell command to find out."
test_with_prompt prompt


# Example 4: Ruby code with data processing
title "Example 4: Data Processing with Ruby", bc: '-'
prompt = "Create an array of numbers from 1 to 10, then calculate their sum and average using Ruby."
test_with_prompt prompt


# Example 5: Python for text manipulation
title "Example 5: Text Processing with Python", bc: '-'
prompt = "Reverse the string 'Hello World' and convert it to uppercase using Python."
test_with_prompt prompt


# Example 6: Shell command with pipes
title "Example 6: Shell Command with Pipes", bc: '-'
prompt = "List all Ruby files in the current directory and count them. Use shell commands."
test_with_prompt prompt


# Example 7: Multi-step calculation
title "Example 7: Multi-Step Calculation", bc: '-'
prompt = <<~PROMPT
  I need to calculate compound interest.
  If I invest $1000 at 5% annual interest for 3 years,
  what will the final amount be?
  Use the formula: A = P(1 + r)^t where P=1000, r=0.05, t=3.
  Calculate this using Ruby.
PROMPT
test_with_prompt prompt


# Example 8: Conversation with context
title "Example 8: Conversational Context", bc: '-'

prompt = "Calculate 100 divided by 4 using Ruby."
test_with_prompt prompt

prompt = "Now multiply that result by 3."
test_with_prompt prompt

title "Example completed!"

puts <<~TAKEAWAYS

  Key Takeaways:
  - The LLM intelligently chooses which eval tool to use (Ruby, Python, or Shell)
  - Natural language prompts are converted to actual code execution
  - The LLM can maintain context across multiple interactions
  - Tools provide safety through SharedTools authorization system
  - Different languages can be used based on the task requirements

TAKEAWAYS
