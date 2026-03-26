#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: WorkflowManagerTool
#
# Shows how an LLM uses the WorkflowManagerTool to create, track, and
# manage structured multi-step workflows — demonstrated here with a
# software release pipeline.
#
# Run:
#   bundle exec ruby -I examples examples/workflow_manager_tool_demo.rb

require_relative 'common'
require 'shared_tools/workflow_manager_tool'


title "WorkflowManagerTool Demo"

@chat = @chat.with_tool(SharedTools::Tools::WorkflowManagerTool.new)

title "Create Release Workflow", char: '-'
ask <<~PROMPT
  Create a workflow named "v2.0.0-release" with the following steps:
  1. run_tests        — Execute the full test suite
  2. security_scan    — Run dependency vulnerability scan
  3. build_artifacts  — Compile and package the release artifacts
  4. staging_deploy   — Deploy to staging environment
  5. qa_sign_off      — QA team reviews and approves staging
  6. production_deploy — Deploy to production
  7. notify_stakeholders — Send release announcement
PROMPT

title "List All Workflows", char: '-'
ask "List all existing workflows and their current status."

title "Start the Workflow", char: '-'
ask "Start the v2.0.0-release workflow and mark the first step (run_tests) as completed."

title "Progress Update", char: '-'
ask "Mark security_scan as completed and build_artifacts as in-progress."

title "Check Status", char: '-'
ask "What is the current status of the v2.0.0-release workflow? Which steps are done and which are pending?"

title "Block on QA", char: '-'
ask "Complete build_artifacts and staging_deploy. Mark qa_sign_off as blocked with the note: 'Waiting for QA team availability'."

title "Resume After QA", char: '-'
ask "QA has approved. Mark qa_sign_off as completed and production_deploy as in-progress."

title "Final Steps", char: '-'
ask "Complete production_deploy and notify_stakeholders. Mark the entire workflow as complete."

title "Post-Release Summary", char: '-'
ask "Give me a full summary of the v2.0.0-release workflow: all steps, their final status, and overall completion."

title "Done", char: '-'
puts "WorkflowManagerTool tracked an entire release pipeline from creation to completion."
