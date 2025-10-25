# DatabaseTool

Execute SQL statements against SQLite or PostgreSQL databases with a pluggable driver architecture.

## Installation

DatabaseTool is included with SharedTools, but requires a database gem:

```ruby
# For SQLite
gem 'sqlite3'

# For PostgreSQL
gem 'pg'
```

## Basic Usage

```ruby
require 'shared_tools'
require 'sqlite3'

# Create database and driver
db = SQLite3::Database.new(':memory:')
driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)

# Initialize tool
database = SharedTools::Tools::DatabaseTool.new(driver: driver)

# Execute SQL statements
results = database.execute(
  statements: [
    "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)",
    "INSERT INTO users (name) VALUES ('Alice')",
    "SELECT * FROM users"
  ]
)

# Check results
results.each do |result|
  puts "Status: #{result[:status]}"
  puts "Result: #{result[:result]}"
end
```

## Execution Model

DatabaseTool executes statements sequentially and **stops on the first error**:

```ruby
results = database.execute(
  statements: [
    "CREATE TABLE items (id INTEGER PRIMARY KEY)",  # Succeeds
    "INSERT INTO items VALUES (1)",                  # Succeeds
    "INSERT INTO invalid_table VALUES (2)",          # Fails - stops here
    "SELECT * FROM items"                            # Not executed
  ]
)

# results contains only the first 3 statements (2 success, 1 error)
```

## Actions

### execute

Execute one or more SQL statements sequentially.

**Parameters:**

- `statements`: Array of SQL statement strings

**Return Value:**

Array of hashes with:
- `status`: `:ok` or `:error`
- `statement`: The SQL statement executed
- `result`: Query results or error message

**Examples:**

```ruby
# Single statement
results = database.execute(
  statements: ["SELECT * FROM users"]
)

# Multiple statements
results = database.execute(
  statements: [
    "CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT, price REAL)",
    "INSERT INTO products (name, price) VALUES ('Widget', 9.99)",
    "INSERT INTO products (name, price) VALUES ('Gadget', 19.99)",
    "SELECT * FROM products"
  ]
)

# Process results
results.each do |result|
  if result[:status] == :ok
    puts "✓ #{result[:statement]}"
    puts "  Result: #{result[:result]}"
  else
    puts "✗ #{result[:statement]}"
    puts "  Error: #{result[:result]}"
  end
end
```

## Database Drivers

### SQLite Driver

```ruby
require 'sqlite3'

# In-memory database
db = SQLite3::Database.new(':memory:')

# File-based database
db = SQLite3::Database.new('./app.db')

# Create driver
driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)
```

### PostgreSQL Driver

```ruby
require 'pg'

# Connect to PostgreSQL
conn = PG.connect(
  host: 'localhost',
  port: 5432,
  dbname: 'myapp',
  user: 'postgres',
  password: 'password'
)

# Create driver
driver = SharedTools::Tools::Database::PostgresDriver.new(db: conn)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)
```

## Complete Examples

### Example 1: User Management

```ruby
require 'shared_tools'
require 'sqlite3'

# Setup
db = SQLite3::Database.new(':memory:')
driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)

# Create schema
database.execute(
  statements: [
    <<~SQL
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    SQL
  ]
)

# Insert users
database.execute(
  statements: [
    "INSERT INTO users (username, email) VALUES ('alice', 'alice@example.com')",
    "INSERT INTO users (username, email) VALUES ('bob', 'bob@example.com')",
    "INSERT INTO users (username, email) VALUES ('charlie', 'charlie@example.com')"
  ]
)

# Query users
results = database.execute(
  statements: ["SELECT id, username, email FROM users ORDER BY username"]
)

puts "Users:"
results.first[:result].each do |row|
  puts "  #{row[0]}: #{row[1]} (#{row[2]})"
end

# Update user
database.execute(
  statements: [
    "UPDATE users SET email = 'alice.new@example.com' WHERE username = 'alice'"
  ]
)

# Delete user
database.execute(
  statements: [
    "DELETE FROM users WHERE username = 'charlie'"
  ]
)
```

### Example 2: E-commerce Database

```ruby
require 'shared_tools'
require 'sqlite3'

db = SQLite3::Database.new('./shop.db')
driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)

# Create schema
database.execute(
  statements: [
    <<~SQL,
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        stock INTEGER DEFAULT 0
      )
    SQL
    <<~SQL,
      CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        quantity INTEGER,
        total REAL,
        order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    SQL
  ]
)

# Add products
database.execute(
  statements: [
    "INSERT INTO products (name, description, price, stock) VALUES ('Laptop', 'High-performance laptop', 1299.99, 10)",
    "INSERT INTO products (name, description, price, stock) VALUES ('Mouse', 'Wireless mouse', 29.99, 50)",
    "INSERT INTO products (name, description, price, stock) VALUES ('Keyboard', 'Mechanical keyboard', 89.99, 30)"
  ]
)

# Create order
product_id = 1
quantity = 2
price = 1299.99

database.execute(
  statements: [
    "INSERT INTO orders (product_id, quantity, total) VALUES (#{product_id}, #{quantity}, #{price * quantity})",
    "UPDATE products SET stock = stock - #{quantity} WHERE id = #{product_id}"
  ]
)

# Generate sales report
results = database.execute(
  statements: [
    <<~SQL
      SELECT
        p.name,
        SUM(o.quantity) as total_sold,
        SUM(o.total) as revenue
      FROM orders o
      JOIN products p ON o.product_id = p.id
      GROUP BY p.name
      ORDER BY revenue DESC
    SQL
  ]
)

puts "Sales Report:"
results.first[:result].each do |row|
  puts "  #{row[0]}: #{row[1]} sold, $#{row[2]} revenue"
end
```

### Example 3: Data Migration

```ruby
require 'shared_tools'
require 'sqlite3'

# Source database
source_db = SQLite3::Database.new('./source.db')
source_driver = SharedTools::Tools::Database::SqliteDriver.new(db: source_db)
source = SharedTools::Tools::DatabaseTool.new(driver: source_driver)

# Destination database
dest_db = SQLite3::Database.new('./destination.db')
dest_driver = SharedTools::Tools::Database::SqliteDriver.new(db: dest_db)
destination = SharedTools::Tools::DatabaseTool.new(driver: dest_driver)

# Create destination schema
destination.execute(
  statements: [
    <<~SQL
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        name TEXT,
        email TEXT
      )
    SQL
  ]
)

# Read from source
results = source.execute(
  statements: ["SELECT id, name, email FROM users"]
)

# Migrate data
if results.first[:status] == :ok
  users = results.first[:result]

  insert_statements = users.map do |user|
    "INSERT INTO users (id, name, email) VALUES (#{user[0]}, '#{user[1]}', '#{user[2]}')"
  end

  destination.execute(statements: insert_statements)
  puts "Migrated #{users.size} users"
end

source_db.close
dest_db.close
```

### Example 4: Query Builder Pattern

```ruby
require 'shared_tools'
require 'sqlite3'

db = SQLite3::Database.new(':memory:')
driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)

# Setup
database.execute(
  statements: [
    "CREATE TABLE logs (id INTEGER PRIMARY KEY, level TEXT, message TEXT, timestamp DATETIME)"
  ]
)

# Helper method to build queries
def build_insert(table, data)
  columns = data.keys.join(', ')
  values = data.values.map { |v| "'#{v}'" }.join(', ')
  "INSERT INTO #{table} (#{columns}) VALUES (#{values})"
end

# Insert logs using builder
logs = [
  { level: 'INFO', message: 'App started', timestamp: Time.now },
  { level: 'ERROR', message: 'Connection failed', timestamp: Time.now },
  { level: 'INFO', message: 'Request processed', timestamp: Time.now }
]

statements = logs.map { |log| build_insert('logs', log) }
database.execute(statements: statements)

# Query with filters
def build_select(table, where: {}, order_by: nil)
  sql = "SELECT * FROM #{table}"

  if where.any?
    conditions = where.map { |k, v| "#{k} = '#{v}'" }.join(' AND ')
    sql += " WHERE #{conditions}"
  end

  sql += " ORDER BY #{order_by}" if order_by

  sql
end

# Get errors
results = database.execute(
  statements: [
    build_select('logs', where: { level: 'ERROR' })
  ]
)

puts "Errors found:"
results.first[:result].each do |row|
  puts "  #{row[3]}: #{row[2]}"
end
```

### Example 5: Transaction-Like Behavior

```ruby
require 'shared_tools'
require 'sqlite3'

db = SQLite3::Database.new(':memory:')
driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)

# Setup
database.execute(
  statements: [
    "CREATE TABLE accounts (id INTEGER PRIMARY KEY, name TEXT, balance REAL)"
  ]
)

database.execute(
  statements: [
    "INSERT INTO accounts (id, name, balance) VALUES (1, 'Alice', 1000.0)",
    "INSERT INTO accounts (id, name, balance) VALUES (2, 'Bob', 500.0)"
  ]
)

# Transfer money (stops on first error)
transfer_amount = 100

results = database.execute(
  statements: [
    "UPDATE accounts SET balance = balance - #{transfer_amount} WHERE id = 1",
    "UPDATE accounts SET balance = balance + #{transfer_amount} WHERE id = 2",
    "SELECT name, balance FROM accounts ORDER BY id"
  ]
)

# Check if all succeeded
if results.all? { |r| r[:status] == :ok }
  puts "Transfer successful!"
  results.last[:result].each do |row|
    puts "  #{row[0]}: $#{row[1]}"
  end
else
  puts "Transfer failed - database unchanged"
end
```

## Error Handling

```ruby
database = SharedTools::Tools::DatabaseTool.new(driver: driver)

# Handle SQL errors
results = database.execute(
  statements: [
    "CREATE TABLE users (id INTEGER PRIMARY KEY)",
    "INSERT INTO users VALUES (1)",
    "INSERT INTO invalid_table VALUES (2)"  # This will fail
  ]
)

# Check results
results.each_with_index do |result, i|
  if result[:status] == :error
    puts "Statement #{i + 1} failed: #{result[:result]}"
    break  # No more statements were executed after this
  end
end

# Handle connection errors
begin
  db = SQLite3::Database.new('/invalid/path/db.sqlite')
rescue SQLite3::CantOpenException => e
  puts "Database connection failed: #{e.message}"
end
```

## Best Practices

### 1. Use Parameterized Queries

```ruby
# BAD: SQL injection vulnerability
user_input = "'; DROP TABLE users; --"
database.execute(
  statements: ["SELECT * FROM users WHERE name = '#{user_input}'"]
)

# GOOD: Use parameterized queries (implementation depends on driver)
# For now, sanitize inputs
def sanitize(input)
  input.gsub("'", "''")
end

safe_input = sanitize(user_input)
database.execute(
  statements: ["SELECT * FROM users WHERE name = '#{safe_input}'"]
)
```

### 2. Check Results

```ruby
results = database.execute(statements: statements)

if results.all? { |r| r[:status] == :ok }
  puts "All statements succeeded"
else
  failed = results.find { |r| r[:status] == :error }
  puts "Failed: #{failed[:statement]}"
  puts "Error: #{failed[:result]}"
end
```

### 3. Close Connections

```ruby
db = SQLite3::Database.new('./app.db')
driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)

begin
  # Use database...
ensure
  db.close  # Always close connection
end
```

### 4. Use Batch Inserts

```ruby
# For large datasets, batch inserts
users = (1..1000).map { |i| { name: "User#{i}", email: "user#{i}@example.com" } }

# Insert in batches of 100
users.each_slice(100) do |batch|
  statements = batch.map do |user|
    "INSERT INTO users (name, email) VALUES ('#{user[:name]}', '#{user[:email]}')"
  end

  database.execute(statements: statements)
end
```

## Custom Driver

Create a custom driver for other databases:

```ruby
class MySqlDriver < SharedTools::Tools::Database::BaseDriver
  def initialize(db:)
    @db = db
  end

  def perform(statement:)
    if statement =~ /^\s*SELECT/i
      results = @db.query(statement)
      { status: :ok, result: results.to_a }
    else
      @db.query(statement)
      { status: :ok, result: "Success (#{@db.affected_rows} rows)" }
    end
  rescue => e
    { status: :error, result: e.message }
  end
end

# Use custom driver
mysql = Mysql2::Client.new(host: "localhost", username: "root")
driver = MySqlDriver.new(db: mysql)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)
```

## See Also

- [Basic Usage](../getting-started/basic-usage.md) - Common patterns
- [Working with Drivers](../guides/drivers.md) - Custom driver implementation
- [Examples](https://github.com/madbomber/shared_tools/tree/main/examples/database_tool_example.rb)
