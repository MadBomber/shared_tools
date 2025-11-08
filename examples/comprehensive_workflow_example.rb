#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Comprehensive Workflow with LLM Integration
#
# This example demonstrates using multiple SharedTools together through
# natural language prompts. The LLM orchestrates: web scraping → database
# storage → data analysis → report generation.

require_relative 'ruby_llm_config'
require 'tmpdir'

begin
  require 'sqlite3'
  require 'shared_tools/tools/database'
  require 'shared_tools/tools/disk'
  require 'shared_tools/tools/eval'
rescue LoadError => e
  title "ERROR: Missing required dependencies for this workflow"

  puts <<~ERROR_MSG

    This example requires the 'sqlite3' gem:
      gem install sqlite3

    Or add to your Gemfile:
      gem 'sqlite3'

    Then run: bundle install
    #{'=' * 80}
  ERROR_MSG

  exit 1
end

title "Comprehensive Workflow Example - LLM-Powered"
puts "Web Scraping → Database Storage → Analysis → Report Generation"
puts

title "Setup: Create database and file system"

# Create an in-memory SQLite database
db = SQLite3::Database.new(':memory:')

# Simple SQLite driver
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

db_driver = SimpleSqliteDriver.new(db: db)

# Create temporary directory for reports
temp_dir = Dir.mktmpdir('llm_workflow')
disk_driver = SharedTools::Tools::Disk::LocalDriver.new(root: temp_dir)

# Register ALL tools with RubyLLM
tools = [
  # Database tools
  SharedTools::Tools::DatabaseTool.new(driver: db_driver),

  # File system tools
  SharedTools::Tools::Disk::FileCreateTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::FileWriteTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::FileReadTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::DirectoryCreateTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::DirectoryListTool.new(driver: disk_driver),

  # Code evaluation tools
  SharedTools::Tools::Eval::RubyEvalTool.new
]

# Create a chat instance using ollama_chat helper
@chat = ollama_chat()

# Add tools to the chat
tools.each { |tool| @chat = @chat.with_tool(tool) }

begin
  title "Phase 1: Data Preparation", bc: '-'
  prompt = <<~PROMPT
    I need you to set up a product database for me:
    1. Create a table called 'products' with columns: id (primary key), name (text), price (integer), category (text)
    2. Insert these products:
       - Laptop Pro, $1299, Electronics
       - Wireless Mouse, $29, Electronics
       - Office Chair, $249, Furniture
       - Desk Lamp, $45, Furniture
    3. Tell me how many products you added
  PROMPT
  test_with_prompt prompt

  # Phase 2: Data Analysis
  title "Phase 2: Data Analysis", bc: '-'
  prompt = <<~PROMPT
    Analyze the products database:
    1. What's the total number of products?
    2. What's the average price by category?
    3. Which product is the most expensive and which is the cheapest?
  PROMPT
  test_with_prompt prompt

  # Phase 3: Report Generation
  title "Phase 3: Report Generation", bc: '-'
  prompt = <<~PROMPT
    Generate a markdown report about the products:
    1. Create a directory called 'reports'
    2. Create a file called 'product_report.md' in that directory
    3. Write a report that includes:
       - A header "Product Inventory Report"
       - The current date
       - Summary statistics (total products, price range)
       - A section for each category listing the products
    4. Show me the report contents when done
  PROMPT
  test_with_prompt prompt

  # Phase 4: Data Export
  title "Phase 4: Data Export", bc: '-'
  prompt = <<~PROMPT
    Export the product data to CSV format:
    1. Query all products from the database
    2. Create a file called 'products.csv' in the reports directory
    3. Write the data as CSV with headers: Name,Price,Category
    4. Tell me how many products were exported
  PROMPT
  test_with_prompt prompt

  # Phase 5: Advanced Analysis
  title "Phase 5: Advanced Analysis", bc: '-'
  prompt = <<~PROMPT
    I want to understand the price distribution:
    1. Calculate the price difference between the most and least expensive items
    2. Create a simple price category (budget: <$50, mid: $50-$500, premium: >$500)
    3. Tell me how many products fall into each price category
    Use Ruby code evaluation to help with the calculations.
  PROMPT
  test_with_prompt prompt

  # Phase 6: Conversational Workflow
  title "Phase 6: Conversational Multi-Tool Workflow", bc: '-'

  prompt = "Find all electronics products and show me their names and prices."
  test_with_prompt prompt

  prompt = "Create a file called 'electronics_summary.txt' with this information."
  test_with_prompt prompt

  prompt = "Now list all files in the reports directory."
  test_with_prompt prompt

rescue => e
  puts "\nError during workflow: #{e.message}"
  puts e.backtrace.first(5)
ensure
  # Cleanup
  db.close
  FileUtils.rm_rf(temp_dir) if temp_dir
end

title "Workflow Summary", bc: '='

puts <<~SUMMARY

  This example demonstrated:
  ✓ Multi-phase workflow orchestration through natural language
  ✓ Database operations (create, insert, query, analyze)
  ✓ File system operations (create dirs, write files, read files)
  ✓ Code evaluation for calculations and data processing
  ✓ Report generation in multiple formats (Markdown, CSV)
  ✓ Conversational context maintenance across operations

  Key Takeaway:
  The LLM intelligently coordinates multiple tools to complete
  complex workflows that would normally require extensive scripting.

SUMMARY

title "Example completed!"
