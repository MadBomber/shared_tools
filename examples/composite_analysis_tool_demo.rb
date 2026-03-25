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

require_relative 'common'
require 'shared_tools/composite_analysis_tool'


title "CompositeAnalysisTool Demo"

@chat = @chat.with_tool(SharedTools::Tools::CompositeAnalysisTool.new)

title "Sales Data Analysis", char: '-'
ask <<~PROMPT
  Analyse the following quarterly sales data for three product lines:

  Quarter | Widget A | Widget B | Widget C
  Q1 2025 |   12,400 |    8,200 |   3,100
  Q2 2025 |   14,100 |    7,900 |   4,800
  Q3 2025 |   13,800 |    9,400 |   6,200
  Q4 2025 |   16,500 |   10,100 |   7,900

  Identify growth trends for each product, which product has the strongest
  momentum, and any patterns that suggest strategic action.
PROMPT

title "Text Pattern Analysis", char: '-'
ask <<~PROMPT
  Analyse the following customer support ticket subjects for common patterns,
  themes, and urgency signals:

  - "Login button not working on mobile"
  - "Can't export data to CSV"
  - "Payment failed three times"
  - "Dashboard loads slowly"
  - "Billing overcharge — urgent"
  - "Login issues since yesterday's update"
  - "How do I export my data?"
  - "App crashes when uploading large files"
  - "Wrong amount charged to my card"
  - "Performance degraded after update"

  What are the top 3 issue categories? Which need immediate attention?
PROMPT

title "Cross-Source Synthesis", char: '-'
ask <<~PROMPT
  Given these two datasets about the same product launch:

  Dataset A — User Acquisition (week 1-4):
  Week 1: 230 signups, 18% conversion
  Week 2: 410 signups, 22% conversion
  Week 3: 380 signups, 19% conversion
  Week 4: 520 signups, 25% conversion

  Dataset B — Support Tickets (week 1-4):
  Week 1: 12 tickets, avg resolution 4h
  Week 2: 28 tickets, avg resolution 6h
  Week 3: 22 tickets, avg resolution 5h
  Week 4: 41 tickets, avg resolution 8h

  Synthesise both datasets. As acquisition grows, is support keeping pace?
  What is the ticket-per-user ratio trend and what does it indicate?
PROMPT

title "Done", char: '-'
puts "CompositeAnalysisTool synthesised multiple data sources into actionable insights."
