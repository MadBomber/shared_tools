#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using DevopsToolkit with LLM Integration
#
# This example demonstrates how an LLM can perform DevOps operations
# through natural language prompts with built-in safety mechanisms.

require_relative 'ruby_llm_config'
require 'shared_tools/tools/devops_toolkit'

title "DevopsToolkit Example - LLM-Powered DevOps Operations"

# Register the DevopsToolkit with RubyLLM
tools = [
  SharedTools::Tools::DevopsToolkit.new
]

# Create a chat instance using ollama_chat helper
@chat = ollama_chat()

# Add tools to the chat
tools.each { |tool| @chat = @chat.with_tool(tool) }

# Example 1: Health check in development
title "Example 1: Health Check - Development Environment", bc: '-'
prompt = <<~PROMPT
  Perform a health check on the development environment.
  Check all critical services and report their status.
PROMPT
test_with_prompt prompt


# Example 2: Deploy to staging
title "Example 2: Deploy to Staging", bc: '-'
prompt = <<~PROMPT
  Deploy version 2.5.0 to the staging environment.
  Use the 'main' branch and enable rollback on failure.
PROMPT
test_with_prompt prompt


# Example 3: Log analysis
title "Example 3: Analyze Application Logs", bc: '-'
prompt = <<~PROMPT
  Analyze logs for the staging environment over the last 24 hours.
  Look for error-level messages and search for any database connection issues.
PROMPT
test_with_prompt prompt


# Example 4: Collect metrics
title "Example 4: Collect System Metrics", bc: '-'
prompt = <<~PROMPT
  Collect system and application metrics from the staging environment.
  Get CPU, memory, and request metrics over the last hour in JSON format.
PROMPT
test_with_prompt prompt


# Example 5: Rollback operation
title "Example 5: Rollback to Previous Version", bc: '-'
prompt = <<~PROMPT
  Rollback the staging deployment to the previous stable version.
  This is needed because we found a critical bug.
PROMPT
test_with_prompt prompt


# Example 6: Production health check (safe operation)
title "Example 6: Production Health Check", bc: '-'
prompt = <<~PROMPT
  Check the health status of the production environment.
  I need to verify all services are running properly.
PROMPT
test_with_prompt prompt


# Example 7: Attempting production deploy without confirmation (will fail safely)
title "Example 7: Production Deploy - Safety Check", bc: '-'
prompt = <<~PROMPT
  Deploy version 2.5.1 to production using the 'release' branch.
PROMPT
test_with_prompt prompt


# Example 8: Production deploy with proper confirmation
title "Example 8: Production Deploy - With Confirmation", bc: '-'
prompt = <<~PROMPT
  Deploy version 2.5.1 to production with explicit confirmation.
  I understand this is a production operation and I confirm it.
  Use options: production_confirmed: true, branch: 'release', rollback_on_failure: true
PROMPT
test_with_prompt prompt


# Example 9: Development operations (no restrictions)
title "Example 9: Development Environment Operations", bc: '-'
prompt = "Deploy the latest code from 'feature-branch' to development"
test_with_prompt prompt

prompt = "Check the deployment logs for development"
test_with_prompt prompt


# Example 10: Conversational DevOps workflow
title "Example 10: Conversational DevOps", bc: '-'

prompt = "What's the current health status of staging?"
test_with_prompt prompt

prompt = "Are there any recent errors in the staging logs?"
test_with_prompt prompt

prompt = "Deploy the latest version to staging"
test_with_prompt prompt

prompt = "Verify the deployment was successful by checking health again"
test_with_prompt prompt

title "Example completed!"

puts <<~TAKEAWAYS

  Key Takeaways:
  - The LLM performs DevOps operations through natural language
  - Safety mechanisms protect production environments
  - Production operations require explicit confirmation
  - All operations are logged with unique operation IDs
  - Supports deployments, rollbacks, health checks, logs, and metrics
  - Environment-specific restrictions prevent accidents
  - The LLM maintains context across DevOps operations
  - Perfect for AI-assisted infrastructure management
  - Built-in audit trail for compliance requirements

  Safety Features Demonstrated:
  - Production confirmation requirement
  - Environment validation
  - Operation logging and tracking
  - Rollback capabilities
  - Health check integration

TAKEAWAYS
