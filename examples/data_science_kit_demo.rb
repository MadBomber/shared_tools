#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: DataScienceKit
#
# Shows how an LLM uses the DataScienceKit to perform statistical
# analysis, identify trends, and generate insights from structured data.
#
# Run:
#   bundle exec ruby -I examples examples/data_science_kit_demo.rb

require_relative 'common'
require 'shared_tools/data_science_kit'


title "DataScienceKit Demo"

@chat = @chat.with_tool(SharedTools::Tools::DataScienceKit.new)

title "Descriptive Statistics", char: '-'
ask <<~PROMPT
  Analyse this monthly revenue dataset (in thousands USD) for a SaaS company:
  Jan: 42, Feb: 45, Mar: 51, Apr: 48, May: 55, Jun: 62,
  Jul: 58, Aug: 67, Sep: 71, Oct: 74, Nov: 69, Dec: 83

  Calculate: mean, median, standard deviation, min, max, and the
  coefficient of variation. Identify any outliers.
PROMPT

title "Trend Analysis", char: '-'
ask <<~PROMPT
  Using the same 12-month revenue series from the previous question,
  identify the trend direction, calculate month-over-month growth rates,
  and predict revenue for January of the following year using linear regression.
PROMPT

title "Correlation Analysis", char: '-'
ask <<~PROMPT
  Examine the correlation between marketing spend and revenue:
  Marketing spend (USD thousands): 8, 9, 11, 10, 12, 15, 13, 17, 18, 19, 16, 22
  Revenue       (USD thousands):  42, 45, 51, 48, 55, 62, 58, 67, 71, 74, 69, 83

  Calculate the correlation coefficient and explain whether marketing
  spend is a strong predictor of revenue.
PROMPT

title "Segmentation", char: '-'
ask <<~PROMPT
  Group these 12 months into quarters and calculate:
  - Total and average revenue per quarter
  - Which quarter showed the strongest growth
  - Quarter-over-quarter growth rate
PROMPT

title "Anomaly Detection", char: '-'
ask <<~PROMPT
  Look at this daily user signup data for April (30 days):
  120,135,128,141,118,95,102,156,163,147,138,142,129,88,91,
  172,168,154,161,149,143,137,85,94,178,182,169,175,163,158

  Identify any anomalous days (potential bot traffic or outages) using
  statistical methods, and explain what thresholds you used.
PROMPT

title "Done", char: '-'
puts "DataScienceKit provided statistical analysis and business insights through natural language."
