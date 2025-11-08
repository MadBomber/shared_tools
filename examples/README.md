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

### 8. Calculator Tool Example (`calculator_tool_example.rb`)

Demonstrates safe mathematical calculations including:
- Basic arithmetic operations (+, -, *, /)
- Complex expressions with parentheses
- Square root and exponentiation
- Percentage calculations
- Precision control for decimal results
- Rounding operations
- Multi-step calculations with conversational context

**Requirements:**
```bash
gem install dentaku
```

**Additional Requirements:**
- None

**Run it:**
```bash
./calculator_tool_example.rb
```

**Key Features:**
- Uses Dentaku for safe math evaluation (no code injection)
- Supports mathematical functions (sqrt, round, pow, etc.)
- Configurable decimal precision
- Natural language to mathematical expressions
- Maintains conversational context across calculations

**⚠️ Note on Modern LLM Capabilities:**
Modern LLMs (GPT-4, Claude 3+, Gemini, and even advanced open-source models like those from Meta and Mistral) have excellent built-in arithmetic capabilities and can accurately perform most mathematical calculations without requiring a calculator tool. This example demonstrates the tool architecture and safety patterns (using Dentaku to prevent code injection), but in practice, **this tool may be largely unnecessary with today's frontier and advanced open-source models**.

The tool might still be useful for:
- **Legacy or smaller models** with weaker math capabilities
- **Extremely high-precision calculations** where you need exact decimal control
- **Compliance/audit requirements** where calculations must be verifiably performed by a specific evaluator
- **Learning purposes** to understand tool integration patterns

---

### 9. Weather Tool Example (`weather_tool_example.rb`)

Demonstrates weather data retrieval including:
- Current weather conditions for cities worldwide
- Temperature, humidity, wind, and atmospheric data
- Multiple unit systems (metric, imperial, kelvin)
- 3-day weather forecasts
- Multi-city comparisons
- Real-time API integration

**Requirements:**
```bash
gem install openweathermap
```

**Additional Requirements:**
- OpenWeatherMap API key (free at https://openweathermap.org/api)
- Set `OPENWEATHER_API_KEY` environment variable
- Active internet connection

**Run it:**
```bash
export OPENWEATHER_API_KEY="your-key-here"
./weather_tool_example.rb
```

**Key Features:**
- Real-time weather data from OpenWeatherMap API
- Supports metric, imperial, and kelvin units
- Includes current conditions and forecasts
- Natural language weather queries
- Conversational context maintenance

---

### 10. Workflow Manager Tool Example (`workflow_manager_tool_example.rb`)

Demonstrates stateful workflow management including:
- Creating and initializing workflows
- Adding sequential workflow steps
- Checking workflow status and progress
- Managing workflow metadata
- Completing workflows with summaries
- Persistent state across process restarts
- Multiple concurrent workflows

**Requirements:**
- None (uses standard Ruby libraries)

**Additional Requirements:**
- None (uses temporary storage)

**Run it:**
```bash
./workflow_manager_tool_example.rb
```

**Key Features:**
- Stateful workflow management with persistence
- Unique workflow IDs for tracking
- Step-by-step execution with metadata
- Status monitoring and progress tracking
- Automatic state persistence to disk
- Workflow completion summaries
- Perfect for coordinating complex multi-step processes

---

### 11. Composite Analysis Tool Example (`composite_analysis_tool_example.rb`)

Demonstrates comprehensive data analysis including:
- Multi-stage data analysis orchestration
- Data structure analysis
- Statistical insights generation
- Visualization recommendations
- Correlation analysis
- Support for CSV, JSON, and web data sources
- Three analysis levels (quick, standard, comprehensive)

**Requirements:**
- None (uses standard Ruby libraries with simulated data)

**Additional Requirements:**
- None (examples use simulated data)

**Run it:**
```bash
./composite_analysis_tool_example.rb
```

**Key Features:**
- Automatically detects data format (CSV, JSON, text)
- Three analysis modes: quick, standard, comprehensive
- Generates structure, insights, and visualization suggestions
- Supports both file paths and web URLs
- Comprehensive correlation analysis
- Perfect for exploratory data analysis

---

### 12. Data Science Kit Example (`data_science_kit_example.rb`)

Demonstrates advanced data science operations including:
- Statistical summary with distributions and outliers
- Correlation analysis (Pearson and Spearman)
- Time series analysis with forecasting
- K-means and hierarchical clustering
- Predictive modeling and regression
- Custom parameters for fine-tuned analysis

**Requirements:**
- None (uses standard Ruby libraries with simulated data)

**Additional Requirements:**
- None (examples use simulated data)

**Run it:**
```bash
./data_science_kit_example.rb
```

**Key Features:**
- Five analysis types: statistical_summary, correlation_analysis, time_series, clustering, prediction
- Supports multiple ML algorithms and methods
- Automatic data loading and preprocessing
- Detailed results with visualization recommendations
- Custom parameter support for advanced users
- Conversational context across analysis steps

---

### 13. Database Query Tool Example (`database_query_tool_example.rb`)

Demonstrates safe, read-only database queries including:
- SELECT-only queries (no data modification)
- Parameterized queries for SQL injection prevention
- Automatic LIMIT enforcement
- Query timeout protection
- Join operations and aggregations
- Connection pooling with automatic cleanup

**Requirements:**
```bash
gem install sequel sqlite3
```

**Additional Requirements:**
- None (uses in-memory database for examples)

**Run it:**
```bash
./database_query_tool_example.rb
```

**Key Features:**
- Read-only security (SELECT statements only)
- Parameterized query support prevents SQL injection
- Automatic connection management
- Query timeout protection
- Works with any Sequel-supported database
- Perfect for AI-assisted data analysis and reporting

---

### 14. DevOps Toolkit Example (`devops_toolkit_example.rb`)

Demonstrates DevOps operations including:
- Application deployments across environments
- Rollback capabilities for failed deployments
- Health checks and system monitoring
- Log analysis and error detection
- Metrics collection and reporting
- Production safety mechanisms with confirmations

**Requirements:**
- None (uses standard Ruby libraries)

**Additional Requirements:**
- None (examples simulate DevOps operations)

**Run it:**
```bash
./devops_toolkit_example.rb
```

**Key Features:**
- Environment-specific restrictions (dev, staging, production)
- Production operations require explicit confirmation
- All operations logged with unique operation IDs
- Supports deployments, rollbacks, health checks, logs, and metrics
- Built-in safety mechanisms prevent accidents
- Audit trail for compliance requirements

---

### 15. Error Handling Tool Example (`error_handling_tool_example.rb`)

Demonstrates comprehensive error handling patterns including:
- Input validation with helpful suggestions
- Network retry with exponential backoff
- Authorization checks and errors
- Resource cleanup in ensure blocks
- Detailed error categorization
- Operation metadata tracking
- Configurable retry mechanisms

**Requirements:**
- None (uses standard Ruby libraries)

**Additional Requirements:**
- None

**Run it:**
```bash
./error_handling_tool_example.rb
```

**Key Features:**
- Reference implementation for robust tool development
- Demonstrates all major error types and handling patterns
- Retry mechanism with exponential backoff
- Proper resource cleanup
- Unique reference IDs for error tracking
- Detailed error messages with suggestions
- Perfect reference for building production-ready tools

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
