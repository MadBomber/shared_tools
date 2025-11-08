#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using DatabaseQueryTool with LLM Integration
#
# This example demonstrates how an LLM can execute safe, read-only database
# queries through natural language prompts using the Sequel gem.
#
# Note: This example requires the 'sequel' and 'sqlite3' gems:
#   gem install sequel sqlite3

require_relative 'ruby_llm_config'

begin
  require 'sequel'
  require 'sqlite3'
  require 'shared_tools/tools/database_query_tool'
rescue LoadError => e
  title "ERROR: Missing required dependencies for DatabaseQueryTool"

  puts <<~ERROR_MSG

    This example requires the 'sequel' and 'sqlite3' gems:
      gem install sequel sqlite3

    Or add to your Gemfile:
      gem 'sequel'
      gem 'sqlite3'

    Then run: bundle install
    #{'=' * 80}
  ERROR_MSG

  exit 1
end

title "DatabaseQueryTool Example - LLM-Powered Safe Queries"

# Create a SQLite database and populate with sample data
# Using a temporary file so the tool can connect to the same database
db_file = '/tmp/shared_tools_db_example.sqlite'
File.delete(db_file) if File.exist?(db_file)
db = Sequel.sqlite(db_file)

# Create tables
db.create_table :employees do
  primary_key :id
  String :name
  String :department
  Integer :salary
  Boolean :active
end

db.create_table :departments do
  primary_key :id
  String :name
  String :location
end

# Insert sample data
db[:departments].insert(name: 'Engineering', location: 'Building A')
db[:departments].insert(name: 'Sales', location: 'Building B')
db[:departments].insert(name: 'Marketing', location: 'Building A')

db[:employees].insert(name: 'Alice Smith', department: 'Engineering', salary: 95000, active: true)
db[:employees].insert(name: 'Bob Johnson', department: 'Engineering', salary: 85000, active: true)
db[:employees].insert(name: 'Carol White', department: 'Sales', salary: 75000, active: true)
db[:employees].insert(name: 'David Brown', department: 'Marketing', salary: 70000, active: true)
db[:employees].insert(name: 'Eve Davis', department: 'Engineering', salary: 105000, active: true)
db[:employees].insert(name: 'Frank Miller', department: 'Sales', salary: 65000, active: false)

# Set DATABASE_URL for the tool to use
ENV['DATABASE_URL'] = "sqlite://#{db_file}"

# Register the DatabaseQueryTool with RubyLLM
tools = [
  SharedTools::Tools::DatabaseQueryTool.new
]

# Create a chat instance using ollama_chat helper
@chat = ollama_chat()

# Add tools to the chat
tools.each { |tool| @chat = @chat.with_tool(tool) }

begin
  # Example 1: Simple SELECT query
  title "Example 1: List All Employees", bc: '-'
  prompt = "Show me all employees in the database using SQL"
  test_with_prompt prompt


  # Example 2: Filtered query
  title "Example 2: Filter Active Employees", bc: '-'
  prompt = "Query the database for all active employees. Show their names and departments."
  test_with_prompt prompt


  # Example 3: Aggregate query
  title "Example 3: Calculate Average Salary", bc: '-'
  prompt = "What's the average salary across all employees? Use SQL to calculate it."
  test_with_prompt prompt


  # Example 4: Grouped aggregation
  title "Example 4: Salary Statistics by Department", bc: '-'
  prompt = "Show me the average salary for each department, grouped by department name"
  test_with_prompt prompt


  # Example 5: Parameterized query for security
  title "Example 5: Parameterized Query", bc: '-'
  prompt = <<~PROMPT
    Query employees in the Engineering department using a parameterized query
    to prevent SQL injection. Use a placeholder for the department name.
  PROMPT
  test_with_prompt prompt


  # Example 6: Join query
  title "Example 6: Join Employees with Departments", bc: '-'
  prompt = <<~PROMPT
    Join the employees and departments tables to show employee names
    with their department location.
  PROMPT
  test_with_prompt prompt


  # Example 7: Complex query with ordering
  title "Example 7: Top Earners", bc: '-'
  prompt = "Show me the top 3 highest-paid employees ordered by salary descending"
  test_with_prompt prompt


  # Example 8: Query with LIMIT
  title "Example 8: Limited Results", bc: '-'
  prompt = "Get the first 5 employees from the database, but limit the results to 5 rows"
  test_with_prompt prompt


  # Example 9: COUNT query
  title "Example 9: Count Records", bc: '-'
  prompt = "How many employees do we have in each department? Use COUNT and GROUP BY."
  test_with_prompt prompt


  # Example 10: Conversational queries
  title "Example 10: Conversational Database Interaction", bc: '-'

  prompt = "How many total employees are in the database?"
  test_with_prompt prompt

  prompt = "Which department has the most employees?"
  test_with_prompt prompt

  prompt = "Show me employees earning more than $80,000"
  test_with_prompt prompt

rescue => e
  puts "\nError during database operations: #{e.message}"
  puts e.backtrace.first(3)
ensure
  # Cleanup
  db.disconnect if db
  ENV.delete('DATABASE_URL')
  File.delete(db_file) if File.exist?(db_file)
end

title "Example completed!"

puts <<~TAKEAWAYS

  Key Takeaways:
  - The LLM executes safe, read-only SQL queries via natural language
  - Only SELECT statements are allowed (no INSERT, UPDATE, DELETE)
  - Supports parameterized queries for SQL injection prevention
  - Automatic LIMIT enforcement to prevent excessive results
  - Query timeout support to prevent long-running queries
  - Works with any database supported by Sequel
  - Connection management is handled automatically
  - The LLM maintains conversational context about queries
  - Perfect for AI-assisted data analysis and reporting

TAKEAWAYS
