#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using DataScienceKit with LLM Integration
#
# This example demonstrates how an LLM can perform advanced data science
# operations through natural language prompts.

require_relative 'ruby_llm_config'
require 'shared_tools/tools/data_science_kit'

title "DataScienceKit Example - LLM-Powered Data Science"

# Register the DataScienceKit with RubyLLM
tools = [
  SharedTools::Tools::DataScienceKit.new
]

# Create a chat instance using ollama_chat helper
@chat = ollama_chat()

# Add tools to the chat
tools.each { |tool| @chat = @chat.with_tool(tool) }

# Example 1: Statistical summary
title "Example 1: Statistical Summary Analysis", bc: '-'
prompt = <<~PROMPT
  Perform a statistical summary analysis on 'customer_data.csv'.
  I want to see descriptive statistics, distributions, and outlier detection.
PROMPT
test_with_prompt prompt


# Example 2: Correlation analysis
title "Example 2: Correlation Analysis", bc: '-'
prompt = <<~PROMPT
  Analyze correlations in 'sales_metrics.csv'.
  Use Pearson correlation method and show me the correlation matrix.
PROMPT
test_with_prompt prompt


# Example 3: Time series analysis
title "Example 3: Time Series Analysis", bc: '-'
prompt = <<~PROMPT
  Perform time series analysis on 'daily_revenue.csv'.
  The date column is 'date' and value column is 'revenue'.
  Detect trends, seasonality, and forecast the next 7 periods.
PROMPT
test_with_prompt prompt


# Example 4: Clustering analysis
title "Example 4: K-Means Clustering", bc: '-'
prompt = <<~PROMPT
  Cluster the data in 'customer_segments.csv' into 3 groups.
  Use k-means algorithm with Euclidean distance metric.
PROMPT
test_with_prompt prompt


# Example 5: Predictive modeling
title "Example 5: Prediction and Regression", bc: '-'
prompt = <<~PROMPT
  Build a prediction model using 'housing_data.csv'.
  The target column is 'price' and I want to predict house prices.
  Use 80% of data for training and 20% for validation.
PROMPT
test_with_prompt prompt


# Example 6: Statistical summary with custom parameters
title "Example 6: Custom Statistical Analysis", bc: '-'
prompt = <<~PROMPT
  Generate a statistical summary for 'product_performance.csv' with:
  - 95% confidence level
  - Include quartiles in the analysis
  - Use IQR method for outlier detection
PROMPT
test_with_prompt prompt


# Example 7: Spearman correlation
title "Example 7: Spearman Correlation Analysis", bc: '-'
prompt = <<~PROMPT
  Analyze correlations in 'rankings.csv' using Spearman method
  since the data might have non-linear relationships.
  Set significance level to 0.01.
PROMPT
test_with_prompt prompt


# Example 8: Hierarchical clustering
title "Example 8: Hierarchical Clustering", bc: '-'
prompt = <<~PROMPT
  Cluster 'gene_expression.csv' using hierarchical clustering.
  Create 5 clusters and use complete linkage method.
PROMPT
test_with_prompt prompt


# Example 9: Conversational data science workflow
title "Example 9: Conversational Analysis", bc: '-'

prompt = "What statistical insights can you provide about 'experiment_results.csv'?"
test_with_prompt prompt

prompt = "Are there any strong correlations in that data?"
test_with_prompt prompt

prompt = "Can you cluster the data into meaningful groups?"
test_with_prompt prompt

title "Example completed!"

puts <<~TAKEAWAYS

  Key Takeaways:
  - The LLM performs comprehensive data science operations
  - Supports statistical analysis, correlations, time series, and ML
  - Five analysis types: statistical_summary, correlation_analysis,
    time_series, clustering, and prediction
  - Automatically handles data loading and preprocessing
  - Provides detailed results with visualizations recommendations
  - Custom parameters for fine-tuned analysis
  - The LLM maintains context across analysis steps
  - Perfect for exploratory and production ML workflows

  Note: This example uses simulated data for demonstration purposes.
        In production, it would work with real datasets and potentially
        require additional ML libraries for advanced features.

TAKEAWAYS
