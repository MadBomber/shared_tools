# Installation

## Requirements

- Ruby >= 3.3.0
- Bundler (recommended)

## Basic Installation

Add SharedTools to your Gemfile:

```ruby
gem 'shared_tools'
```

Then install:

```bash
bundle install
```

Or install directly:

```bash
gem install shared_tools
```

## Dependencies

SharedTools has the following core dependencies that are automatically installed:

- `ruby_llm` - Ruby LLM framework for tool integration
- `zeitwerk` - Code autoloading
- `nokogiri` - HTML/XML parsing

## Optional Dependencies

Depending on which tools you plan to use, you may need additional gems:

### Browser Automation

For the `BrowserTool`:

```ruby
gem 'watir'
```

Watir also requires a browser driver (Chrome, Firefox, etc.). Install ChromeDriver:

```bash
# macOS
brew install --cask chromedriver

# Ubuntu/Debian
apt-get install chromium-chromedriver
```

### Database Operations

For the `DatabaseTool`:

```ruby
# SQLite
gem 'sqlite3'

# PostgreSQL
gem 'pg'
```

### Document Processing

For the `DocTool`:

```ruby
gem 'pdf-reader', '~> 2.0'
```

### Code Evaluation

The `EvalTool` requires:

- Ruby (already installed)
- Python 3 (for Python evaluation)
- Shell access (for shell commands)

Install Python 3:

```bash
# macOS
brew install python3

# Ubuntu/Debian
apt-get install python3
```

## Complete Setup Example

For a full-featured installation with all optional dependencies:

```ruby
# Gemfile
gem 'shared_tools'
gem 'watir'            # Browser automation
gem 'sqlite3'          # SQLite database
gem 'pg'               # PostgreSQL database
gem 'pdf-reader'       # PDF processing
```

Then run:

```bash
bundle install
```

## Verify Installation

Create a test script to verify SharedTools is installed correctly:

```ruby
# test_install.rb
require 'shared_tools'

puts "SharedTools version: #{SharedTools::VERSION}"
puts "RubyLLM detected: #{defined?(RubyLLM::Tool) ? 'Yes' : 'No'}"

# Test basic tool initialization
disk = SharedTools::Tools::DiskTool.new
puts "DiskTool initialized successfully!"
```

Run it:

```bash
ruby test_install.rb
```

Expected output:

```
SharedTools version: 0.5.1
RubyLLM detected: Yes
DiskTool initialized successfully!
```

## Troubleshooting

### Zeitwerk Errors

If you see autoloading errors, ensure you're using Ruby >= 3.3.0:

```bash
ruby --version
```

### Missing Browser Driver

If BrowserTool fails with "browser not found":

1. Install a browser (Chrome, Firefox)
2. Install the corresponding driver (chromedriver, geckodriver)
3. Ensure the driver is in your PATH

### SQLite3 Compilation Issues

On macOS, if `sqlite3` gem fails to install:

```bash
gem install sqlite3 -- --with-sqlite3-include=/usr/local/opt/sqlite/include \
                        --with-sqlite3-lib=/usr/local/opt/sqlite/lib
```

## Next Steps

- [Quickstart Guide](quickstart.md) - Get started in 5 minutes
- [Basic Usage](basic-usage.md) - Learn the fundamentals
- [Tools Overview](../tools/index.md) - Explore available tools
