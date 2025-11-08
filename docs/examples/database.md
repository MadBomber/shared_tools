# Database Tool Example

The DatabaseTool provides a unified interface for executing SQL operations on databases. This example demonstrates using SQLite3, but the tool supports any database with an appropriate driver.

## Overview

This example demonstrates how to use the DatabaseTool to execute SQL statements. It uses SQLite3 as the database backend and shows how to create tables, insert data, query, update, and delete records.

## Example Code

View the complete example: [database_tool_example.rb](https://github.com/madbomber/shared_tools/blob/main/examples/database_tool_example.rb)

## Requirements

This example requires the `sqlite3` gem:

```bash
gem install sqlite3
```

## Key Features

### 1. Creating a Database Driver

First, create a driver that implements the `BaseDriver` interface:

```ruby
class SimpleSqliteDriver < SharedTools::Tools::Database::BaseDriver
  def initialize(db:)
    @db = db
  end

  def perform(statement:)
    # Execute query or command
    # Return structured result
  end
end

# Create database connection
db = SQLite3::Database.new(':memory:')
driver = SimpleSqliteDriver.new(db: db)
database_tool = SharedTools::Tools::DatabaseTool.new(driver: driver)
```

### 2. Creating Tables

```ruby
results = database_tool.execute(
  statements: [
    "CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT NOT NULL,
      age INTEGER
    )"
  ]
)

results.each do |result|
  puts "Status: #{result[:status]}"
  puts "Result: #{result[:result]}"
end
```

### 3. Inserting Data

Execute multiple INSERT statements:

```ruby
results = database_tool.execute(
  statements: [
    "INSERT INTO users (name, email, age) VALUES ('Alice Smith', 'alice@example.com', 30)",
    "INSERT INTO users (name, email, age) VALUES ('Bob Johnson', 'bob@example.com', 25)",
    "INSERT INTO users (name, email, age) VALUES ('Carol White', 'carol@example.com', 28)"
  ]
)

results.each do |result|
  puts "Statement: #{result[:statement]}"
  puts "Result: #{result[:result]}"
end
```

### 4. Querying Data

```ruby
results = database_tool.execute(
  statements: ["SELECT * FROM users"]
)

results.each do |result|
  puts "Results:"
  puts result[:result]
end
```

With WHERE clause:

```ruby
results = database_tool.execute(
  statements: [
    "SELECT name, age FROM users WHERE age > 25 ORDER BY age DESC"
  ]
)
```

### 5. Updating Data

```ruby
results = database_tool.execute(
  statements: [
    "UPDATE users SET age = 31 WHERE name = 'Alice Smith'"
  ]
)

puts "Result: #{results.first[:result]}"
# Output: Command executed successfully (1 rows affected)
```

### 6. Foreign Keys and Relations

Create tables with foreign keys:

```ruby
results = database_tool.execute(
  statements: [
    "CREATE TABLE posts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      title TEXT,
      body TEXT,
      FOREIGN KEY(user_id) REFERENCES users(id)
    )"
  ]
)
```

### 7. JOIN Queries

Query with joins:

```ruby
results = database_tool.execute(
  statements: [
    "SELECT users.name, posts.title
     FROM posts
     JOIN users ON posts.user_id = users.id"
  ]
)
```

### 8. Aggregate Functions

```ruby
results = database_tool.execute(
  statements: [
    "SELECT COUNT(*) as total_users FROM users",
    "SELECT AVG(age) as average_age FROM users",
    "SELECT name, COUNT(*) as post_count
     FROM users
     JOIN posts ON users.id = posts.user_id
     GROUP BY users.name"
  ]
)
```

### 9. Deleting Data

```ruby
results = database_tool.execute(
  statements: [
    "DELETE FROM posts WHERE user_id = 2",
    "DELETE FROM users WHERE id = 2"
  ]
)
```

### 10. Dropping Tables

```ruby
results = database_tool.execute(
  statements: [
    "DROP TABLE posts",
    "DROP TABLE users"
  ]
)
```

## Sequential Execution with Error Handling

The tool stops execution on the first error (transaction-like behavior):

```ruby
results = database_tool.execute(
  statements: [
    "INSERT INTO users (name, email, age) VALUES ('David Brown', 'david@example.com', 35)",
    "INSERT INTO invalid_table (foo) VALUES ('bar')",  # This will fail
    "INSERT INTO users (name, email, age) VALUES ('Eve Wilson', 'eve@example.com', 32)"  # Won't execute
  ]
)

# Only the first statement executed
puts "Executed: #{results.size} statements"  # 2 (success + failure)
```

## Result Structure

Each statement returns a result hash:

```ruby
{
  statement: <SQL statement>,
  status: :ok or :error,
  result: <result data or error message>
}
```

For queries:
```ruby
{
  status: :ok,
  result: "id | name | email
           1 | Alice Smith | alice@example.com
           2 | Bob Johnson | bob@example.com"
}
```

For commands:
```ruby
{
  status: :ok,
  result: "Command executed successfully (1 rows affected)"
}
```

For errors:
```ruby
{
  status: :error,
  result: "no such table: invalid_table"
}
```

## Creating Custom Drivers

To support other databases, create a driver that extends `BaseDriver`:

```ruby
class MyDatabaseDriver < SharedTools::Tools::Database::BaseDriver
  def initialize(connection:)
    @connection = connection
  end

  def perform(statement:)
    # Your implementation here
    # Must return hash with :status and :result keys
    {
      status: :ok,
      result: "Your result"
    }
  rescue => e
    {
      status: :error,
      result: e.message
    }
  end
end
```

## Run the Example

```bash
cd examples
bundle exec ruby database_tool_example.rb
```

The example creates an in-memory SQLite database, performs various operations, and demonstrates the tool's capabilities.

## Related Documentation

- [DatabaseTool Documentation](../tools/database.md)
- [Facade Pattern](../api/facade-pattern.md)
- [Driver Interface](../api/driver-interface.md)
- [Architecture Guide](../development/architecture.md)

## Supported Databases

With appropriate drivers, DatabaseTool can work with:

- SQLite3
- PostgreSQL
- MySQL/MariaDB
- SQL Server
- Any database with a Ruby adapter

## Key Takeaways

- DatabaseTool provides a unified interface for SQL operations
- Supports multiple database backends via the driver pattern
- Executes multiple statements sequentially
- Stops on first error (transaction-like behavior)
- Returns structured results for each statement
- Graceful error handling with descriptive messages
- Works with any database that has a Ruby adapter

## Security Notes

- Always use parameterized queries in production
- Validate and sanitize user input
- Use connection pooling for better performance
- Consider using transactions for multiple related operations
- Implement proper error handling and logging
- Follow database-specific best practices

## Use Cases

- Database migrations and schema management
- Data import/export operations
- Automated testing with database fixtures
- Administrative tasks and maintenance
- Data analysis and reporting
- Building database utilities and tools
- LLM-powered database interactions
