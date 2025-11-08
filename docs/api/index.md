# API Reference

Complete API documentation for SharedTools, covering the base tool classes, facade patterns, driver interfaces, and all available tools.

## Core Concepts

SharedTools is built around several key architectural patterns:

- **Tool Base Class**: All tools extend `RubyLLM::Tool` which provides the DSL for defining parameters and descriptions
- **Facade Pattern**: Complex tools like BrowserTool, DiskTool, and DatabaseTool act as facades that delegate to specialized sub-tools
- **Driver Interface**: Tools that interact with external systems use pluggable drivers (browser drivers, database drivers, etc.)
- **Authorization System**: Human-in-the-loop confirmation via `SharedTools.execute?`

## Quick Reference

### Available Tools

| Tool | Purpose | Driver Required | Example Use Case |
|------|---------|-----------------|------------------|
| [BrowserTool](../tools/browser.md) | Web automation | Browser driver (Watir) | Scraping, testing, automation |
| [DiskTool](../tools/disk.md) | File system operations | Local driver | Reading/writing files |
| [DatabaseTool](../tools/database.md) | SQL execution | Database driver | Data storage, queries |
| [ComputerTool](../tools/computer.md) | System control | Computer driver (Mac) | Screenshots, mouse/keyboard |
| [EvalTool](../tools/eval.md) | Code execution | None | Running Ruby/Python/Shell |
| [DocTool](../tools/doc.md) | Document processing | None | Reading PDFs |

### Tool Actions Reference

Quick lookup for tool actions and their required parameters:

#### BrowserTool Actions

```ruby
# Visit a URL
action: "visit", url: "https://example.com"

# Get page HTML/summary
action: "page_inspect", full_html: true/false

# Find elements by text
action: "ui_inspect", text_content: "Search", context_size: 2

# Find elements by CSS selector
action: "selector_inspect", selector: ".button", context_size: 2

# Click an element
action: "click", selector: "button[type='submit']"

# Fill in text field
action: "text_field_set", selector: "#input", value: "text"

# Take screenshot
action: "screenshot"
```

#### DiskTool Actions

```ruby
# Directory operations
action: "directory_create", path: "./new_dir"
action: "directory_delete", path: "./old_dir"
action: "directory_move", path: "./src", destination: "./dest"
action: "directory_list", path: "."

# File operations
action: "file_create", path: "./new.txt"
action: "file_delete", path: "./old.txt"
action: "file_move", path: "./src.txt", destination: "./dest.txt"
action: "file_read", path: "./file.txt"
action: "file_write", path: "./file.txt", text: "content"
action: "file_replace", path: "./file.txt", old_text: "old", new_text: "new"
```

#### DatabaseTool Actions

```ruby
# Execute SQL statements
statements: [
  "CREATE TABLE users (id INTEGER, name TEXT)",
  "INSERT INTO users VALUES (1, 'Alice')",
  "SELECT * FROM users"
]
```

## Documentation Structure

### [Tool Base Class](./tool-base.md)

Learn about the `RubyLLM::Tool` base class that all SharedTools extend:

- Parameter DSL with `param`
- Description method
- Execute method signature
- Logger integration
- Common patterns

### [Facade Pattern](./facade-pattern.md)

Understand how facade tools like BrowserTool orchestrate multiple specialized sub-tools:

- Architecture overview
- Sub-tool delegation
- Action routing
- Parameter validation
- Error handling

### [Driver Interface](./driver-interface.md)

Details on implementing and using driver interfaces:

- BaseDriver pattern
- Required methods
- Custom driver implementation
- Testing with mock drivers
- Available drivers

## Tool-Specific Documentation

Detailed documentation for each tool:

- [BrowserTool](../tools/browser.md) - Web automation and scraping
- [DiskTool](../tools/disk.md) - File system operations
- [DatabaseTool](../tools/database.md) - SQL database operations
- [ComputerTool](../tools/computer.md) - System-level automation
- [EvalTool](../tools/eval.md) - Code evaluation
- [DocTool](../tools/doc.md) - Document processing

## Common API Patterns

### Initialization Patterns

Most tools follow consistent initialization patterns:

```ruby
# With default driver
tool = SharedTools::Tools::BrowserTool.new

# With custom driver
driver = MyCustomDriver.new
tool = SharedTools::Tools::BrowserTool.new(driver: driver)

# With logger
tool = SharedTools::Tools::BrowserTool.new(logger: my_logger)

# With multiple options
tool = SharedTools::Tools::BrowserTool.new(
  driver: driver,
  logger: logger
)
```

### Execution Patterns

All tools use the `execute` method with keyword arguments:

```ruby
# Single action
result = tool.execute(
  action: "visit",
  url: "https://example.com"
)

# Multiple parameters
result = tool.execute(
  action: "text_field_set",
  selector: "#search",
  value: "query"
)

# Optional parameters
result = tool.execute(
  action: "ui_inspect",
  text_content: "Login",
  context_size: 3  # optional
)
```

### Result Patterns

Tools return consistent result formats:

```ruby
# String results
result = disk.execute(action: "file_read", path: "./file.txt")
# => "file contents..."

# Hash results (DatabaseTool)
results = database.execute(statements: ["SELECT * FROM users"])
# => [{ status: :ok, statement: "SELECT...", result: [...] }]

# Structured responses
info = computer.execute(action: "screen_info")
# => { width: 1920, height: 1080, ... }
```

### Error Handling Patterns

```ruby
# Exception-based errors
begin
  result = tool.execute(action: "invalid_action")
rescue ArgumentError => e
  puts "Invalid parameters: #{e.message}"
end

# Status-based errors (DatabaseTool)
results = database.execute(statements: ["BAD SQL"])
if results.first[:status] == :error
  puts "SQL error: #{results.first[:result]}"
end

# Nil results
result = disk.execute(action: "file_read", path: "./missing.txt")
# => nil (or error depending on tool)
```

## Authorization System

All tools respect the SharedTools authorization system:

```ruby
# Enable human-in-the-loop (default)
SharedTools.auto_execute(false)

# When tool executes, user is prompted:
# "The AI (tool: disk_tool) wants to do the following ..."
# "Is it okay to proceed? (y/N)"

disk.execute(action: "file_delete", path: "./important.txt")

# Disable for automated workflows
SharedTools.auto_execute(true)
```

### Checking Authorization in Custom Tools

```ruby
class MyTool < RubyLLM::Tool
  def execute(action:)
    return unless SharedTools.execute?(
      tool: self.class.name,
      stuff: "Delete all files"
    )

    # Proceed with dangerous operation
    perform_action(action)
  end
end
```

## Logger Integration

All tools support optional logger parameters:

```ruby
require 'logger'

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG

tool = SharedTools::Tools::BrowserTool.new(logger: logger)
# Tool operations will now log to STDOUT
```

Default logger uses `RubyLLM.logger`:

```ruby
# Configure RubyLLM logger globally
RubyLLM.configure do |config|
  config.logger = Logger.new('llm.log')
end

# Tools will automatically use this logger
tool = SharedTools::Tools::BrowserTool.new
```

## Parameter Types

Tools use consistent parameter types:

### String Parameters

```ruby
url: "https://example.com"           # URLs
path: "./file.txt"                   # File paths
text: "Hello, World!"                # Text content
selector: "button.submit"            # CSS selectors
action: "visit"                      # Action names
```

### Integer Parameters

```ruby
context_size: 2                      # Context window size
page: 1                              # Page numbers
timeout: 30                          # Timeouts in seconds
```

### Boolean Parameters

```ruby
full_html: true                      # Return full HTML vs summary
summarize: false                     # Enable summarization
```

### Array Parameters

```ruby
statements: [                        # Array of SQL statements
  "SELECT * FROM users",
  "INSERT INTO logs VALUES (...)"
]
```

### Hash Parameters

```ruby
options: {                           # Tool-specific options
  headless: true,
  timeout: 60
}
```

## Tool Naming Convention

All tools follow a consistent naming pattern:

```ruby
# Class name
SharedTools::Tools::BrowserTool

# Tool name (for LLM)
BrowserTool.name  # => "browser_tool"

# Action constants
SharedTools::Tools::BrowserTool::Action::VISIT

# Sub-tools (internal)
SharedTools::Tools::Browser::VisitTool
```

## Version Compatibility

Current version: 0.2.1

- **RubyLLM**: Required, version ~> 0.4
- **Zeitwerk**: For autoloading
- **Optional Dependencies**:
  - `watir` for BrowserTool
  - `sqlite3` for SQLite database support
  - `pg` for PostgreSQL support
  - `pdf-reader` for DocTool

## Framework Evolution

Starting with version 0.3.0, SharedTools will focus exclusively on RubyLLM support. Earlier versions included support for:

- OmniAI (deprecated)
- llm.rb (deprecated)
- Raix (deprecated)

Migration guides will be provided for projects using older versions.

## Next Steps

- Learn about [RubyLLM::Tool base class](./tool-base.md)
- Understand the [Facade Pattern](./facade-pattern.md)
- Read about [Driver Interfaces](./driver-interface.md)
- Explore [Example Workflows](../examples/workflows.md)
- Review individual [Tool Documentation](../tools/browser.md)

## Getting Help

- GitHub Issues: Report bugs or request features
- Examples: Check `/examples` directory for working code
- Tests: Review test files for usage patterns
- Source Code: All code is documented with YARD comments
