# Installation

## Requirements

- Ruby >= 3.3.0
- Bundler (recommended)

## Basic Installation

Add SharedTools to your Gemfile:

```ruby
gem 'shared_tools'
gem 'ruby_llm'  # Required LLM framework
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
- `dentaku` - Mathematical expression evaluation (CalculatorTool)
- `openweathermap` - Weather API client (WeatherTool)
- `sequel` - SQL toolkit (DatabaseQueryTool)

## Optional Dependencies

Depending on which tools you plan to use, you may need additional gems:

### Browser Automation

For the `BrowserTool`:

```ruby
gem 'watir'
```

Watir also requires a browser driver. Install ChromeDriver:

```bash
# macOS
brew install --cask chromedriver

# Ubuntu/Debian
apt-get install chromium-chromedriver
```

### Database Operations

For the `DatabaseTool`:

```ruby
gem 'sqlite3'   # SQLite
gem 'pg'        # PostgreSQL
```

### Document Processing

For the `DocTool`:

```ruby
gem 'pdf-reader', '~> 2.0'   # PDF support
gem 'docx'                    # Microsoft Word (.docx) support
gem 'roo'                     # Spreadsheet support: CSV, XLSX, ODS, XLSM
```

Install all three to support all document formats:

```bash
gem install pdf-reader docx roo
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
gem 'ruby_llm'

# Browser automation
gem 'watir'

# Database
gem 'sqlite3'
gem 'pg'

# Document processing
gem 'pdf-reader'
gem 'docx'
gem 'roo'
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
SharedTools version: 0.x.x
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

On macOS, if the `sqlite3` gem fails to install:

```bash
gem install sqlite3 -- --with-sqlite3-include=/usr/local/opt/sqlite/include \
                        --with-sqlite3-lib=/usr/local/opt/sqlite/lib
```

### DocTool — Missing Gem for Format

If DocTool raises a `LoadError` when reading a specific format, install the corresponding gem:

```bash
gem install pdf-reader   # for PDF
gem install docx         # for Word documents
gem install roo          # for CSV, XLSX, ODS
```

## Next Steps

- [Quickstart Guide](quickstart.md) - Get started in 5 minutes
- [Basic Usage](basic-usage.md) - Learn the fundamentals
- [Tools Overview](../tools/index.md) - Explore available tools
