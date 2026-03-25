#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: DevopsToolkit
#
# Shows how an LLM performs DevOps operations — deployments, health checks,
# log analysis, metrics collection, and rollbacks — with built-in safety
# mechanisms for production environments.
#
# Run:
#   bundle exec ruby -I examples examples/devops_toolkit_demo.rb

require_relative 'common'
require 'shared_tools/devops_toolkit'


title "DevopsToolkit Demo — LLM-Powered DevOps Operations"

@chat = @chat.with_tool(SharedTools::Tools::DevopsToolkit.new)

title "Example 1: Health Check — Development", char: '-'
ask "Perform a health check on the development environment and report service status."

title "Example 2: Deploy to Staging", char: '-'
ask "Deploy version 2.5.0 to the staging environment using the 'main' branch with rollback on failure."

title "Example 3: Analyze Application Logs", char: '-'
ask "Analyze logs for the staging environment over the last 24 hours. Look for errors and database connection issues."

title "Example 4: Collect System Metrics", char: '-'
ask "Collect CPU, memory, and request metrics from staging over the last hour in JSON format."

title "Example 5: Rollback to Previous Version", char: '-'
ask "Rollback the staging deployment to the previous stable version due to a critical bug."

title "Example 6: Production Health Check", char: '-'
ask "Check the health status of the production environment and verify all services are running."

title "Example 7: Production Deploy — Safety Check", char: '-'
ask "Deploy version 2.5.1 to production using the 'release' branch."

title "Example 8: Production Deploy — With Confirmation", char: '-'
ask <<~PROMPT
  Deploy version 2.5.1 to production with explicit confirmation.
  I confirm this is a production operation.
  Use: production_confirmed: true, branch: 'release', rollback_on_failure: true
PROMPT

title "Example 9: Conversational DevOps Workflow", char: '-'
ask "What's the current health status of staging?"
ask "Are there any recent errors in the staging logs?"
ask "Deploy the latest version to staging"
ask "Verify the deployment was successful by checking health again"

title "Done", char: '-'
puts "DevopsToolkit performed DevOps operations safely through natural language."
