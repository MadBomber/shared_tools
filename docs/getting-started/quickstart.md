# Quickstart Guide

Get up and running with SharedTools in 5 minutes.

## Installation

```bash
gem install shared_tools
```

## Your First Script

Create a file called `hello_tools.rb`:

```ruby
#!/usr/bin/env ruby
require 'shared_tools'

# 1. File Operations
puts "=== File Operations ==="
disk = SharedTools::Tools::DiskTool.new

# Create and write a file
disk.execute(action: "file_create", path: "./hello.txt")
disk.execute(
  action: "file_write",
  path: "./hello.txt",
  text: "Hello from SharedTools!"
)

# Read it back
content = disk.execute(action: "file_read", path: "./hello.txt")
puts "File contents: #{content}"

# Clean up
disk.execute(action: "file_delete", path: "./hello.txt")
puts "File deleted!"
```

Run it:

```bash
ruby hello_tools.rb
```

## Tool Examples

### DiskTool - File Management

```ruby
disk = SharedTools::Tools::DiskTool.new

# Create directory
disk.execute(action: "directory_create", path: "./my_project")

# List contents
listing = disk.execute(action: "directory_list", path: ".")
puts listing

# Move file
disk.execute(
  action: "file_move",
  path: "./old.txt",
  destination: "./my_project/new.txt"
)
```

### EvalTool - Code Execution

```ruby
eval_tool = SharedTools::Tools::EvalTool.new

# Execute Ruby
result = eval_tool.execute(
  action: "ruby",
  code: "[1, 2, 3, 4, 5].sum"
)
puts "Sum: #{result}"  # => 15

# Execute Python
result = eval_tool.execute(
  action: "python",
  code: "print('Hello from Python')"
)

# Execute shell command
result = eval_tool.execute(
  action: "shell",
  command: "ls -la"
)
```

### DocTool - PDF Reading

```ruby
doc = SharedTools::Tools::DocTool.new

# Read specific pages
result = doc.execute(
  action: "pdf_read",
  doc_path: "./document.pdf",
  page_numbers: "1, 3-5"
)

puts result[:pages]  # Array of page content
```

### BrowserTool - Web Automation

!!!note "Requires watir gem"
    Install with: `gem install watir`

```ruby
browser = SharedTools::Tools::BrowserTool.new

# Visit website
browser.execute(
  action: "visit",
  url: "https://example.com"
)

# Find button by text
elements = browser.execute(
  action: "ui_inspect",
  text_content: "Login"
)

# Click using selector
browser.execute(
  action: "click",
  selector: "button[type='submit']"
)

# Take screenshot
screenshot_data = browser.execute(action: "screenshot")

# Clean up
browser.cleanup!
```

### DatabaseTool - SQL Operations

!!!note "Requires database gem"
    Install with: `gem install sqlite3` or `gem install pg`

```ruby
require 'sqlite3'

# Initialize database and driver
db = SQLite3::Database.new(':memory:')
driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)

# Execute SQL statements
results = database.execute(
  statements: [
    "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)",
    "INSERT INTO users (name) VALUES ('Alice')",
    "INSERT INTO users (name) VALUES ('Bob')",
    "SELECT * FROM users"
  ]
)

# Check results
results.each do |result|
  puts "Status: #{result[:status]}"
  puts "Result: #{result[:result]}"
end
```

## Authorization System

By default, SharedTools requires confirmation for potentially dangerous operations:

```ruby
# This will prompt the user
eval_tool = SharedTools::Tools::EvalTool.new
eval_tool.execute(action: "shell", command: "rm important_file.txt")
# Output:
# The AI (tool: eval_tool) wants to do the following ...
# ==========================================
# rm important_file.txt
# ==========================================
# Is it okay to proceed? (y/N)
```

Disable authorization for automated scripts:

```ruby
# Enable auto-execute mode (use with caution!)
SharedTools.auto_execute(true)

# Now operations run without confirmation
eval_tool.execute(action: "shell", command: "echo 'No prompt!'")
```

## Complete Example

Here's a practical example that combines multiple tools:

```ruby
#!/usr/bin/env ruby
require 'shared_tools'

# Create a simple data processor
disk = SharedTools::Tools::DiskTool.new
eval_tool = SharedTools::Tools::EvalTool.new

# 1. Create data file
disk.execute(action: "file_create", path: "./numbers.txt")
disk.execute(
  action: "file_write",
  path: "./numbers.txt",
  text: "1\n2\n3\n4\n5\n"
)

# 2. Read and process data
content = disk.execute(action: "file_read", path: "./numbers.txt")

# 3. Calculate sum using Ruby
result = eval_tool.execute(
  action: "ruby",
  code: "'#{content}'.split.map(&:to_i).sum"
)

puts "Sum of numbers: #{result}"

# 4. Save result
disk.execute(
  action: "file_write",
  path: "./result.txt",
  text: "The sum is: #{result}"
)

# 5. Clean up
disk.execute(action: "file_delete", path: "./numbers.txt")
disk.execute(action: "file_delete", path: "./result.txt")

puts "Done!"
```

## Next Steps

- [Basic Usage](basic-usage.md) - Learn more patterns and best practices
- [Tools Documentation](../tools/index.md) - Detailed reference for each tool
- [Authorization Guide](../guides/authorization.md) - Control operation approval
- [Working with Drivers](../guides/drivers.md) - Extend tools with custom drivers

## Common Patterns

### Error Handling

```ruby
begin
  disk.execute(action: "file_read", path: "./missing.txt")
rescue Errno::ENOENT => e
  puts "File not found: #{e.message}"
end
```

### Resource Cleanup

```ruby
# Always clean up browser resources
browser = SharedTools::Tools::BrowserTool.new
begin
  browser.execute(action: "visit", url: "https://example.com")
  # ... do work ...
ensure
  browser.cleanup!
end
```

### Working with Temporary Directories

```ruby
require 'tmpdir'

Dir.mktmpdir do |tmpdir|
  disk = SharedTools::Tools::DiskTool.new(
    driver: SharedTools::Tools::Disk::LocalDriver.new(root: tmpdir)
  )

  # All operations are sandboxed to tmpdir
  disk.execute(action: "file_create", path: "./test.txt")

  # tmpdir is automatically cleaned up
end
```
