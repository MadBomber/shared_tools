# SharedTools

A comprehensive Ruby gem providing LLM-callable tools for browser automation, file operations, code evaluation, database operations, and document processing.

## Overview

SharedTools provides a collection of reusable tools designed to work seamlessly with the [RubyLLM](https://github.com/madbomber/ruby_llm) framework. Each tool extends `RubyLLM::Tool` and provides a clean, consistent interface for common operations that LLM agents need to perform.

### Key Features

- **Browser Automation**: Control web browsers with Watir for visiting pages, clicking elements, filling forms, and taking screenshots
- **File System Operations**: Secure file and directory operations with path traversal protection
- **Code Evaluation**: Execute Ruby, Python, and shell commands with authorization controls
- **Database Operations**: Execute SQL queries against SQLite and PostgreSQL databases
- **Document Processing**: Read and extract content from PDF documents
- **Authorization System**: Human-in-the-loop confirmation for potentially dangerous operations
- **Driver Architecture**: Pluggable driver system for extensibility

### Design Principles

**Facade Pattern**: Each tool acts as a facade, providing a unified interface to complex subsystems:

```ruby
# Single tool, multiple actions
browser = SharedTools::Tools::BrowserTool.new
browser.execute(action: "visit", url: "https://example.com")
browser.execute(action: "click", selector: "button[type='submit']")
browser.execute(action: "screenshot")
```

**Safety First**: Authorization system protects against unintended operations:

```ruby
# By default, requires human confirmation
SharedTools.execute?(tool: 'eval_tool', stuff: 'rm -rf /')  # Prompts user

# Can be disabled for automation
SharedTools.auto_execute(true)  # Bypass confirmation
```

**Driver-Based**: Extensible architecture allows custom implementations:

```ruby
# Use built-in driver
disk = SharedTools::Tools::DiskTool.new  # Uses LocalDriver

# Or provide custom driver
custom_driver = MyCustomDriver.new
disk = SharedTools::Tools::DiskTool.new(driver: custom_driver)
```

## Quick Example

```ruby
require 'shared_tools'

# Initialize tools
browser = SharedTools::Tools::BrowserTool.new
disk = SharedTools::Tools::DiskTool.new

# Scrape data from a website
browser.execute(action: "visit", url: "https://example.com/products")
html = browser.execute(action: "page_inspect", full_html: true)

# Save to file
disk.execute(
  action: "file_create",
  path: "./scraped_data.html"
)
disk.execute(
  action: "file_write",
  path: "./scraped_data.html",
  text: html
)

# Clean up
browser.cleanup!
```

## Getting Started

- [Installation](getting-started/installation.md) - Install and configure SharedTools
- [Quickstart Guide](getting-started/quickstart.md) - Get up and running in 5 minutes
- [Basic Usage](getting-started/basic-usage.md) - Learn fundamental patterns

## Available Tools

- **[BrowserTool](tools/browser.md)** - Web browser automation with Watir
- **[DiskTool](tools/disk.md)** - File and directory operations
- **[EvalTool](tools/eval.md)** - Code execution (Ruby, Python, Shell)
- **[DocTool](tools/doc.md)** - PDF document processing
- **[DatabaseTool](tools/database.md)** - SQL database operations

## Guides

- **[Authorization System](guides/authorization.md)** - Control when operations require approval
- **[Working with Drivers](guides/drivers.md)** - Extend tools with custom drivers

## Requirements

- Ruby >= 3.3.0
- RubyLLM gem
- Optional: watir (for browser automation), sqlite3 or pg (for databases), pdf-reader (for PDFs)

## License

MIT License - see [LICENSE](https://github.com/madbomber/shared_tools/blob/main/LICENSE) for details.

## Credits

Originally inspired by Kevin Sylvestre's [omniai-tools](https://github.com/ksylvest/omniai-tools) gem. SharedTools has evolved to focus exclusively on RubyLLM support with enhanced features and an extended tool collection.
