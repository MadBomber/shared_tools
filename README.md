<div align="center">
  <h1>SharedTools</h1>
  <img src="docs/assets/images/shared_tools.png" alt="Two Robots sharing the same set of tools" width="400">
  <p><em>A Ruby gem providing LLM-callable tools for browser automation, file operations, code evaluation, document processing, network queries, data science, workflow management, and more</em></p>

  [![Gem Version](https://badge.fury.io/rb/shared_tools.svg)](https://badge.fury.io/rb/shared_tools)
  [![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)
  [![Documentation](https://img.shields.io/badge/docs-mkdocs-blue.svg)](https://madbomber.github.io/shared_tools)
</div>

---

## Overview

SharedTools is a comprehensive collection of production-ready tools designed for LLM (Large Language Model) applications. Built on the [RubyLLM](https://github.com/mariochavez/ruby_llm) framework, it provides a unified interface for common automation tasks while maintaining safety through a human-in-the-loop authorization system.

### Key Features

- 🔧 **20+ Production Tools** — Browser automation, file operations, database queries, code evaluation, document processing, DNS and WHOIS lookups, IP geolocation, data science, weather data, workflow management, system utilities, and more
- 🔒 **Human-in-the-Loop Authorization** — Built-in safety system for sensitive operations
- 🎯 **Facade Pattern** — Simplified interfaces with complex capabilities under the hood
- 🔌 **Pluggable Drivers** — Swap implementations for testing or different backends
- 📚 **Comprehensive Documentation** — Detailed guides, examples, and API reference
- ✅ **Well Tested** — 85%+ test coverage with Minitest

## Installation

Add to your Gemfile:

```ruby
gem 'shared_tools'
gem 'ruby_llm'  # Required LLM framework
```

Or install directly:

```bash
gem install shared_tools
```

### Optional Dependencies

Depending on which tools you use, you may need additional gems:

```ruby
# For BrowserTool
gem 'watir'

# For DatabaseTool and DatabaseQueryTool
gem 'sqlite3'  # or pg, mysql2, etc.

# For DocTool
gem 'pdf-reader'   # PDF support
gem 'docx'         # Microsoft Word (.docx) support
gem 'roo'          # Spreadsheet support: CSV, XLSX, ODS, XLSM

# Core dependencies (automatically installed)
gem 'dentaku'        # For CalculatorTool
gem 'openweathermap' # For WeatherTool
gem 'sequel'         # For DatabaseQueryTool
gem 'nokogiri'       # For various tools
```

## Quick Start

```ruby
require 'shared_tools'
require 'ruby_llm'

# Initialize an LLM agent with SharedTools
chat = RubyLLM.chat.with_tools(
  SharedTools::Tools::BrowserTool.new,
  SharedTools::Tools::DiskTool.new,
  SharedTools::Tools::DnsTool.new,
  SharedTools::Tools::WeatherTool.new,
  SharedTools::Tools::WorkflowManagerTool.new
)

# Use with human-in-the-loop authorization (default)
chat.ask("Visit example.com and save the page title to title.txt")
# User will be prompted: "Allow BrowserTool to visit https://example.com? (y/n)"

# Or enable auto-execution for automated workflows
SharedTools.auto_execute(true)
chat.ask("Calculate the square root of 144 and tell me the weather in London")
```

## Tool Collections

### 🌐 Browser Tools

Web automation and scraping capabilities.

**Actions:** `visit`, `page_inspect`, `ui_inspect`, `selector_inspect`, `click`, `text_field_set`, `screenshot`

```ruby
browser = SharedTools::Tools::BrowserTool.new
browser.execute(action: "visit", url: "https://example.com")
browser.execute(action: "page_inspect", full_html: false)
```

[📖 Full Browser Documentation](https://madbomber.github.io/shared_tools/tools/browser/)

---

### 💾 Disk Tools

Secure file system operations with path traversal protection.

**Actions:** `file_create`, `file_read`, `file_write`, `file_delete`, `file_move`, `file_replace`, `directory_create`, `directory_list`, `directory_move`, `directory_delete`

```ruby
disk = SharedTools::Tools::DiskTool.new
disk.execute(action: "file_create", path: "./report.txt")
disk.execute(action: "file_write", path: "./report.txt", text: "Hello, World!")
content = disk.execute(action: "file_read", path: "./report.txt")
```

[📖 Full Disk Documentation](https://madbomber.github.io/shared_tools/tools/disk/)

---

### 🗄️ Database Tools

Execute SQL operations on databases.

**Features:** SELECT, INSERT, UPDATE, DELETE; read-only query mode; automatic LIMIT enforcement; pluggable drivers (SQLite, PostgreSQL, MySQL)

```ruby
require 'sqlite3'

db = SQLite3::Database.new(':memory:')
driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)

results = database.execute(
  statements: [
    "CREATE TABLE users (id INTEGER, name TEXT)",
    "INSERT INTO users VALUES (1, 'Alice')",
    "SELECT * FROM users"
  ]
)
```

[📖 Full Database Documentation](https://madbomber.github.io/shared_tools/tools/database/)

---

### 💻 Eval Tools

Safe code evaluation for Ruby, Python, and shell commands.

**Languages:** `ruby`, `python`, `shell`

```ruby
eval_tool = SharedTools::Tools::EvalTool.new
result = eval_tool.execute(language: "ruby", code: "puts 2 + 2")
output = eval_tool.execute(language: "shell", code: "ls -la")
```

[📖 Full Eval Documentation](https://madbomber.github.io/shared_tools/tools/eval/)

---

### 📄 Doc Tools

Read and reason over documents in any format.

**Actions:** `text_read`, `pdf_read`, `docx_read`, `spreadsheet_read`

```ruby
doc = SharedTools::Tools::DocTool.new

# Plain text
doc.execute(action: "text_read", doc_path: "./notes.txt")

# PDF — specific pages or ranges
doc.execute(action: "pdf_read", doc_path: "./report.pdf", page_numbers: "1, 5-10")

# Microsoft Word
doc.execute(action: "docx_read", doc_path: "./meeting.docx")

# Spreadsheets (CSV, XLSX, ODS, XLSM)
doc.execute(action: "spreadsheet_read", doc_path: "./data.xlsx", sheet: "Q1 Sales")
```

[📖 Full Doc Documentation](https://madbomber.github.io/shared_tools/tools/doc/)

---

### 🌐 DNS Tool

DNS resolution, WHOIS queries, IP geolocation, and external IP detection. No API key required.

**Actions:** `a`, `aaaa`, `mx`, `ns`, `txt`, `cname`, `reverse`, `all`, `external_ip`, `ip_location`, `whois`

```ruby
dns = SharedTools::Tools::DnsTool.new

dns.execute(action: "mx", host: "gmail.com")
dns.execute(action: "whois", host: "ruby-lang.org")
dns.execute(action: "external_ip")
dns.execute(action: "ip_location")           # geolocate your own IP
dns.execute(action: "ip_location", host: "8.8.8.8")  # geolocate any IP
```

[📖 Full DNS Documentation](https://madbomber.github.io/shared_tools/tools/dns_tool/)

---

### 🌤️ Weather Tool

Real-time weather data from OpenWeatherMap API. Combine with DnsTool for automatic local forecasts.

**Features:** Current conditions, 3-day forecast, metric/imperial/kelvin units, global coverage

```ruby
weather = SharedTools::Tools::WeatherTool.new
weather.execute(city: "London,UK", units: "metric", include_forecast: true)
```

**Local forecast with automatic location detection:**

```ruby
chat = RubyLLM.chat.with_tools(
  SharedTools::Tools::DnsTool.new,
  SharedTools::Tools::WeatherTool.new,
  SharedTools::Tools::CurrentDateTimeTool.new
)

chat.ask("Get my external IP, find my city, then give me the current weather and 3-day forecast.")
```

[📖 Full Weather Documentation](https://madbomber.github.io/shared_tools/tools/weather/)

---

### 🧮 Calculator Tool

Safe mathematical calculations without code execution risks.

**Features:** Arithmetic, math functions (sqrt, round, abs), trigonometry (sin, cos, tan), configurable precision

```ruby
calculator = SharedTools::Tools::CalculatorTool.new
calculator.execute(expression: "sqrt(16) * 2", precision: 4)
# => {success: true, result: 8.0}
```

---

### 📊 Data Science Kit

Real statistical analysis on actual data — file-based or inline.

**Analysis types:** `statistical_summary`, `correlation_analysis`, `time_series`, `clustering`, `prediction`

**Inline data formats:** pipe-delimited tables, CSV strings, JSON arrays, comma-separated numbers

```ruby
kit = SharedTools::Tools::DataScienceKit.new

# From a file
kit.execute(analysis_type: "statistical_summary", data_source: "./sales.csv")

# Inline pipe-delimited table
kit.execute(
  analysis_type: "correlation_analysis",
  data: "| month | revenue | cost |\n| Jan | 12400 | 8200 |\n| Feb | 11800 | 7900 |"
)
```

[📖 Full Data Science Documentation](https://madbomber.github.io/shared_tools/tools/data_science_kit/)

---

### 🖱️ Computer Tools

System-level automation for mouse, keyboard, and screen control.

**Actions:** `mouse_click`, `mouse_move`, `mouse_position`, `type`, `key`, `hold_key`, `scroll`, `wait`

```ruby
computer = SharedTools::Tools::ComputerTool.new
computer.execute(action: "mouse_click", coordinate: {x: 100, y: 200})
computer.execute(action: "type", text: "Hello, World!")
```

[📖 Full Computer Documentation](https://madbomber.github.io/shared_tools/tools/computer/)

---

### 🕐 Date/Time, System Info & Clipboard

Utility tools for context and system access:

```ruby
# Current date and day of week (prevents LLM hallucination)
dt = SharedTools::Tools::CurrentDateTimeTool.new
dt.execute(format: "date")
# => { date: "2026-03-25", day_of_week: "Wednesday", ... }

# System hardware and OS info
info = SharedTools::Tools::SystemInfoTool.new
info.execute

# Clipboard
clipboard = SharedTools::Tools::ClipboardTool.new
clipboard.execute(action: "read")
clipboard.execute(action: "write", text: "Hello!")
```

---

### 🔄 Workflow Manager Tool

Persistent multi-step workflow orchestration with JSON file storage.

**Actions:** `start`, `step`, `status`, `complete`, `list`

```ruby
workflow = SharedTools::Tools::WorkflowManagerTool.new

# Start a workflow
result = workflow.execute(action: "start", step_data: {project: "release-v2.0"})
workflow_id = result[:workflow_id]

# Execute steps
workflow.execute(action: "step", workflow_id: workflow_id, step_data: {task: "run_tests"})
workflow.execute(action: "step", workflow_id: workflow_id, step_data: {task: "deploy"})

# Check status
workflow.execute(action: "status", workflow_id: workflow_id)

# List all workflows
workflow.execute(action: "list")

# Complete
workflow.execute(action: "complete", workflow_id: workflow_id)
```

---

### 📊 Composite Analysis Tool

Multi-stage data analysis orchestration.

```ruby
analyzer = SharedTools::Tools::CompositeAnalysisTool.new
analyzer.execute(
  data_source: "./sales_data.csv",
  analysis_type: "comprehensive",
  options: {include_correlations: true, visualization_limit: 5}
)
```

---

### 🐳 Docker Compose Tool

Execute Docker Compose commands safely.

```ruby
docker = SharedTools::Tools::Docker::ComposeRunTool.new
docker.execute(service: "app", command: "rspec", args: ["spec/main_spec.rb"])
```

---

### 🛠️ Error Handling Tool

Reference implementation for robust error handling patterns.

```ruby
error_tool = SharedTools::Tools::ErrorHandlingTool.new
error_tool.execute(
  operation: "process",
  data: {name: "test", value: 42},
  max_retries: 3
)
```

---

## Authorization System

SharedTools includes a human-in-the-loop authorization system for safety:

```ruby
# Require user confirmation (default)
SharedTools.auto_execute(false)

# The LLM proposes an action
disk.execute(action: "file_delete", path: "./important.txt")
# Prompt: "Allow DiskTool to delete ./important.txt? (y/n)"

# Enable auto-execution for trusted workflows
SharedTools.auto_execute(true)
disk.execute(action: "file_delete", path: "./temp.txt")
# Executes immediately without prompting
```

[📖 Authorization Guide](https://madbomber.github.io/shared_tools/guides/authorization/)

## Documentation

Comprehensive documentation is available at **[madbomber.github.io/shared_tools](https://madbomber.github.io/shared_tools)**

### Documentation Sections

- **[Getting Started](https://madbomber.github.io/shared_tools/getting-started/installation/)** — Installation, quick start, basic usage
- **[Tool Collections](https://madbomber.github.io/shared_tools/tools/)** — Detailed documentation for each tool
- **[Guides](https://madbomber.github.io/shared_tools/guides/)** — Authorization, drivers, error handling, testing
- **[Examples](https://madbomber.github.io/shared_tools/examples/)** — Working code examples and workflows
- **[API Reference](https://madbomber.github.io/shared_tools/api/)** — Tool base class, facade pattern, driver interface
- **[Development](https://madbomber.github.io/shared_tools/development/)** — Architecture, contributing, changelog

## Examples

The `/examples` directory contains runnable demonstrations using a shared `common.rb` helper:

```bash
bundle exec ruby -I examples examples/weather_tool_demo.rb
bundle exec ruby -I examples examples/dns_tool_demo.rb
bundle exec ruby -I examples examples/doc_tool_demo.rb
```

| Demo | What it shows |
|------|--------------|
| `browser_tool_demo.rb` | Web automation |
| `calculator_tool_demo.rb` | Math expressions |
| `clipboard_tool_demo.rb` | Clipboard read/write |
| `composite_analysis_tool_demo.rb` | Multi-stage analysis |
| `computer_tool_demo.rb` | Mouse and keyboard |
| `cron_tool_demo.rb` | Cron scheduling |
| `current_date_time_tool_demo.rb` | Real date and time |
| `data_science_kit_demo.rb` | Statistical analysis with inline data |
| `database_tool_demo.rb` | SQL operations |
| `database_query_tool_demo.rb` | Read-only SQL queries |
| `disk_tool_demo.rb` | File operations |
| `dns_tool_demo.rb` | DNS, WHOIS, geolocation |
| `doc_tool_demo.rb` | Text, PDF, Word, spreadsheets |
| `error_handling_tool_demo.rb` | Error handling patterns |
| `eval_tool_demo.rb` | Code evaluation |
| `mcp_client_demo.rb` | MCP client integration |
| `system_info_tool_demo.rb` | System info |
| `weather_tool_demo.rb` | Weather + local forecast |
| `workflow_manager_tool_demo.rb` | Workflow orchestration |
| `comprehensive_workflow_demo.rb` | Multi-tool pipeline |

[📖 View All Examples](https://madbomber.github.io/shared_tools/examples/)

## Development

### Setup

```bash
git clone https://github.com/madbomber/shared_tools.git
cd shared_tools
bundle install
```

### Running Tests

```bash
# Run all tests
bundle exec rake test

# Run specific test file
bundle exec ruby test/shared_tools/tools/browser_tool_test.rb

# Run with SimpleCov coverage report
COVERAGE=true bundle exec rake test
```

### Building Documentation

```bash
pip install mkdocs-material
mkdocs serve    # Serve locally
mkdocs build    # Build static site
```

### Code Quality

- **Testing**: Minitest (85%+ coverage)
- **Code Loading**: Zeitwerk for autoloading
- **Documentation**: MkDocs with Material theme
- **Examples**: Executable Ruby scripts in `/examples`

## Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with tests
4. Ensure tests pass (`bundle exec rake test`)
5. Open a Pull Request

[📖 Contributing Guide](https://madbomber.github.io/shared_tools/development/contributing/)

## Requirements

- Ruby 3.0 or higher
- RubyLLM gem for LLM integration

## License

This gem is available as open source under the terms of the [MIT License](LICENSE.txt).

## Special Thanks

This gem was originally inspired by Kevin Sylvestre's [omniai-tools](https://github.com/ksylvest/omniai-tools) gem. SharedTools has since evolved to focus exclusively on RubyLLM support with enhanced features and comprehensive documentation.

## Links

- **Documentation**: [madbomber.github.io/shared_tools](https://madbomber.github.io/shared_tools)
- **RubyGems**: [rubygems.org/gems/shared_tools](https://rubygems.org/gems/shared_tools)
- **Source Code**: [github.com/madbomber/shared_tools](https://github.com/madbomber/shared_tools)
- **Issue Tracker**: [github.com/madbomber/shared_tools/issues](https://github.com/madbomber/shared_tools/issues)
- **RubyLLM**: [github.com/mariochavez/ruby_llm](https://github.com/mariochavez/ruby_llm)

## Support

- 📖 [Documentation](https://madbomber.github.io/shared_tools)
- 💬 [GitHub Discussions](https://github.com/madbomber/shared_tools/discussions)
- 🐛 [Issue Tracker](https://github.com/madbomber/shared_tools/issues)

---

<div align="center">
  Made with ❤️ by <a href="https://github.com/madbomber">Dewayne VanHoozer</a>
</div>
