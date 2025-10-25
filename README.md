<div align="center">
  <h1>SharedTools</h1>
  <img src="docs/assets/images/shared_tools.png" alt="Two Robots sharing the same set of tools" width="400">
  <p><em>A Ruby gem providing LLM-callable tools for browser automation, file operations, code evaluation, and more</em></p>

  [![Gem Version](https://badge.fury.io/rb/shared_tools.svg)](https://badge.fury.io/rb/shared_tools)
  [![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)
  [![Documentation](https://img.shields.io/badge/docs-mkdocs-blue.svg)](https://madbomber.github.io/shared_tools)
</div>

---

## Overview

SharedTools is a comprehensive collection of production-ready tools designed for LLM (Large Language Model) applications. Built on the [RubyLLM](https://github.com/mariochavez/ruby_llm) framework, it provides a unified interface for common automation tasks while maintaining safety through a human-in-the-loop authorization system.

### Key Features

- 🔧 **6 Tool Collections** - Browser automation, file operations, database queries, code evaluation, PDF processing, and system control
- 🔒 **Human-in-the-Loop Authorization** - Built-in safety system for sensitive operations
- 🎯 **Facade Pattern** - Simplified interfaces with complex capabilities under the hood
- 🔌 **Pluggable Drivers** - Swap implementations for testing or different backends
- 📚 **Comprehensive Documentation** - Detailed guides, examples, and API reference
- ✅ **Well Tested** - 85%+ test coverage with Minitest

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
gem 'webdrivers'

# For DatabaseTool
gem 'sqlite3'  # or pg, mysql2, etc.

# For DocTool
gem 'pdf-reader'  # included in SharedTools dependencies
```

## Quick Start

```ruby
require 'shared_tools'
require 'ruby_llm'

# Initialize an LLM agent with SharedTools
agent = RubyLLM::Agent.new(
  tools: [
    SharedTools::Tools::BrowserTool.new,
    SharedTools::Tools::DiskTool.new,
    SharedTools::Tools::DatabaseTool.new
  ]
)

# Use with human-in-the-loop authorization (default)
agent.process("Visit example.com and save the page title to title.txt")
# User will be prompted: "Allow BrowserTool to visit https://example.com? (y/n)"

# Or enable auto-execution for automated workflows
SharedTools.auto_execute(true)
agent.process("Read all .rb files in the current directory")
```

## Tool Collections

### 🌐 Browser Tools

Web automation and scraping capabilities.

**Actions:**
- `visit` - Navigate to URLs
- `page_inspect` - Get page HTML content
- `ui_inspect` - Find elements by text
- `selector_inspect` - Find elements by CSS selector
- `click` - Click elements
- `text_field_set` - Fill in forms
- `screenshot` - Capture page screenshots

**Example:**
```ruby
browser = SharedTools::Tools::BrowserTool.new

browser.execute(action: "visit", url: "https://example.com")
browser.execute(action: "page_inspect", full_html: false)
```

[📖 Full Browser Documentation](https://madbomber.github.io/shared_tools/tools/browser/)

---

### 💾 Disk Tools

Secure file system operations with path traversal protection.

**Actions:**
- `file_create` - Create new files
- `file_read` - Read file contents
- `file_write` - Write to files
- `file_delete` - Delete files
- `file_move` - Move/rename files
- `file_replace` - Find and replace text in files
- `directory_create` - Create directories
- `directory_list` - List directory contents
- `directory_move` - Move directories
- `directory_delete` - Delete directories

**Example:**
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

**Actions:**
- Execute SQL statements (CREATE, INSERT, SELECT, UPDATE, DELETE)
- Batch statement execution
- Transaction-like error handling (stops on first error)
- Support for SQLite, PostgreSQL, MySQL via drivers

**Example:**
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

**Languages:**
- `ruby` - Execute Ruby code
- `python` - Execute Python code (with sandboxing)
- `shell` - Execute shell commands

**Example:**
```ruby
eval_tool = SharedTools::Tools::EvalTool.new

# Ruby evaluation
result = eval_tool.execute(language: "ruby", code: "puts 2 + 2")

# Shell command execution (requires authorization by default)
output = eval_tool.execute(language: "shell", code: "ls -la")
```

[📖 Full Eval Documentation](https://madbomber.github.io/shared_tools/tools/eval/)

---

### 📄 Doc Tools

PDF document processing and text extraction.

**Actions:**
- `read_pdf` - Read PDF content from specific pages or entire documents
- Extract text, statistics, and metadata
- Process multi-page documents

**Example:**
```ruby
doc = SharedTools::Tools::DocTool.new

# Read first page
content = doc.execute(action: "read_pdf", path: "./document.pdf", page: 1)

# Read entire document
full_content = doc.execute(action: "read_pdf", path: "./document.pdf")
```

[📖 Full Doc Documentation](https://madbomber.github.io/shared_tools/tools/doc/)

---

### 🖱️ Computer Tools

System-level automation for mouse, keyboard, and screen control.

**Actions:**
- `mouse_click` - Click at coordinates
- `mouse_move` - Move mouse cursor
- `mouse_position` - Get current mouse position
- `type` - Type text
- `key` - Press keyboard keys and shortcuts
- `hold_key` - Hold keys for duration
- `scroll` - Scroll windows
- `wait` - Wait for specified duration

**Example:**
```ruby
computer = SharedTools::Tools::ComputerTool.new

computer.execute(action: "mouse_click", coordinate: {x: 100, y: 200})
computer.execute(action: "type", text: "Hello, World!")
computer.execute(action: "key", text: "Return")
```

[📖 Full Computer Documentation](https://madbomber.github.io/shared_tools/tools/computer/)

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

- **[Getting Started](https://madbomber.github.io/shared_tools/getting-started/installation/)** - Installation, quick start, basic usage
- **[Tool Collections](https://madbomber.github.io/shared_tools/tools/)** - Detailed documentation for each tool
- **[Guides](https://madbomber.github.io/shared_tools/guides/)** - Authorization, drivers, error handling, testing
- **[Examples](https://madbomber.github.io/shared_tools/examples/)** - Working code examples and workflows
- **[API Reference](https://madbomber.github.io/shared_tools/api/)** - Tool base class, facade pattern, driver interface
- **[Development](https://madbomber.github.io/shared_tools/development/)** - Architecture, contributing, changelog

## Examples

The `/examples` directory contains working demonstrations:

- `browser_tool_example.rb` - Web automation
- `disk_tool_example.rb` - File operations
- `database_tool_example.rb` - SQL operations
- `eval_tool_example.rb` - Code evaluation
- `doc_tool_example.rb` - PDF processing
- `comprehensive_workflow_example.rb` - Multi-tool workflow

Run examples:
```bash
bundle install
ruby examples/browser_tool_example.rb
```

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
# Install MkDocs and dependencies
pip install mkdocs-material

# Serve documentation locally
mkdocs serve

# Build static site
mkdocs build
```

### Code Quality

The project uses standard Ruby tooling:

- **Testing**: Minitest (85%+ coverage)
- **Code Loading**: Zeitwerk for autoloading
- **Documentation**: MkDocs with Material theme
- **Examples**: Executable Ruby scripts in `/examples`

## Contributing

Contributions are welcome! Here's how you can help:

### Reporting Issues

Found a bug or have a feature request? Please [open an issue](https://github.com/madbomber/shared_tools/issues/new) with:

- Clear description of the problem
- Steps to reproduce (for bugs)
- Expected vs actual behavior
- Ruby version and gem version
- Code examples if applicable

### Submitting Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes with tests
4. Ensure tests pass (`bundle exec rake test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Contribution Guidelines

- Add tests for new features
- Update documentation as needed
- Follow existing code style
- Keep commits focused and atomic
- Write clear commit messages

[📖 Contributing Guide](https://madbomber.github.io/shared_tools/development/contributing/)

## Roadmap

See the [Changelog](https://madbomber.github.io/shared_tools/development/changelog/) for version history and upcoming features.

### Future Enhancements

- Additional browser drivers (Selenium, Playwright)
- More database adapters
- Enhanced PDF processing capabilities
- Additional document formats (Word, Excel)
- Video and image processing tools

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
