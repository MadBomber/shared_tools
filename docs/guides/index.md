# Guides

In-depth guides for advanced SharedTools usage.

## Available Guides

### [Authorization System](authorization.md)

Learn how to control when operations require user approval.

**Topics Covered:**

- Understanding the authorization system
- Default behavior (human-in-the-loop)
- Disabling authorization for automation
- Best practices for security
- Custom authorization logic

**Example:**

```ruby
# Require approval for dangerous operations
eval_tool.execute(action: "shell", command: "rm file.txt")
# Prompts: "Is it okay to proceed? (y/N)"

# Disable for automation
SharedTools.auto_execute(true)
```

[Read Authorization Guide →](authorization.md)

---

### [Working with Drivers](drivers.md)

Understand the driver architecture and create custom implementations.

**Topics Covered:**

- Driver architecture overview
- Built-in drivers
- Creating custom drivers
- Driver interfaces
- Testing drivers

**Example:**

```ruby
# Custom disk driver for cloud storage
class S3Driver < SharedTools::Tools::Disk::BaseDriver
  def file_read(path:)
    @bucket.object(path).get.body.read
  end
  # ... implement other methods
end

disk = SharedTools::Tools::DiskTool.new(driver: S3Driver.new)
```

[Read Drivers Guide →](drivers.md)

---

## Quick Links

### Getting Started

- [Installation](../getting-started/installation.md)
- [Quickstart](../getting-started/quickstart.md)
- [Basic Usage](../getting-started/basic-usage.md)

### Tools

- [Tools Overview](../tools/index.md)
- [BrowserTool](../tools/browser.md)
- [DiskTool](../tools/disk.md)
- [EvalTool](../tools/eval.md)
- [DocTool](../tools/doc.md)
- [DatabaseTool](../tools/database.md)

## Common Patterns

### Multi-Tool Workflows

Combine multiple tools for complex operations:

```ruby
# Web scraping to database pipeline
browser = SharedTools::Tools::BrowserTool.new
disk = SharedTools::Tools::DiskTool.new
database = SharedTools::Tools::DatabaseTool.new(driver: driver)

# 1. Scrape data
browser.execute(action: "visit", url: "https://example.com/data")
html = browser.execute(action: "page_inspect", full_html: true)

# 2. Save raw data
disk.execute(action: "file_write", path: "./raw.html", text: html)

# 3. Store in database
database.execute(statements: ["INSERT INTO pages (html) VALUES ('#{html}')"])

browser.cleanup!
```

### Error Recovery

Implement robust error handling:

```ruby
MAX_RETRIES = 3

def execute_with_retry(tool, action, **params)
  retries = 0

  begin
    tool.execute(action: action, **params)
  rescue StandardError => e
    retries += 1
    if retries < MAX_RETRIES
      sleep 2 ** retries  # Exponential backoff
      retry
    else
      raise
    end
  end
end
```

### Resource Management

Use ensure blocks for cleanup:

```ruby
browser = SharedTools::Tools::BrowserTool.new

begin
  browser.execute(action: "visit", url: url)
  # Do work...
rescue StandardError => e
  puts "Error: #{e.message}"
ensure
  browser.cleanup!  # Always clean up
end
```

### Configuration Management

Store tool configuration:

```ruby
class ToolConfig
  def self.disk_tool(root: Dir.pwd)
    driver = SharedTools::Tools::Disk::LocalDriver.new(root: root)
    SharedTools::Tools::DiskTool.new(driver: driver)
  end

  def self.browser_tool
    SharedTools::Tools::BrowserTool.new
  end

  def self.database_tool(db_path:)
    db = SQLite3::Database.new(db_path)
    driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)
    SharedTools::Tools::DatabaseTool.new(driver: driver)
  end
end

# Use configuration
disk = ToolConfig.disk_tool(root: '/tmp')
browser = ToolConfig.browser_tool
```

## Advanced Topics

### Performance Optimization

- Batch operations when possible
- Use appropriate chunk sizes for large data
- Cache expensive operations
- Close resources promptly

### Security Considerations

- Always use authorization for untrusted input
- Sanitize user inputs
- Use sandboxed directories
- Validate file paths
- Limit execution time

### Testing Tools

```ruby
require 'minitest/autorun'

class ToolTest < Minitest::Test
  def setup
    @disk = SharedTools::Tools::DiskTool.new
  end

  def test_file_operations
    @disk.execute(action: "file_create", path: "./test.txt")
    @disk.execute(action: "file_write", path: "./test.txt", text: "test")

    content = @disk.execute(action: "file_read", path: "./test.txt")
    assert_equal "test", content

    @disk.execute(action: "file_delete", path: "./test.txt")
  end
end
```

### Logging and Debugging

```ruby
require 'logger'

# Create detailed logger
logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG
logger.formatter = proc do |severity, datetime, progname, msg|
  "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
end

# Use with tools
disk = SharedTools::Tools::DiskTool.new(logger: logger)
disk.execute(action: "file_read", path: "./test.txt")
# Output: [2025-10-25 10:30:00] INFO: action="file_read" path="./test.txt"
```

## Contributing

Have ideas for new guides? Contributions welcome!

- [GitHub Repository](https://github.com/madbomber/shared_tools)
- [Issue Tracker](https://github.com/madbomber/shared_tools/issues)
- [Pull Requests](https://github.com/madbomber/shared_tools/pulls)
