# Examples

This section contains practical examples demonstrating how to use SharedTools in your LLM applications.

## Available Examples

### Basic Tool Examples

Each tool has a dedicated example file in the `/examples` directory showing basic usage:

#### [Browser Tool Example](https://github.com/madbomber/shared_tools/blob/main/examples/browser_tool_example.rb)
Demonstrates web automation capabilities including:

- Navigating to web pages
- Inspecting page content and HTML
- Finding elements by text or CSS selectors
- Clicking elements
- Filling in forms
- Taking screenshots

```ruby
require 'shared_tools'

# Initialize browser tool with Watir driver
browser = SharedTools::Tools::BrowserTool.new

# Navigate to a website
browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::VISIT,
  url: "https://example.com"
)

# Get page summary
summary = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::PAGE_INSPECT
)
```

#### [Disk Tool Example](https://github.com/madbomber/shared_tools/blob/main/examples/disk_tool_example.rb)
Shows file system operations including:

- Creating and deleting directories
- Reading and writing files
- Moving files and directories
- Listing directory contents
- Replacing text in files

```ruby
require 'shared_tools'

# Initialize disk tool
disk = SharedTools::Tools::DiskTool.new

# Create a file
disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_CREATE,
  path: "./demo.txt"
)

# Write content
disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_WRITE,
  path: "./demo.txt",
  text: "Hello, World!"
)

# Read content
content = disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_READ,
  path: "./demo.txt"
)
```

#### [Database Tool Example](https://github.com/madbomber/shared_tools/blob/main/examples/database_tool_example.rb)
Illustrates database operations including:

- Creating tables
- Inserting data
- Querying with SELECT statements
- Updating and deleting records
- Transaction handling

```ruby
require 'shared_tools'
require 'sqlite3'

# Setup database connection
db = SQLite3::Database.new(':memory:')
driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)

# Execute SQL statements
results = database.execute(
  statements: [
    "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)",
    "INSERT INTO users (name) VALUES ('Alice')",
    "SELECT * FROM users"
  ]
)
```

#### [Computer Tool Example](https://github.com/madbomber/shared_tools/blob/main/examples/computer_tool_example.rb)
Demonstrates system-level operations:

- Taking screenshots
- Getting screen information
- Performing mouse actions
- Keyboard input simulation
- Accessing system clipboard

```ruby
require 'shared_tools'

# Initialize computer tool (Mac-specific in this example)
computer = SharedTools::Tools::ComputerTool.new

# Take a screenshot
screenshot = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::SCREENSHOT
)

# Get screen dimensions
info = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::SCREEN_INFO
)
```

#### [Eval Tool Example](https://github.com/madbomber/shared_tools/blob/main/examples/eval_tool_example.rb)
Shows code evaluation capabilities:

- Ruby code evaluation
- Python code evaluation (with safe sandboxing)
- Shell command execution
- Error handling and output capture

```ruby
require 'shared_tools'

# Initialize eval tool
eval_tool = SharedTools::Tools::EvalTool.new

# Evaluate Ruby code
result = eval_tool.execute(
  language: 'ruby',
  code: 'puts [1, 2, 3].sum'
)

# Execute shell commands
output = eval_tool.execute(
  language: 'shell',
  code: 'ls -la'
)
```

#### [Doc Tool Example](https://github.com/madbomber/shared_tools/blob/main/examples/doc_tool_example.rb)
Demonstrates document processing:

- Reading PDF files
- Extracting text from specific pages
- Processing multi-page documents
- Handling PDF metadata

```ruby
require 'shared_tools'

# Initialize doc tool
doc = SharedTools::Tools::DocTool.new

# Read PDF content
content = doc.execute(
  action: 'read_pdf',
  path: './document.pdf',
  page: 1
)
```

### Advanced Workflow Example

#### [Comprehensive Workflow Example](https://github.com/madbomber/shared_tools/blob/main/examples/comprehensive_workflow_example.rb)
A complete end-to-end example showing how multiple tools work together in a realistic workflow:

**Scenario**: Web Scraping to Database with Report Generation

This example demonstrates:

1. **Web Scraping Phase**
   - Using BrowserTool to navigate to a product catalog
   - Extracting structured data from HTML
   - Parsing and transforming the data

2. **Database Storage Phase**
   - Creating database tables with DatabaseTool
   - Inserting scraped data
   - Performing queries and aggregations
   - Generating statistics

3. **Report Generation Phase**
   - Using DiskTool to create report directories
   - Generating Markdown reports
   - Exporting data to JSON and CSV formats
   - Organizing output files

```ruby
# Phase 1: Scrape data
browser = SharedTools::Tools::BrowserTool.new(driver: browser_driver)
browser.execute(action: "visit", url: "https://example.com/products")
html = browser.execute(action: "page_inspect", full_html: true)

# Phase 2: Store in database
database = SharedTools::Tools::DatabaseTool.new(driver: db_driver)
database.execute(statements: [
  "CREATE TABLE products (...)",
  "INSERT INTO products VALUES (...)"
])

# Phase 3: Generate reports
disk = SharedTools::Tools::DiskTool.new
disk.execute(action: "file_write", path: "./report.md", text: report_content)
```

See the [Workflows Guide](./workflows.md) for a detailed breakdown of this example.

## Running the Examples

All examples are located in the `/examples` directory and can be run directly:

```bash
# Install dependencies first
bundle install

# Run a specific example
ruby examples/browser_tool_example.rb
ruby examples/comprehensive_workflow_example.rb
```

## Mock Drivers for Testing

Many examples include mock driver implementations that demonstrate the driver interface pattern:

- **MockBrowserDriver**: Simulates browser behavior without requiring a real browser
- **SimpleSqliteDriver**: Minimal database driver implementation
- **LocalDriver**: File system operations within a specified root directory

These mock drivers are useful for:

- Understanding the driver interface requirements
- Testing without external dependencies
- Creating your own custom drivers

## Next Steps

- Learn about [Multi-Tool Workflows](./workflows.md)
- Explore the [Tool API Reference](../api/index.md)
- Read about [Testing Your Tools](../guides/testing.md)
- Understand [Error Handling Patterns](../guides/error-handling.md)

## Example Categories

### By Tool Type

- **Browser Automation**: [browser_tool_example.rb](https://github.com/madbomber/shared_tools/blob/main/examples/browser_tool_example.rb)
- **File System**: [disk_tool_example.rb](https://github.com/madbomber/shared_tools/blob/main/examples/disk_tool_example.rb)
- **Database**: [database_tool_example.rb](https://github.com/madbomber/shared_tools/blob/main/examples/database_tool_example.rb)
- **System Control**: [computer_tool_example.rb](https://github.com/madbomber/shared_tools/blob/main/examples/computer_tool_example.rb)
- **Code Execution**: [eval_tool_example.rb](https://github.com/madbomber/shared_tools/blob/main/examples/eval_tool_example.rb)
- **Document Processing**: [doc_tool_example.rb](https://github.com/madbomber/shared_tools/blob/main/examples/doc_tool_example.rb)

### By Complexity

- **Beginner**: Single-tool examples showing basic operations
- **Intermediate**: Examples with custom drivers and error handling
- **Advanced**: [comprehensive_workflow_example.rb](https://github.com/madbomber/shared_tools/blob/main/examples/comprehensive_workflow_example.rb) showing multi-tool integration

### By Use Case

- **Data Collection**: Web scraping and extraction
- **Data Processing**: Database operations and transformations
- **Report Generation**: Creating output files in multiple formats
- **System Automation**: Orchestrating multiple tools together

## Common Patterns

### Human-in-the-Loop Authorization

All tools respect the SharedTools authorization system:

```ruby
# Require user confirmation (default)
SharedTools.auto_execute(false)

# The AI will ask permission before executing
disk.execute(action: "file_delete", path: "./important.txt")

# Auto-execute for automated workflows
SharedTools.auto_execute(true)
```

### Error Handling

Examples demonstrate proper error handling:

```ruby
begin
  result = database.execute(statements: ["SELECT * FROM missing_table"])
  if result.first[:status] == :error
    puts "Database error: #{result.first[:result]}"
  end
rescue => e
  puts "Unexpected error: #{e.message}"
end
```

### Cleanup and Resource Management

Examples show proper resource cleanup:

```ruby
browser = SharedTools::Tools::BrowserTool.new
begin
  # Use the tool
  browser.execute(action: "visit", url: "https://example.com")
ensure
  # Always cleanup
  browser.cleanup!
end
```

## Contributing Examples

Have a great example to share? See our [Contributing Guide](../development/contributing.md) for information on submitting examples.

Good examples:

- Solve a real-world problem
- Are well-commented and explain the "why"
- Include error handling
- Clean up resources properly
- Can run independently with minimal setup
