# SharedTools Examples

This directory contains example programs demonstrating how to use SharedTools with the RubyLLM framework. Each example showcases a different tool collection and demonstrates practical use cases.

## Prerequisites

**All examples require:**

1. **RubyLLM gem** - The Ruby LLM integration framework
   ```bash
   gem install ruby_llm
   ```

2. **LLM Provider** - A running LLM service (one of):
   - **Ollama** (recommended for local development)
     ```bash
     # Install Ollama from https://ollama.ai
     # Pull a model:
     ollama pull llama3.2
     # Or use the model referenced in examples:
     ollama pull gpt-oss:20b
     ```
   - **OpenAI API** - Set `OPENAI_API_KEY` environment variable
   - **Anthropic API** - Set `ANTHROPIC_API_KEY` environment variable

3. **Shared Configuration** - The `ruby_llm_config.rb` file in this directory provides helper methods (`title()`, `test_with_prompt()`, `ollama_chat()`) used by all examples.

## Running Examples

All examples are executable Ruby scripts:

```bash
cd examples
./browser_tool_example.rb
# or
ruby browser_tool_example.rb
```

**Debug mode** - See detailed LLM tool calls:
```bash
RUBY_LLM_DEBUG=true ./eval_tool_example.rb
```

**Expected behavior:**
- Examples will make LLM API calls and may take 10-30 seconds to complete
- With `RUBY_LLM_DEBUG=true`, you'll see tool invocations in the format: `Tool eval_ruby called with params={...}`
- Most examples will timeout (this is expected) as they demonstrate multiple interactions with the LLM

## Available Examples

### 1. Browser Tool Example (`browser_tool_example.rb`)

Demonstrates web browser automation capabilities including:
- Visiting web pages
- Inspecting page content (HTML/text)
- Finding UI elements by text or CSS selectors
- Clicking buttons and links
- Filling in form fields
- Taking screenshots
- Complete login workflow automation

**Requirements:**
```bash
gem install watir webdrivers
```

**Additional Requirements:**
- Chrome, Firefox, or Safari browser installed
- Compatible webdriver (automatically managed by `webdrivers` gem)

**Run it:**
```bash
./browser_tool_example.rb
```

**Key Features:**
- Uses mock driver for demonstration (no browser required)
- Shows all available browser actions
- Includes a complete form-filling workflow

---

### 2. Disk Tool Example (`disk_tool_example.rb`)

Demonstrates file system operations including:
- Creating directories (single and nested)
- Creating, reading, writing files
- Moving and deleting files/directories
- Replacing text within files
- Listing directory contents
- Security: path traversal protection
- Complete project structure generation

**Requirements:**
- None (uses standard Ruby libraries)

**Run it:**
```bash
./disk_tool_example.rb
```

**Key Features:**
- Works with temporary directories (automatically cleaned up)
- Demonstrates sandboxed file operations
- Shows security features preventing path traversal attacks
- Includes a complete Ruby project scaffolding example

---

### 3. Database Tool Example (`database_tool_example.rb`)

Demonstrates SQL database operations using SQLite:
- Creating tables
- Inserting data
- Querying with SELECT, WHERE, JOIN
- Updating and deleting records
- Aggregate functions (COUNT, AVG)
- Transaction-like sequential execution (stops on error)

**Requirements:**
```bash
gem install sqlite3
```

**Additional Requirements:**
- None (uses in-memory database)

**Run it:**
```bash
./database_tool_example.rb
```

**Key Features:**
- Uses in-memory SQLite database
- Demonstrates foreign key relationships
- Shows error handling and transaction behavior
- Includes aggregate queries and statistics

---

### 4. Computer Tool Example (`computer_tool_example.rb`)

Demonstrates system automation capabilities including:
- Mouse movements and positioning
- Mouse clicks (single, double, triple)
- Right-click context menus
- Drag and drop operations
- Keyboard input (typing text)
- Keyboard shortcuts (Cmd+C, Cmd+V, etc.)
- Holding keys for duration
- Scrolling
- Automated form filling
- Text selection workflows

**Requirements:**
```bash
gem install macos  # macOS only
```

**Additional Requirements:**
- macOS operating system
- Accessibility permissions granted:
  - System Preferences → Security & Privacy → Privacy → Accessibility
  - Add Terminal or your IDE to the allowed applications

**Run it:**
```bash
./computer_tool_example.rb
```

**Key Features:**
- Uses mock driver for demonstration
- Shows all mouse and keyboard actions
- Includes complete automation workflows
- Note: For real system automation on macOS, requires `macos` gem and accessibility permissions

---

### 5. Eval Tool Example (`eval_tool_example.rb`)

Demonstrates code evaluation capabilities including:
- Evaluating Ruby code with results and console output
- Evaluating Python code (if python3 is available)
- Executing shell commands with output capture
- Handling errors in code execution
- Using authorization system for safe execution
- Practical calculator example

**Requirements:**
- None (uses standard Ruby libraries)

**Additional Requirements:**
- Python installed (for Python evaluation examples)
- Shell access (for shell command examples)

**Run it:**
```bash
./eval_tool_example.rb
```

**Key Features:**
- Supports Ruby, Python, and Shell code execution
- Built-in authorization system (bypassed for demo with auto_execute)
- Captures both output and result values
- Error handling with detailed messages
- Individual tools can be used directly for more control

**Security Note:**
- Auto-execution is enabled for this demo only
- In production, always use `SharedTools.auto_execute(false)` to require user confirmation

---

### 6. Doc Tool Example (`doc_tool_example.rb`)

Demonstrates PDF document processing including:
- Reading single pages from PDF documents
- Reading multiple specific pages
- Handling invalid page numbers gracefully
- Extracting text for search and analysis
- Document statistics (word count, character count)
- Finding section headers
- Word frequency analysis

**Requirements:**
```bash
gem install pdf-reader
```

**Additional Requirements:**
- A sample PDF file (the example looks for `test/fixtures/test.pdf`)

**Run it:**
```bash
./doc_tool_example.rb
```

**Key Features:**
- Uses the test fixture PDF (automatically available)
- Demonstrates single and multi-page extraction
- Shows practical text analysis examples
- Error handling for missing files and invalid pages
- Individual PdfReaderTool can be used directly

---

### 7. Comprehensive Workflow Example (`comprehensive_workflow_example.rb`)

Demonstrates using multiple tools together in a realistic scenario:

**Workflow:** Web Scraping → Database Storage → Report Generation

1. **Phase 1: Web Scraping**
   - Uses BrowserTool to scrape product data from HTML
   - Parses HTML with Nokogiri
   - Extracts structured product information

2. **Phase 2: Database Storage**
   - Uses DatabaseTool to create tables
   - Stores scraped products in SQLite
   - Generates statistics and analytics

3. **Phase 3: Report Generation**
   - Uses DiskTool to create report directory
   - Generates reports in multiple formats:
     - Markdown summary report
     - JSON data export
     - CSV data export

**Requirements:**
```bash
gem install sqlite3
```

**Additional Requirements:**
- None

**Run it:**
```bash
./comprehensive_workflow_example.rb
```

**Key Features:**
- Shows real-world integration of multiple tools
- Demonstrates data pipeline: scrape → store → report
- Generates reports in multiple formats
- Preserves output directory for inspection

---

## General Usage Patterns

### Tool Initialization

All tools follow a similar initialization pattern:

```ruby
# With default driver
tool = SharedTools::Tools::BrowserTool.new

# With custom driver
driver = CustomDriver.new
tool = SharedTools::Tools::BrowserTool.new(driver: driver)

# With custom logger
logger = Logger.new(STDOUT)
tool = SharedTools::Tools::DiskTool.new(logger: logger)
```

### Executing Actions

Tools use a consistent `execute` method with named parameters:

```ruby
result = tool.execute(
  action: ActionConstant,
  param1: value1,
  param2: value2
)
```

### Action Constants

Each tool defines action constants in its module:

```ruby
# Browser actions
SharedTools::Tools::BrowserTool::Action::VISIT
SharedTools::Tools::BrowserTool::Action::CLICK

# Disk actions
SharedTools::Tools::DiskTool::Action::FILE_CREATE
SharedTools::Tools::DiskTool::Action::DIRECTORY_LIST

# Computer actions
SharedTools::Tools::ComputerTool::Action::MOUSE_CLICK
SharedTools::Tools::ComputerTool::Action::TYPE

# Eval actions
SharedTools::Tools::EvalTool::Action::RUBY
SharedTools::Tools::EvalTool::Action::PYTHON
SharedTools::Tools::EvalTool::Action::SHELL

# Doc actions
SharedTools::Tools::DocTool::Action::PDF_READ

# Database - uses SQL statements directly
database.execute(statements: ["SELECT * FROM users"])
```

## Running All Examples

To run all examples sequentially:

```bash
for example in examples/*.rb; do
  echo "Running $example..."
  ruby "$example"
  echo ""
done
```

## Production Usage

These examples use mock drivers for demonstration. In production:

1. **BrowserTool**: Install `watir` gem and use real browser drivers
   ```bash
   gem install watir webdrivers
   ```

2. **ComputerTool**: On macOS, the tool works with system automation
   (requires accessibility permissions)

3. **DatabaseTool**: Works with any database that has a compatible driver
   (SQLite, PostgreSQL, MySQL, etc.)

4. **DiskTool**: Uses `LocalDriver` with sandboxed root directory for security

## Environment Variables

For LLM provider configuration:

```bash
# For OpenAI
export OPENAI_API_KEY="your-api-key-here"

# For Anthropic
export ANTHROPIC_API_KEY="your-api-key-here"

# For Ollama (default: http://localhost:11434)
export OLLAMA_HOST="http://localhost:11434"
```

## Troubleshooting

### "LoadError: cannot load such file - ruby_llm"

The RubyLLM framework is not installed. Install it:

```bash
gem install ruby_llm
```

### LLM connection errors

**Ollama connection refused:**
1. Make sure Ollama is running: `ollama serve`
2. Verify the model is pulled: `ollama list`
3. Check Ollama is listening on default port (11434)

**OpenAI/Anthropic API errors:**
1. Verify your API key is set in environment variables
2. Check your API key has sufficient credits/permissions
3. Verify network connectivity to the API endpoint

### "LoadError: cannot load such file"

This means a required gem is not installed. Read the error message carefully - it will tell you which gem is missing. Install it using:

```bash
gem install <gem-name>
```

### Browser automation fails

1. Make sure Chrome (or your preferred browser) is installed
2. Check that `webdrivers` gem is installed: `gem install webdrivers`
3. Try running with a visible browser (non-headless) for debugging

### Computer automation fails on macOS

1. Grant accessibility permissions:
   - System Preferences → Security & Privacy → Privacy → Accessibility
   - Add your Terminal app or IDE
   - Restart the application after granting permissions

### PDF reading fails

1. Make sure `pdf-reader` gem is installed: `gem install pdf-reader`
2. Verify the PDF file exists at the specified path
3. Check that the PDF is not corrupted or password-protected

## Further Reading

- [SharedTools Documentation](../README.md)
- [RubyLLM Framework](https://github.com/mariochavez/ruby_llm)
- [Tool Source Code](../lib/shared_tools/tools/)

## Contributing

Have an interesting use case? Consider contributing an example!

1. Create a new example file
2. Follow the existing pattern (descriptive comments, clear sections)
3. Make it runnable with minimal dependencies
4. Add it to this README

## License

All examples are released under the same MIT license as SharedTools.
