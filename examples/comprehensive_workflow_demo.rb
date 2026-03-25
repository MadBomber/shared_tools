#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: Comprehensive Multi-Tool Workflow
#
# Shows how an LLM orchestrates multiple tools together:
# database storage → data analysis → report generation → CSV export.
#
# Run:
#   bundle exec ruby -I examples examples/comprehensive_workflow_demo.rb

require_relative 'common'
require 'shared_tools/database_tool'
require 'shared_tools/disk_tool'
require 'shared_tools/eval_tool'


begin
  require 'sqlite3'
rescue LoadError
  puts "ERROR: Missing sqlite3 gem. Install with: gem install sqlite3"
  exit 1
end

require 'tmpdir'
require 'fileutils'

title "Comprehensive Workflow Demo — Multi-Tool LLM Orchestration"
puts "DatabaseTool + DiskTool + EvalTool working together"
puts

db = SQLite3::Database.new(':memory:')

class SimpleSqliteDriver < SharedTools::Tools::Database::BaseDriver
  def initialize(db:)
    @db = db
  end

  def perform(statement:)
    if statement.match?(/^\s*SELECT/i)
      rows = @db.execute(statement)
      { status: :ok, result: rows }
    else
      @db.execute(statement)
      { status: :ok, result: "Success (#{@db.changes} rows)" }
    end
  rescue SQLite3::Exception => e
    { status: :error, result: e.message }
  end
end

temp_dir    = Dir.mktmpdir('llm_workflow')
db_driver   = SimpleSqliteDriver.new(db: db)
disk_driver = SharedTools::Tools::Disk::LocalDriver.new(root: temp_dir)

@chat = @chat.with_tools(
  SharedTools::Tools::DatabaseTool.new(driver: db_driver),
  SharedTools::Tools::Disk::FileCreateTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::FileWriteTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::FileReadTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::DirectoryCreateTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::DirectoryListTool.new(driver: disk_driver),
  SharedTools::Tools::Eval::RubyEvalTool.new
)

begin
  title "Phase 1: Data Preparation", char: '-'
  ask <<~PROMPT
    Set up a product database:
    1. Create a table 'products' with columns: id (primary key), name (text), price (integer), category (text)
    2. Insert: Laptop Pro $1299 Electronics, Wireless Mouse $29 Electronics, Office Chair $249 Furniture, Desk Lamp $45 Furniture
    3. Tell me how many products you added
  PROMPT

  title "Phase 2: Data Analysis", char: '-'
  ask <<~PROMPT
    Analyse the products database:
    1. Total number of products
    2. Average price by category
    3. Most expensive and cheapest products
  PROMPT

  title "Phase 3: Report Generation", char: '-'
  ask <<~PROMPT
    Generate a markdown report:
    1. Create a 'reports' directory
    2. Create 'product_report.md' in it
    3. Write a report with header "Product Inventory Report", current date, summary stats, and products by category
    4. Show me the report contents
  PROMPT

  title "Phase 4: CSV Export", char: '-'
  ask <<~PROMPT
    Export product data to CSV:
    1. Query all products
    2. Create 'products.csv' in the reports directory
    3. Write CSV with headers: Name,Price,Category
    4. Confirm how many rows were exported
  PROMPT

  title "Phase 5: Conversational Multi-Tool Workflow", char: '-'
  ask "Find all electronics products and show their names and prices."
  ask "Create a file 'electronics_summary.txt' with this information."
  ask "List all files in the reports directory."

rescue => e
  puts "\nError: #{e.message}"
  puts e.backtrace.first(5)
ensure
  db.close
  FileUtils.rm_rf(temp_dir) if temp_dir
end

title "Done", char: '-'
puts "The LLM coordinated DatabaseTool, DiskTool, and EvalTool across a multi-phase workflow."
