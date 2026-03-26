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

ENV['RUBY_LLM_DEBUG'] = 'true'

require_relative 'common'
require 'shared_tools/data_science_kit'


title "DataScienceKit Demo"

@chat = @chat.with_tool(SharedTools::Tools::DataScienceKit.new)

title "Descriptive Statistics", char: '-'
ask <<~PROMPT
  Use the data_science_kit tool with analysis_type "statistical_summary" and pass
  this monthly revenue data (in thousands USD) as the data parameter (pipe-delimited):

  Month | Revenue
  Jan   | 42
  Feb   | 45
  Mar   | 51
  Apr   | 48
  May   | 55
  Jun   | 62
  Jul   | 58
  Aug   | 67
  Sep   | 71
  Oct   | 74
  Nov   | 69
  Dec   | 83

  Report: mean, median, standard deviation, min, max, coefficient of variation,
  and any outliers.
PROMPT

title "Trend Analysis", char: '-'
@chat = new_chat.with_tool(SharedTools::Tools::DataScienceKit.new)
ask <<~PROMPT
  Use the data_science_kit tool with analysis_type "time_series" and pass
  this data as the data parameter (pipe-delimited):

  Month | Revenue
  Jan   | 42
  Feb   | 45
  Mar   | 51
  Apr   | 48
  May   | 55
  Jun   | 62
  Jul   | 58
  Aug   | 67
  Sep   | 71
  Oct   | 74
  Nov   | 69
  Dec   | 83

  Identify trend direction, month-over-month growth rates, and predict
  revenue for January of the following year.
PROMPT

title "Correlation Analysis", char: '-'
@chat = new_chat.with_tool(SharedTools::Tools::DataScienceKit.new)
ask <<~PROMPT
  Use the data_science_kit tool with analysis_type "correlation_analysis" and
  pass this data as the data parameter (pipe-delimited):

  Month | Marketing | Revenue
  Jan   | 8         | 42
  Feb   | 9         | 45
  Mar   | 11        | 51
  Apr   | 10        | 48
  May   | 12        | 55
  Jun   | 15        | 62
  Jul   | 13        | 58
  Aug   | 17        | 67
  Sep   | 18        | 71
  Oct   | 19        | 74
  Nov   | 16        | 69
  Dec   | 22        | 83

  Calculate the correlation coefficient and explain whether marketing spend
  is a strong predictor of revenue.
PROMPT

title "Segmentation", char: '-'
@chat = new_chat.with_tool(SharedTools::Tools::DataScienceKit.new)
ask <<~PROMPT
  Use the data_science_kit tool with analysis_type "clustering" and pass
  this data as the data parameter (pipe-delimited):

  Month   | Quarter | Revenue
  Jan     | Q1      | 42
  Feb     | Q1      | 45
  Mar     | Q1      | 51
  Apr     | Q2      | 48
  May     | Q2      | 55
  Jun     | Q2      | 62
  Jul     | Q3      | 58
  Aug     | Q3      | 67
  Sep     | Q3      | 71
  Oct     | Q4      | 74
  Nov     | Q4      | 69
  Dec     | Q4      | 83

  Group the months into their quarters and calculate total and average revenue
  per quarter, identify which quarter had the strongest growth, and compute
  quarter-over-quarter growth rates.
PROMPT

title "Anomaly Detection", char: '-'
@chat = new_chat.with_tool(SharedTools::Tools::DataScienceKit.new)
ask <<~PROMPT
  Use the data_science_kit tool with analysis_type "statistical_summary" and pass
  this daily signup data for April as the data parameter (pipe-delimited):

  Day | Signups
  1   | 120
  2   | 135
  3   | 128
  4   | 141
  5   | 118
  6   | 95
  7   | 102
  8   | 156
  9   | 163
  10  | 147
  11  | 138
  12  | 142
  13  | 129
  14  | 88
  15  | 91
  16  | 172
  17  | 168
  18  | 154
  19  | 161
  20  | 149
  21  | 143
  22  | 137
  23  | 85
  24  | 94
  25  | 178
  26  | 182
  27  | 169
  28  | 175
  29  | 163
  30  | 158

  Identify anomalous days (potential bot traffic or outages) using statistical
  methods, and explain the thresholds used.
PROMPT

title "Done", char: '-'
puts "DataScienceKit provided statistical analysis and business insights through natural language."
