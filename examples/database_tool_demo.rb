#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo: Using DatabaseTool with LLM Integration
#
# This demo demonstrates how an LLM can execute SQL operations
# through natural language prompts using the DatabaseTool.
#
# Requires:
#   require_relative 'common'
#   require 'shared_tools/database'
#
# Note: This demo requires the 'sqlite3' gem:
#   gem install sqlite3

require_relative 'common'

begin
  require 'sqlite3'
  require 'shared_tools/database'
rescue LoadError => e
  title "ERROR: Missing required dependencies for DatabaseTool"

  puts <<~ERROR_MSG

    This demo requires the 'sqlite3' gem:
      gem install sqlite3

    Or add to your Gemfile:
      gem 'sqlite3'

    Then run: bundle install
    #{'=' * 80}
  ERROR_MSG

  exit 1
end


title "DatabaseTool Demo - LLM-Powered SQL Operations"

# Create a SQLite3 database driver
class SimpleSqliteDriver < SharedTools::Tools::Database::BaseDriver
  def initialize(db:)
    @db = db
  end

  def perform(statement:)
    statement = statement.strip

    # Determine if this is a query or a command
    if statement.match?(/^\s*(SELECT|PRAGMA)/i)
      execute_query(statement)
    else
      execute_command(statement)
    end
  rescue SQLite3::Exception => e
    { status: :error, result: e.message }
  end

  private

  def execute_query(statement)
    rows = @db.execute(statement)
    {
      status: :ok,
      result: format_results(rows)
    }
  end

  def execute_command(statement)
    @db.execute(statement)
    {
      status: :ok,
      result: "Command executed successfully (#{@db.changes} rows affected)"
    }
  end

  def format_results(rows)
    return "No results" if rows.empty?

    # Simple table formatting
    rows.map { |row| row.join(" | ") }.join("\n")
  end
end

# Create an in-memory SQLite database
db = SQLite3::Database.new(':memory:')
driver = SimpleSqliteDriver.new(db: db)

# Register the DatabaseTool with RubyLLM
tools = [
  SharedTools::Tools::DatabaseTool.new(driver: driver)
]

# Create a chat instance using new_chat helper
@chat = new_chat()

# Add tools to the chat
tools.each { |tool| @chat = @chat.with_tool(tool) }

begin
  # Example 1: Create a table
  title "Example 1: Create a Database Table", char: '-'
  prompt = "Create a table called 'users' with columns: id (primary key), name (text), email (text), and age (integer)."
  test_with_prompt prompt

  # Example 2: Insert data
  title "Example 2: Insert Records", char: '-'
  prompt = <<~PROMPT
    Insert three users into the users table:
    - Alice Smith, alice@example.com, age 30
    - Bob Johnson, bob@example.com, age 25
    - Carol White, carol@example.com, age 28
  PROMPT
  test_with_prompt prompt

  # Example 3: Query data
  title "Example 3: Retrieve All Users", char: '-'
  prompt = "Show me all the users in the database."
  test_with_prompt prompt

  # Example 4: Filtered query
  title "Example 4: Filtered Query", char: '-'
  prompt = "Find all users who are older than 25 and show their names and ages, ordered by age."
  test_with_prompt prompt

  # Example 5: Update data
  title "Example 5: Update Records", char: '-'
  prompt = "Update Alice Smith's age to 31."
  test_with_prompt prompt

  # Example 6: Create related table
  title "Example 6: Create Related Table", char: '-'
  prompt = <<~PROMPT
    Create a posts table with:
    - id (primary key)
    - user_id (foreign key to users)
    - title (text)
    - body (text)
  PROMPT
  test_with_prompt prompt

  # Example 7: Insert related data
  title "Example 7: Insert Related Data", char: '-'
  prompt = <<~PROMPT
    Add some posts to the posts table:
    - User 1: "Hello World", "My first post"
    - User 1: "Ruby is Great", "I love Ruby programming"
    - User 2: "Database Tools", "Working with SQLite"
  PROMPT
  test_with_prompt prompt

  # Example 8: Join query
  title "Example 8: Join Query", char: '-'
  prompt = "Show me all posts with the author's name."
  test_with_prompt prompt

  # Example 9: Aggregate query
  title "Example 9: Aggregate Calculations", char: '-'
  prompt = "How many users are in the database and what's their average age?"
  test_with_prompt prompt

  # Example 10: Conversational database interaction
  title "Example 10: Conversational Database Operations", char: '-'

  prompt = "Count how many posts each user has written."
  test_with_prompt prompt

  prompt = "Who has the most posts?"
  test_with_prompt prompt

  prompt = "Delete all posts by user 2."
  test_with_prompt prompt

rescue => e
  puts "\nError during database operations: #{e.message}"
  puts e.backtrace.first(3)
ensure
  # Close database connection
  db.close
  puts "\nDatabase connection closed."
end

title "Demo completed!"

puts <<~TAKEAWAYS

  Key Takeaways:
  - The LLM translates natural language into SQL queries
  - Complex joins and aggregations become conversational
  - Database operations don't require SQL expertise
  - The LLM maintains context about database schema and operations
  - Data analysis and manipulation are intuitive

TAKEAWAYS
