#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using DatabaseTool for SQL operations
#
# This example demonstrates how to use the DatabaseTool to execute
# SQL statements on a database. We'll use SQLite3 as the database.
#
# Note: This example requires the 'sqlite3' gem:
#   gem install sqlite3

require 'bundler/setup'
require 'shared_tools'

begin
  require 'sqlite3'
rescue LoadError
  puts "Error: This example requires the 'sqlite3' gem."
  puts "Install it with: gem install sqlite3"
  exit 1
end

puts "=" * 80
puts "DatabaseTool Example - SQL Operations with SQLite"
puts "=" * 80
puts

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
database_tool = SharedTools::Tools::DatabaseTool.new(driver: driver)

# Example 1: Create a table
puts "1. Creating a users table"
puts "-" * 40
results = database_tool.execute(
  statements: [
    "CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, email TEXT NOT NULL, age INTEGER)"
  ]
)
results.each do |result|
  puts "Status: #{result[:status]}"
  puts "Result: #{result[:result]}"
end
puts

# Example 2: Insert data
puts "2. Inserting users"
puts "-" * 40
results = database_tool.execute(
  statements: [
    "INSERT INTO users (name, email, age) VALUES ('Alice Smith', 'alice@example.com', 30)",
    "INSERT INTO users (name, email, age) VALUES ('Bob Johnson', 'bob@example.com', 25)",
    "INSERT INTO users (name, email, age) VALUES ('Carol White', 'carol@example.com', 28)"
  ]
)
results.each do |result|
  puts "Statement: #{result[:statement]}"
  puts "Status: #{result[:status]}"
  puts "Result: #{result[:result]}"
  puts
end

# Example 3: Query data
puts "3. Querying all users"
puts "-" * 40
results = database_tool.execute(
  statements: ["SELECT * FROM users"]
)
results.each do |result|
  puts "Status: #{result[:status]}"
  puts "Results:"
  puts result[:result]
end
puts

# Example 4: Update data
puts "4. Updating user age"
puts "-" * 40
results = database_tool.execute(
  statements: [
    "UPDATE users SET age = 31 WHERE name = 'Alice Smith'"
  ]
)
results.each do |result|
  puts "Statement: #{result[:statement]}"
  puts "Result: #{result[:result]}"
end
puts

# Example 5: Query with WHERE clause
puts "5. Querying users over 25"
puts "-" * 40
results = database_tool.execute(
  statements: ["SELECT name, age FROM users WHERE age > 25 ORDER BY age DESC"]
)
results.each do |result|
  puts "Results:"
  puts result[:result]
end
puts

# Example 6: Create another table with foreign key
puts "6. Creating posts table with foreign key"
puts "-" * 40
results = database_tool.execute(
  statements: [
    "CREATE TABLE posts (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, title TEXT, body TEXT, FOREIGN KEY(user_id) REFERENCES users(id))"
  ]
)
results.each do |result|
  puts "Status: #{result[:status]}"
  puts "Result: #{result[:result]}"
end
puts

# Example 7: Insert related data
puts "7. Inserting posts"
puts "-" * 40
results = database_tool.execute(
  statements: [
    "INSERT INTO posts (user_id, title, body) VALUES (1, 'Hello World', 'My first post')",
    "INSERT INTO posts (user_id, title, body) VALUES (1, 'Ruby is Great', 'I love Ruby programming')",
    "INSERT INTO posts (user_id, title, body) VALUES (2, 'Database Tools', 'Working with SQLite')"
  ]
)
results.each do |result|
  puts "Result: #{result[:result]}"
end
puts

# Example 8: Join query
puts "8. Querying posts with user names (JOIN)"
puts "-" * 40
results = database_tool.execute(
  statements: [
    "SELECT users.name, posts.title FROM posts JOIN users ON posts.user_id = users.id"
  ]
)
results.each do |result|
  puts "Results:"
  puts result[:result]
end
puts

# Example 9: Transaction-like sequence (stops on error)
puts "9. Sequential execution (stops on first error)"
puts "-" * 40
puts "Attempting to insert valid and invalid data..."
results = database_tool.execute(
  statements: [
    "INSERT INTO users (name, email, age) VALUES ('David Brown', 'david@example.com', 35)",
    "INSERT INTO invalid_table (foo) VALUES ('bar')",  # This will fail
    "INSERT INTO users (name, email, age) VALUES ('Eve Wilson', 'eve@example.com', 32)"  # Should not execute
  ]
)

results.each_with_index do |result, i|
  puts "Statement #{i + 1}: #{result[:statement]}"
  puts "Status: #{result[:status]}"
  puts "Result: #{result[:result]}"
  puts
end

if results.size < 3
  puts "✓ Execution stopped after error (transaction-like behavior)"
end
puts

# Example 10: Count and aggregate
puts "10. Aggregate queries"
puts "-" * 40
results = database_tool.execute(
  statements: [
    "SELECT COUNT(*) as total_users FROM users",
    "SELECT AVG(age) as average_age FROM users",
    "SELECT name, COUNT(*) as post_count FROM users JOIN posts ON users.id = posts.user_id GROUP BY users.name"
  ]
)
results.each do |result|
  puts "Query: #{result[:statement]}"
  puts "Result: #{result[:result]}"
  puts
end

# Example 11: Delete data
puts "11. Deleting a user"
puts "-" * 40
results = database_tool.execute(
  statements: [
    "DELETE FROM posts WHERE user_id = 2",
    "DELETE FROM users WHERE id = 2"
  ]
)
results.each do |result|
  puts "Statement: #{result[:statement]}"
  puts "Result: #{result[:result]}"
end
puts

# Verify deletion
results = database_tool.execute(
  statements: ["SELECT name FROM users"]
)
puts "Remaining users:"
puts results.first[:result]
puts

# Example 12: Drop tables
puts "12. Cleaning up (dropping tables)"
puts "-" * 40
results = database_tool.execute(
  statements: [
    "DROP TABLE posts",
    "DROP TABLE users"
  ]
)
results.each do |result|
  puts "Status: #{result[:status]}"
  puts "Result: #{result[:result]}"
end
puts

# Close database connection
db.close
puts "Database connection closed."
puts
puts "=" * 80
puts "Example completed successfully!"
puts "=" * 80
