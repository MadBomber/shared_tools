# Basic Usage

Learn the fundamental patterns for using SharedTools effectively.

## Tool Architecture

All SharedTools follow a consistent pattern:

1. **Inherit from RubyLLM::Tool** - Compatible with RubyLLM framework
2. **Facade pattern** - Single tool, multiple actions
3. **Driver-based** - Pluggable implementations
4. **Authorization-aware** - Safety controls built-in

## Tool Lifecycle

### Basic Pattern

```ruby
# 1. Initialize tool
tool = SharedTools::Tools::SomeTool.new

# 2. Execute actions
result = tool.execute(action: "some_action", param: "value")

# 3. Clean up (if needed)
tool.cleanup! if tool.respond_to?(:cleanup!)
```

### With Custom Configuration

```ruby
# Initialize with custom logger
require 'logger'

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

tool = SharedTools::Tools::SomeTool.new(logger: logger)
```

### With Custom Driver

```ruby
# Use custom driver implementation
driver = MyCustomDriver.new(config: options)
tool = SharedTools::Tools::SomeTool.new(driver: driver)
```

## Common Patterns

### Pattern 1: File Operations with Safety

```ruby
require 'shared_tools'
require 'tmpdir'

# Create sandboxed disk tool
Dir.mktmpdir do |tmpdir|
  disk = SharedTools::Tools::DiskTool.new(
    driver: SharedTools::Tools::Disk::LocalDriver.new(root: tmpdir)
  )

  # All operations are restricted to tmpdir
  disk.execute(action: "file_create", path: "./data.txt")
  disk.execute(action: "file_write", path: "./data.txt", text: "content")

  # This would raise SecurityError (path traversal attempt)
  begin
    disk.execute(action: "file_read", path: "../../etc/passwd")
  rescue SecurityError => e
    puts "Security check passed: #{e.message}"
  end
end
```

### Pattern 2: Browser Automation with Error Handling

```ruby
browser = SharedTools::Tools::BrowserTool.new

begin
  # Navigate to page
  browser.execute(action: "visit", url: "https://example.com/login")

  # Wait and check if element exists
  elements = browser.execute(
    action: "ui_inspect",
    text_content: "Sign In"
  )

  if elements.empty?
    puts "Login button not found"
  else
    # Fill form
    browser.execute(
      action: "text_field_set",
      selector: "#username",
      value: "user@example.com"
    )

    browser.execute(
      action: "text_field_set",
      selector: "#password",
      value: "password123"
    )

    # Submit
    browser.execute(
      action: "click",
      selector: "button[type='submit']"
    )
  end
rescue StandardError => e
  puts "Browser error: #{e.message}"
ensure
  browser.cleanup!
end
```

### Pattern 3: Database Operations with Transactions

```ruby
require 'sqlite3'

db = SQLite3::Database.new(':memory:')
driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)

# Execute multiple statements
# Stops on first error
results = database.execute(
  statements: [
    "CREATE TABLE products (id INTEGER PRIMARY KEY, name TEXT, price REAL)",
    "INSERT INTO products (name, price) VALUES ('Widget', 9.99)",
    "INSERT INTO products (name, price) VALUES ('Gadget', 19.99)",
    "SELECT * FROM products WHERE price > 10.0"
  ]
)

# Check each result
results.each do |result|
  if result[:status] == :ok
    puts "Success: #{result[:statement]}"
    puts "Result: #{result[:result]}"
  else
    puts "Error: #{result[:statement]}"
    puts "Message: #{result[:result]}"
  end
end
```

### Pattern 4: Code Evaluation with Authorization

```ruby
eval_tool = SharedTools::Tools::EvalTool.new

# For interactive scripts, leave authorization enabled
# User will be prompted before execution
result = eval_tool.execute(
  action: "shell",
  command: "ls -la /tmp"
)

# For automated scripts, disable authorization
SharedTools.auto_execute(true)

result = eval_tool.execute(
  action: "ruby",
  code: "Time.now.to_i"
)

# Re-enable authorization for safety
SharedTools.auto_execute(false)
```

### Pattern 5: Multi-Tool Workflows

```ruby
# Web scraping to database workflow
browser = SharedTools::Tools::BrowserTool.new
disk = SharedTools::Tools::DiskTool.new
eval_tool = SharedTools::Tools::EvalTool.new

begin
  # 1. Scrape data
  browser.execute(action: "visit", url: "https://example.com/data")
  html = browser.execute(action: "page_inspect", full_html: true)

  # 2. Parse with Ruby
  parsed_data = eval_tool.execute(
    action: "ruby",
    code: <<~RUBY
      require 'nokogiri'
      doc = Nokogiri::HTML('#{html}')
      doc.css('.data-item').map { |item| item.text.strip }
    RUBY
  )

  # 3. Save to file
  disk.execute(action: "file_create", path: "./scraped_data.txt")
  disk.execute(
    action: "file_write",
    path: "./scraped_data.txt",
    text: parsed_data.to_s
  )

  puts "Data saved successfully!"
ensure
  browser.cleanup!
end
```

## Action-Based Interface

All tools use an action-based interface where you specify the action and its parameters:

```ruby
tool.execute(
  action: "action_name",
  param1: "value1",
  param2: "value2"
)
```

### DiskTool Actions

```ruby
disk = SharedTools::Tools::DiskTool.new

# Directory operations
disk.execute(action: "directory_create", path: "./mydir")
disk.execute(action: "directory_list", path: "./mydir")
disk.execute(action: "directory_move", path: "./mydir", destination: "./newdir")
disk.execute(action: "directory_delete", path: "./newdir")

# File operations
disk.execute(action: "file_create", path: "./file.txt")
disk.execute(action: "file_write", path: "./file.txt", text: "content")
disk.execute(action: "file_read", path: "./file.txt")
disk.execute(action: "file_replace", path: "./file.txt", old_text: "old", new_text: "new")
disk.execute(action: "file_move", path: "./file.txt", destination: "./moved.txt")
disk.execute(action: "file_delete", path: "./moved.txt")
```

### BrowserTool Actions

```ruby
browser = SharedTools::Tools::BrowserTool.new

browser.execute(action: "visit", url: "https://example.com")
browser.execute(action: "page_inspect")  # Summary
browser.execute(action: "page_inspect", full_html: true)  # Full HTML
browser.execute(action: "ui_inspect", text_content: "Search")
browser.execute(action: "selector_inspect", selector: ".nav-item")
browser.execute(action: "click", selector: "button.submit")
browser.execute(action: "text_field_set", selector: "#search", value: "query")
browser.execute(action: "screenshot")
```

### EvalTool Actions

```ruby
eval_tool = SharedTools::Tools::EvalTool.new

eval_tool.execute(action: "ruby", code: "1 + 1")
eval_tool.execute(action: "python", code: "print('Hello')")
eval_tool.execute(action: "shell", command: "echo 'Hello'")
```

### DocTool Actions

```ruby
doc = SharedTools::Tools::DocTool.new

doc.execute(action: "pdf_read", doc_path: "./file.pdf", page_numbers: "1")
doc.execute(action: "pdf_read", doc_path: "./file.pdf", page_numbers: "1-5")
doc.execute(action: "pdf_read", doc_path: "./file.pdf", page_numbers: "1, 3, 5-10")
```

## Logging

All tools support custom loggers:

```ruby
require 'logger'

# Create custom logger
logger = Logger.new(STDOUT)
logger.level = Logger::INFO
logger.formatter = proc { |severity, datetime, progname, msg|
  "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} [#{severity}] #{msg}\n"
}

# Use with tools
disk = SharedTools::Tools::DiskTool.new(logger: logger)
disk.execute(action: "file_read", path: "./test.txt")
# Output: 2025-10-25 10:30:00 [INFO] action="file_read" path="./test.txt"
```

## Error Handling

Tools raise standard Ruby exceptions:

```ruby
disk = SharedTools::Tools::DiskTool.new

# Handle file not found
begin
  disk.execute(action: "file_read", path: "./missing.txt")
rescue Errno::ENOENT => e
  puts "File not found: #{e.message}"
end

# Handle security errors
begin
  disk.execute(action: "file_read", path: "../../../etc/passwd")
rescue SecurityError => e
  puts "Security violation: #{e.message}"
end

# Handle parameter errors
begin
  disk.execute(action: "file_write", path: "./test.txt")  # Missing 'text'
rescue ArgumentError => e
  puts "Invalid arguments: #{e.message}"
end
```

## Best Practices

### 1. Always Clean Up Resources

```ruby
browser = SharedTools::Tools::BrowserTool.new
begin
  # Do work...
ensure
  browser.cleanup!  # Always close browser
end
```

### 2. Use Sandboxed Directories

```ruby
require 'tmpdir'

# Operations are restricted to tmpdir
Dir.mktmpdir do |tmpdir|
  disk = SharedTools::Tools::DiskTool.new(
    driver: SharedTools::Tools::Disk::LocalDriver.new(root: tmpdir)
  )
  # Safe operations here
end
```

### 3. Enable Authorization for Interactive Scripts

```ruby
# Keep authorization enabled
# SharedTools.auto_execute(false)  # This is the default

# User will approve each dangerous operation
eval_tool.execute(action: "shell", command: "rm file.txt")
```

### 4. Validate Inputs

```ruby
# Check file exists before reading
if File.exist?(path)
  content = disk.execute(action: "file_read", path: path)
else
  puts "File not found: #{path}"
end
```

### 5. Use Structured Logging

```ruby
logger = Logger.new(STDOUT)
logger.level = Logger::INFO

disk = SharedTools::Tools::DiskTool.new(logger: logger)
# Operations are automatically logged with context
```

## Next Steps

- [Tools Overview](../tools/index.md) - Explore all available tools
- [Authorization Guide](../guides/authorization.md) - Master the authorization system
- [Working with Drivers](../guides/drivers.md) - Create custom drivers
- [Examples](https://github.com/madbomber/shared_tools/tree/main/examples) - View complete examples
