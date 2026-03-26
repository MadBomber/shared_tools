# SharedTools

![SharedTools](assets/images/shared_tools.png)

A comprehensive Ruby gem providing LLM-callable tools for browser automation, file operations, code evaluation, database operations, document processing, network queries, data science, workflow management, and more.

## Overview

SharedTools provides a collection of reusable tools designed to work seamlessly with the [RubyLLM](https://github.com/mariochavez/ruby_llm) framework. Each tool extends `RubyLLM::Tool` and provides a clean, consistent interface for common operations that LLM agents need to perform.

### Key Features

- **Browser Automation**: Control web browsers with Watir for visiting pages, clicking elements, filling forms, and taking screenshots
- **File System Operations**: Secure file and directory operations with path traversal protection
- **Code Evaluation**: Execute Ruby, Python, and shell commands with authorization controls
- **Database Operations**: Execute SQL queries against SQLite, PostgreSQL, and other databases
- **Document Processing**: Read plain text, PDF, Word (.docx), and spreadsheet files (CSV, XLSX, ODS)
- **Network & DNS**: DNS lookups, WHOIS queries, IP geolocation, and external IP detection
- **Data Science**: Statistical analysis, correlation, time series, clustering, and prediction
- **Workflow Management**: Persistent multi-step workflow orchestration with state tracking
- **System Utilities**: Date/time, system info, clipboard, cron scheduling, and more
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
disk.execute(action: "file_create", path: "./scraped_data.html")
disk.execute(action: "file_write", path: "./scraped_data.html", text: html)

# Clean up
browser.cleanup!
```

## Getting Started

- [Installation](getting-started/installation.md) - Install and configure SharedTools
- [Quickstart Guide](getting-started/quickstart.md) - Get up and running in 5 minutes
- [Basic Usage](getting-started/basic-usage.md) - Learn fundamental patterns

## Available Tools

### Core Tools
- **[BrowserTool](tools/browser.md)** - Web browser automation with Watir
- **[DiskTool](tools/disk.md)** - File and directory operations
- **[EvalTool](tools/eval.md)** - Code execution (Ruby, Python, Shell)
- **[DocTool](tools/doc.md)** - Document reading: plain text, PDF, Word, and spreadsheets
- **[DatabaseTool](tools/database.md)** - SQL database operations (read/write)
- **[DatabaseQueryTool](tools/database.md)** - Safe read-only SQL queries
- **[ComputerTool](tools/computer.md)** - Mouse, keyboard, and screen automation

### Data & Analysis
- **[CalculatorTool](tools/calculator.md)** - Safe mathematical expression evaluation
- **[DataScienceKit](tools/data_science_kit.md)** - Statistical analysis, correlation, clustering, prediction
- **[CompositeAnalysisTool](tools/index.md)** - Multi-stage data analysis orchestration

### Network & System
- **[DnsTool](tools/dns_tool.md)** - DNS lookups, WHOIS, IP geolocation, external IP detection
- **[WeatherTool](tools/weather.md)** - Real-time weather data via OpenWeatherMap
- **[SystemInfoTool](tools/index.md)** - System hardware and OS information
- **[CurrentDateTimeTool](tools/index.md)** - Current date, time, and day of week
- **[ClipboardTool](tools/index.md)** - Read and write system clipboard
- **[CronTool](tools/index.md)** - Cron expression scheduling utilities

### Workflow & DevOps
- **[WorkflowManagerTool](tools/index.md)** - Persistent multi-step workflow orchestration
- **[Docker ComposeRunTool](tools/index.md)** - Docker container command execution
- **[ErrorHandlingTool](tools/index.md)** - Reference implementation for error handling patterns

## Guides

- **[Authorization System](guides/authorization.md)** - Control when operations require approval
- **[Working with Drivers](guides/drivers.md)** - Extend tools with custom drivers

## Requirements

- Ruby >= 3.3.0
- RubyLLM gem
- Optional: watir (browser), sqlite3/pg (databases), pdf-reader (PDFs), docx (Word), roo (spreadsheets)

## License

MIT License - see [LICENSE](https://github.com/madbomber/shared_tools/blob/main/LICENSE) for details.

## Credits

Originally inspired by Kevin Sylvestre's [omniai-tools](https://github.com/ksylvest/omniai-tools) gem. SharedTools has evolved to focus exclusively on RubyLLM support with an extended tool collection.
