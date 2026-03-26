#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: CompositeAnalysisTool
#
# Shows how an LLM uses the CompositeAnalysisTool to combine multiple
# analysis strategies — structure detection, pattern recognition, and
# cross-source synthesis — in a single tool call.
#
# Run:
#   bundle exec ruby -I examples examples/composite_analysis_tool_demo.rb

ENV['RUBY_LLM_DEBUG'] = 'true'

require_relative 'common'
require 'shared_tools/composite_analysis_tool'


title "CompositeAnalysisTool Demo"

@chat = @chat.with_tool(SharedTools::Tools::CompositeAnalysisTool.new)

title "Sales Data Analysis", char: '-'
ask <<~PROMPT
  Use the composite_analysis tool with the following inline data to analyse
  quarterly sales for three product lines. Pass this table as the data parameter:

  Quarter | Widget A | Widget B | Widget C
  Q1 2025 | 12400    | 8200     | 3100
  Q2 2025 | 14100    | 7900     | 4800
  Q3 2025 | 13800    | 9400     | 6200
  Q4 2025 | 16500    | 10100    | 7900

  Use analysis_type "comprehensive". Then identify growth trends for each product,
  which has the strongest momentum, and any patterns that suggest strategic action.
PROMPT

title "Text Pattern Analysis", char: '-'
ask <<~PROMPT
  Use the composite_analysis tool with the following inline data to analyse
  customer support ticket subjects. Pass this as the data parameter (one per line):

  Login button not working on mobile
  Can't export data to CSV
  Payment failed three times
  Dashboard loads slowly
  Billing overcharge urgent
  Login issues since yesterday's update
  How do I export my data
  App crashes when uploading large files
  Wrong amount charged to my card
  Performance degraded after update

  Use analysis_type "standard". Then identify the top 3 issue categories and
  which need immediate attention.
PROMPT

title "Cross-Source Synthesis", char: '-'
ask <<~PROMPT
  Use the composite_analysis tool twice — once for each dataset below.

  First call — pass this as the data parameter for user acquisition:

  Week | Signups | Conversion
  1    | 230     | 18
  2    | 410     | 22
  3    | 380     | 19
  4    | 520     | 25

  Second call — pass this as the data parameter for support tickets:

  Week | Tickets | ResolutionHours
  1    | 12      | 4
  2    | 28      | 6
  3    | 22      | 5
  4    | 41      | 8

  Use analysis_type "comprehensive" for both. Then synthesise the results:
  as acquisition grows, is support keeping pace? What does the ticket-per-user
  ratio trend indicate?
PROMPT

title "Done", char: '-'
puts "CompositeAnalysisTool synthesised multiple data sources into actionable insights."
