#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo: Using CalculatorTool with LLM Integration
#
# This demo demonstrates how an LLM can use the CalculatorTool to perform
# safe mathematical calculations through natural language prompts.
#
# Requires:
#   require_relative 'common'
#   require 'shared_tools/calculator_tool'

require_relative 'common'

begin
  require 'dentaku'
  require 'shared_tools/calculator_tool'
rescue LoadError => e
  title "ERROR: Missing required dependencies for CalculatorTool"

  puts <<~ERROR_MSG

    This demo requires the 'dentaku' gem:
      gem install dentaku

    Or add to your Gemfile:
      gem 'dentaku'

    Then run: bundle install
    #{'=' * 80}
  ERROR_MSG

  exit 1
end


title "CalculatorTool Demo - LLM-Powered Calculations"

# Register the CalculatorTool with RubyLLM
tools = [
  SharedTools::Tools::CalculatorTool.new
]

# Create a chat instance using new_chat helper
@chat = new_chat()

# Add tools to the chat
tools.each { |tool| @chat = @chat.with_tool(tool) }

# Example 1: Basic arithmetic
title "Example 1: Basic Arithmetic", char: '-'
prompt = "What is 127 plus 349?"
test_with_prompt prompt


# Example 2: Complex expression
title "Example 2: Complex Expression with Parentheses", char: '-'
prompt = "Calculate (15 + 7) * 3 - 10 / 2"
test_with_prompt prompt


# Example 3: Square root
title "Example 3: Square Root Calculation", char: '-'
prompt = "What is the square root of 256?"
test_with_prompt prompt


# Example 4: Percentage calculation
title "Example 4: Percentage Calculation", char: '-'
prompt = "If a product costs $120 and there's a 15% discount, how much is the discount amount? Calculate 120 * 0.15"
test_with_prompt prompt


# Example 5: Precision control
title "Example 5: Division with Specific Precision", char: '-'
prompt = "Divide 100 by 3 and give me the result with 4 decimal places"
test_with_prompt prompt


# Example 6: Scientific calculation
title "Example 6: Exponentiation", char: '-'
prompt = "Calculate 2 to the power of 10"
test_with_prompt prompt


# Example 7: Multiple operations
title "Example 7: Multi-Step Calculation", char: '-'
prompt = <<~PROMPT
  I need to calculate the total cost:
  - Item 1: 3 units at $12.50 each
  - Item 2: 5 units at $8.75 each
  What's the total? Calculate (3 * 12.50) + (5 * 8.75)
PROMPT
test_with_prompt prompt


# Example 8: Rounding
title "Example 8: Rounding Numbers", char: '-'
prompt = "Round 3.14159 to 2 decimal places"
test_with_prompt prompt


# Example 9: Conversational context
title "Example 9: Conversational Calculations", char: '-'

prompt = "What is 50 multiplied by 8?"
test_with_prompt prompt

prompt = "Now add 125 to that result"
test_with_prompt prompt

prompt = "Finally, divide that by 5"
test_with_prompt prompt

title "Demo completed!"

puts <<~TAKEAWAYS

  Key Takeaways:
  - The LLM uses CalculatorTool for safe mathematical calculations
  - Supports basic arithmetic, exponents, square roots, and rounding
  - Precision can be controlled for decimal results
  - Natural language is converted to proper mathematical expressions
  - Dentaku provides safe evaluation without code injection risks
  - The LLM maintains conversational context across calculations

TAKEAWAYS
