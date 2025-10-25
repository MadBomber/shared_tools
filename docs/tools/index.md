# Tools Overview

SharedTools provides a collection of LLM-callable tools for common operations. Each tool follows a consistent facade pattern with an action-based interface.

## Available Tools

### [BrowserTool](browser.md)

Web browser automation using Watir for visiting pages, inspecting content, clicking elements, filling forms, and capturing screenshots.

**Key Features:**

- Navigate to URLs
- Inspect page content and DOM
- Find elements by text or CSS selectors
- Click buttons and links
- Fill input fields
- Take screenshots

**Example:**

```ruby
browser = SharedTools::Tools::BrowserTool.new
browser.execute(action: "visit", url: "https://example.com")
browser.execute(action: "click", selector: "button.login")
```

[View BrowserTool Documentation →](browser.md)

---

### [DiskTool](disk.md)

Secure file system operations with path traversal protection for managing files and directories.

**Key Features:**

- Create, read, write, delete files
- Create, list, move, delete directories
- Find and replace text in files
- Path security (sandboxing)

**Example:**

```ruby
disk = SharedTools::Tools::DiskTool.new
disk.execute(action: "file_write", path: "./data.txt", text: "Hello")
content = disk.execute(action: "file_read", path: "./data.txt")
```

[View DiskTool Documentation →](disk.md)

---

### [EvalTool](eval.md)

Execute code in multiple languages (Ruby, Python, Shell) with authorization controls.

**Key Features:**

- Execute Ruby code
- Execute Python scripts
- Run shell commands
- Authorization system for safety

**Example:**

```ruby
eval_tool = SharedTools::Tools::EvalTool.new
result = eval_tool.execute(action: "ruby", code: "[1,2,3].sum")
# => 6
```

[View EvalTool Documentation →](eval.md)

---

### [DocTool](doc.md)

Read and process document formats, currently supporting PDF files.

**Key Features:**

- Read specific PDF pages
- Support for page ranges
- Extract text content

**Example:**

```ruby
doc = SharedTools::Tools::DocTool.new
result = doc.execute(
  action: "pdf_read",
  doc_path: "./report.pdf",
  page_numbers: "1-5"
)
```

[View DocTool Documentation →](doc.md)

---

### [DatabaseTool](database.md)

Execute SQL statements against SQLite or PostgreSQL databases.

**Key Features:**

- Execute SELECT, INSERT, UPDATE, DELETE
- Transaction-like execution (stops on error)
- Support for multiple databases
- Pluggable driver architecture

**Example:**

```ruby
driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)
database.execute(statements: ["SELECT * FROM users"])
```

[View DatabaseTool Documentation →](database.md)

---

## Tool Architecture

All tools share common architectural patterns:

### Facade Pattern

Each tool acts as a facade, providing a unified interface to complex operations:

```ruby
# Single tool, multiple related actions
tool.execute(action: "action_one", params...)
tool.execute(action: "action_two", params...)
```

### Action-Based Interface

Tools use an action parameter to specify the operation:

```ruby
tool.execute(
  action: "specific_action",
  param1: "value1",
  param2: "value2"
)
```

### Driver Architecture

Tools delegate to driver implementations for flexibility:

```ruby
# Use built-in driver
tool = SharedTools::Tools::SomeTool.new

# Or provide custom driver
custom_driver = MyCustomDriver.new
tool = SharedTools::Tools::SomeTool.new(driver: custom_driver)
```

### Authorization Integration

Tools respect the global authorization setting:

```ruby
# Default: requires confirmation
SharedTools.execute?(tool: 'tool_name', stuff: 'operation details')

# Disable for automation
SharedTools.auto_execute(true)
```

## Tool Comparison

| Tool | Primary Use | Authorization | Requires External Gem |
|------|-------------|---------------|----------------------|
| BrowserTool | Web automation | No | Yes (watir) |
| DiskTool | File operations | No | No |
| EvalTool | Code execution | Yes | No (Python for python action) |
| DocTool | Document processing | No | Yes (pdf-reader) |
| DatabaseTool | SQL operations | No | Yes (sqlite3 or pg) |

## Common Usage Patterns

### Pattern 1: Resource Management

```ruby
tool = SharedTools::Tools::BrowserTool.new
begin
  tool.execute(action: "visit", url: "https://example.com")
  # Do work...
ensure
  tool.cleanup!  # Always clean up
end
```

### Pattern 2: Error Handling

```ruby
begin
  result = tool.execute(action: "some_action", param: "value")
rescue ArgumentError => e
  puts "Invalid parameters: #{e.message}"
rescue StandardError => e
  puts "Operation failed: #{e.message}"
end
```

### Pattern 3: Multi-Tool Workflows

```ruby
# Combine tools for complex workflows
browser = SharedTools::Tools::BrowserTool.new
disk = SharedTools::Tools::DiskTool.new
database = SharedTools::Tools::DatabaseTool.new(driver: driver)

# 1. Scrape data
html = browser.execute(action: "page_inspect", full_html: true)

# 2. Save raw data
disk.execute(action: "file_write", path: "./raw.html", text: html)

# 3. Store in database
database.execute(statements: ["INSERT INTO pages (content) VALUES ('#{html}')"])

browser.cleanup!
```

## Tool Selection Guide

### Choose BrowserTool when you need to:

- Interact with web pages
- Fill forms and click buttons
- Scrape dynamic content
- Take screenshots of web pages

### Choose DiskTool when you need to:

- Read or write files
- Manage directory structures
- Search and replace in files
- Work with the file system safely

### Choose EvalTool when you need to:

- Execute Ruby code dynamically
- Run Python scripts
- Execute shell commands
- Process data with code

### Choose DocTool when you need to:

- Extract text from PDFs
- Read specific document pages
- Process document content

### Choose DatabaseTool when you need to:

- Execute SQL queries
- Manage database records
- Perform CRUD operations
- Work with relational data

## Next Steps

- View detailed documentation for each tool
- [Basic Usage Guide](../getting-started/basic-usage.md) - Learn common patterns
- [Authorization System](../guides/authorization.md) - Control operation approval
- [Working with Drivers](../guides/drivers.md) - Create custom drivers
