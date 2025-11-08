#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using WorkflowManagerTool with LLM Integration
#
# This example demonstrates how an LLM can manage stateful workflows
# through natural language prompts, maintaining state across multiple steps.

require_relative 'ruby_llm_config'
require 'shared_tools/tools/workflow_manager_tool'
require 'fileutils'

title "WorkflowManagerTool Example - LLM-Powered Workflow Management"

# Create a temporary storage directory for workflows
workflow_storage = File.join(Dir.tmpdir, "llm_workflows_#{Time.now.to_i}")
FileUtils.mkdir_p(workflow_storage)

# Register the WorkflowManagerTool with RubyLLM
tools = [
  SharedTools::Tools::WorkflowManagerTool.new(storage_dir: workflow_storage)
]

# Create a chat instance using ollama_chat helper
@chat = ollama_chat()

# Add tools to the chat
tools.each { |tool| @chat = @chat.with_tool(tool) }

begin
  # Example 1: Start a new workflow
  title "Example 1: Start a New Workflow", bc: '-'
  prompt = <<~PROMPT
    Start a new workflow for processing customer orders with the following initial data:
    - customer_name: "Alice Johnson"
    - order_type: "premium"
    - items_count: 5
  PROMPT
  test_with_prompt prompt


  # Example 2: Add workflow steps
  title "Example 2: Process Workflow Steps", bc: '-'
  prompt = <<~PROMPT
    Add a step to the workflow to validate the inventory.
    Use the workflow_id from the previous response.
    Include step data: action: "inventory_check", status: "validated"
  PROMPT
  test_with_prompt prompt

  prompt = <<~PROMPT
    Add another step for payment processing with data:
    action: "process_payment", amount: 299.99, status: "completed"
  PROMPT
  test_with_prompt prompt


  # Example 3: Check workflow status
  title "Example 3: Check Workflow Status", bc: '-'
  prompt = "What's the current status of the workflow? Show me all the steps completed so far."
  test_with_prompt prompt


  # Example 4: Add more steps
  title "Example 4: Continue Workflow Processing", bc: '-'
  prompt = <<~PROMPT
    Add a shipping step to the workflow with this information:
    action: "prepare_shipment", carrier: "FedEx", tracking: "123456789"
  PROMPT
  test_with_prompt prompt

  prompt = <<~PROMPT
    Now add a final notification step:
    action: "send_confirmation", email: "alice@example.com", sent: true
  PROMPT
  test_with_prompt prompt


  # Example 5: Complete the workflow
  title "Example 5: Complete the Workflow", bc: '-'
  prompt = "The workflow is finished. Mark it as complete and show me the summary."
  test_with_prompt prompt


  # Example 6: Start a new workflow for different use case
  title "Example 6: New Workflow - Data Pipeline", bc: '-'
  prompt = <<~PROMPT
    Start a new workflow for a data processing pipeline:
    - source: "customer_database"
    - target: "analytics_warehouse"
    - record_count: 10000
  PROMPT
  test_with_prompt prompt


  # Example 7: Multi-step data pipeline
  title "Example 7: Process Data Pipeline Steps", bc: '-'
  prompt = "Add a data extraction step with status: extracted, records: 10000"
  test_with_prompt prompt

  prompt = "Add a data transformation step with status: transformed, records: 9850, invalid: 150"
  test_with_prompt prompt

  prompt = "Add a data loading step with status: loaded, records: 9850, duration: 45"
  test_with_prompt prompt


  # Example 8: Check and complete second workflow
  title "Example 8: Review and Complete Pipeline", bc: '-'
  prompt = "Check the status of this data pipeline workflow"
  test_with_prompt prompt

  prompt = "Complete this workflow and show me the final summary"
  test_with_prompt prompt

rescue => e
  puts "\nError during workflow operations: #{e.message}"
  puts e.backtrace.first(3)
ensure
  # Cleanup
  FileUtils.rm_rf(workflow_storage) if workflow_storage && Dir.exist?(workflow_storage)
  puts "\nWorkflow storage cleaned up: #{workflow_storage}"
end

title "Example completed!"

puts <<~TAKEAWAYS

  Key Takeaways:
  - The LLM manages stateful workflows across multiple interactions
  - Workflows persist state between steps and can be resumed
  - Each workflow has a unique ID for tracking and management
  - Supports complex multi-step processes with metadata
  - The LLM maintains context about workflow state and progress
  - Workflows can be checked, updated, and completed programmatically
  - Perfect for coordinating complex automation tasks
  - State is persisted to disk and survives process restarts

TAKEAWAYS
