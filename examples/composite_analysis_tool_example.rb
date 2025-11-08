#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using CompositeAnalysisTool with LLM Integration
#
# This example demonstrates how an LLM can perform comprehensive data analysis
# through natural language prompts, orchestrating multiple analysis steps.

require_relative 'ruby_llm_config'
require 'shared_tools/tools/composite_analysis_tool'

title "CompositeAnalysisTool Example - LLM-Powered Data Analysis"

# Register the CompositeAnalysisTool with RubyLLM
tools = [
  SharedTools::Tools::CompositeAnalysisTool.new
]

# Create a chat instance using ollama_chat helper
@chat = ollama_chat()

# Add tools to the chat
tools.each { |tool| @chat = @chat.with_tool(tool) }

# Example 1: Quick analysis of simulated CSV data
title "Example 1: Quick Analysis of Sales Data", bc: '-'
prompt = <<~PROMPT
  Perform a quick analysis on 'sales_data.csv' to get basic structure and summary statistics.
  Use analysis_type: quick
PROMPT
test_with_prompt prompt


# Example 2: Standard analysis with insights
title "Example 2: Standard Analysis with Insights", bc: '-'
prompt = <<~PROMPT
  Analyze the data source 'products.csv' with standard analysis.
  I want to see the data structure, insights, and visualization suggestions.
PROMPT
test_with_prompt prompt


# Example 3: Comprehensive analysis with correlations
title "Example 3: Comprehensive Analysis", bc: '-'
prompt = <<~PROMPT
  Perform a comprehensive analysis on 'customer_metrics.csv' including:
  - Full data structure analysis
  - Statistical insights
  - Correlation analysis
  - Visualization recommendations
PROMPT
test_with_prompt prompt


# Example 4: Web data source analysis
title "Example 4: Analyze Web API Data", bc: '-'
prompt = <<~PROMPT
  Analyze data from 'https://api.example.com/data.json' with standard analysis.
  Show me the data structure and key insights.
PROMPT
test_with_prompt prompt


# Example 5: JSON file analysis
title "Example 5: JSON Data Analysis", bc: '-'
prompt = "Analyze 'user_data.json' and tell me what insights you can find"
test_with_prompt prompt


# Example 6: Analysis with custom options
title "Example 6: Custom Analysis Options", bc: '-'
prompt = <<~PROMPT
  Analyze 'metrics.csv' with these options:
  - Use comprehensive analysis type
  - Include correlations
  - Limit visualizations to 3 suggestions
PROMPT
test_with_prompt prompt


# Example 7: Conversational analysis
title "Example 7: Conversational Data Exploration", bc: '-'

prompt = "I have a file called 'sales.csv'. What can you tell me about its structure?"
test_with_prompt prompt

prompt = "Are there any correlations between the numeric columns?"
test_with_prompt prompt

prompt = "What visualizations would you recommend for this data?"
test_with_prompt prompt

title "Example completed!"

puts <<~TAKEAWAYS

  Key Takeaways:
  - The LLM performs multi-stage data analysis automatically
  - Supports both file paths and web URLs as data sources
  - Three analysis levels: quick, standard, comprehensive
  - Automatically detects data format (CSV, JSON, text)
  - Provides structure analysis, insights, and visualization suggestions
  - Includes correlation analysis for comprehensive mode
  - The LLM maintains conversational context about the data
  - Perfect for exploratory data analysis workflows

  Note: This example uses simulated data for demonstration purposes.
        In production, it would read actual files or fetch from web APIs.

TAKEAWAYS
