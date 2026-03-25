#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: DatabaseQueryTool
#
# Shows how an LLM executes safe, read-only SQL queries through natural
# language (requires sequel + sqlite3 gems).
#
# Run:
#   bundle exec ruby -I examples examples/database_query_tool_demo.rb

require_relative 'common'
require 'shared_tools/database_query_tool'


begin
  require 'sequel'
  require 'sqlite3'
rescue LoadError => e
  puts "ERROR: #{e.message}. Install with: gem install sequel sqlite3"
  exit 1
end

title "DatabaseQueryTool Demo — LLM-Powered Safe SQL Queries"

db_file = '/tmp/shared_tools_db_demo.sqlite'
File.delete(db_file) if File.exist?(db_file)
db = Sequel.sqlite(db_file)

db.create_table(:employees) { primary_key :id; String :name; String :department; Integer :salary; Boolean :active }
db.create_table(:departments) { primary_key :id; String :name; String :location }

db[:departments].insert(name: 'Engineering', location: 'Building A')
db[:departments].insert(name: 'Sales',       location: 'Building B')
db[:departments].insert(name: 'Marketing',   location: 'Building A')
db[:employees].insert(name: 'Alice Smith',  department: 'Engineering', salary: 95000,  active: true)
db[:employees].insert(name: 'Bob Johnson',  department: 'Engineering', salary: 85000,  active: true)
db[:employees].insert(name: 'Carol White',  department: 'Sales',       salary: 75000,  active: true)
db[:employees].insert(name: 'David Brown',  department: 'Marketing',   salary: 70000,  active: true)
db[:employees].insert(name: 'Eve Davis',    department: 'Engineering', salary: 105000, active: true)
db[:employees].insert(name: 'Frank Miller', department: 'Sales',       salary: 65000,  active: false)

ENV['DATABASE_URL'] = "sqlite://#{db_file}"
@chat = @chat.with_tool(SharedTools::Tools::DatabaseQueryTool.new)

begin
  title "Example 1: List All Employees", char: '-'
  ask "Show me all employees in the database using SQL"

  title "Example 2: Filter Active Employees", char: '-'
  ask "Query the database for all active employees. Show their names and departments."

  title "Example 3: Average Salary", char: '-'
  ask "What's the average salary across all employees? Use SQL to calculate it."

  title "Example 4: Salary by Department", char: '-'
  ask "Show me the average salary for each department, grouped by department name"

  title "Example 5: Join Query", char: '-'
  ask "Join employees and departments to show each employee's name and department location."

  title "Example 6: Top Earners", char: '-'
  ask "Show me the top 3 highest-paid employees ordered by salary descending"

  title "Example 7: Conversational Queries", char: '-'
  ask "How many total employees are in the database?"
  ask "Which department has the most employees?"
  ask "Show me employees earning more than $80,000"

rescue => e
  puts "\nError: #{e.message}"
ensure
  db.disconnect if db
  ENV.delete('DATABASE_URL')
  File.delete(db_file) if File.exist?(db_file)
end

title "Done", char: '-'
puts "DatabaseQueryTool let the LLM run safe read-only SQL through natural language."
