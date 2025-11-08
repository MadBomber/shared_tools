# Tools Overview

SharedTools provides a collection of LLM-callable tools for common operations. Each tool follows a consistent facade pattern with an action-based interface.

## Available Tools

### [BrowserTool](browser.md)

Web browser automation using Watir for visiting pages, inspecting content, clicking elements, filling forms, and capturing screenshots.

**Key Features:**

- Navigate to URLs
- Inspect page content and DOM
- Find elements by text or CSS selectors
- Click buttons and links
- Fill input fields
- Take screenshots

**Example:**

```ruby
browser = SharedTools::Tools::BrowserTool.new
browser.execute(action: "visit", url: "https://example.com")
browser.execute(action: "click", selector: "button.login")
```

[View BrowserTool Documentation →](browser.md)

---

### [DiskTool](disk.md)

Secure file system operations with path traversal protection for managing files and directories.

**Key Features:**

- Create, read, write, delete files
- Create, list, move, delete directories
- Find and replace text in files
- Path security (sandboxing)

**Example:**

```ruby
disk = SharedTools::Tools::DiskTool.new
disk.execute(action: "file_write", path: "./data.txt", text: "Hello")
content = disk.execute(action: "file_read", path: "./data.txt")
```

[View DiskTool Documentation →](disk.md)

---

### [EvalTool](eval.md)

Execute code in multiple languages (Ruby, Python, Shell) with authorization controls.

**Key Features:**

- Execute Ruby code
- Execute Python scripts
- Run shell commands
- Authorization system for safety

**Example:**

```ruby
eval_tool = SharedTools::Tools::EvalTool.new
result = eval_tool.execute(action: "ruby", code: "[1,2,3].sum")
# => 6
```

[View EvalTool Documentation →](eval.md)

---

### [DocTool](doc.md)

Read and process document formats, currently supporting PDF files.

**Key Features:**

- Read specific PDF pages
- Support for page ranges
- Extract text content

**Example:**

```ruby
doc = SharedTools::Tools::DocTool.new
result = doc.execute(
  action: "pdf_read",
  doc_path: "./report.pdf",
  page_numbers: "1-5"
)
```

[View DocTool Documentation →](doc.md)

---

### [DatabaseTool](database.md)

Execute SQL statements against SQLite or PostgreSQL databases.

**Key Features:**

- Execute SELECT, INSERT, UPDATE, DELETE
- Transaction-like execution (stops on error)
- Support for multiple databases
- Pluggable driver architecture

**Example:**

```ruby
driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)
database.execute(statements: ["SELECT * FROM users"])
```

[View DatabaseTool Documentation →](database.md)

---

### [ComputerTool](computer.md)

System-level automation for mouse, keyboard, and screen control.

**Key Features:**

- Mouse click, move, and position tracking
- Keyboard typing and key press simulation
- Scroll control
- Wait functionality for timing

**Example:**

```ruby
computer = SharedTools::Tools::ComputerTool.new
computer.execute(action: "mouse_click", coordinate: {x: 100, y: 200})
computer.execute(action: "type", text: "Hello, World!")
```

[View ComputerTool Documentation →](computer.md)

---

### CalculatorTool

Safe mathematical calculations without code execution risks.

**Key Features:**

- Safe expression evaluation using Dentaku
- Basic arithmetic and mathematical functions
- Trigonometric operations
- Configurable precision (0-10 decimal places)
- Comprehensive error handling

**Example:**

```ruby
calculator = SharedTools::Tools::CalculatorTool.new
calculator.execute(expression: "sqrt(16) * 2", precision: 4)
# => {success: true, result: 8.0, precision: 4}
```

---

### WeatherTool

Real-time weather data from OpenWeatherMap API.

**Key Features:**

- Current weather conditions worldwide
- Multiple temperature units (metric, imperial, kelvin)
- Optional 3-day forecast
- Atmospheric data (humidity, pressure, wind)
- Requires OPENWEATHER_API_KEY environment variable

**Example:**

```ruby
weather = SharedTools::Tools::WeatherTool.new
weather.execute(city: "London,UK", units: "metric", include_forecast: true)
# => {success: true, current: {...}, forecast: [...]}
```

---

### WorkflowManagerTool

Manage complex multi-step workflows with persistent state tracking.

**Key Features:**

- Create and track stateful workflows
- Step-by-step execution with persistence
- Status monitoring and progress tracking
- Workflow completion and cleanup
- Survives process restarts

**Example:**

```ruby
workflow = SharedTools::Tools::WorkflowManagerTool.new
result = workflow.execute(action: "start", step_data: {project: "demo"})
workflow_id = result[:workflow_id]
workflow.execute(action: "step", workflow_id: workflow_id, step_data: {task: "compile"})
```

---

### CompositeAnalysisTool

Multi-stage data analysis orchestration for comprehensive insights.

**Key Features:**

- Automatic data source detection (files or URLs)
- Data structure analysis
- Statistical insights generation
- Visualization suggestions
- Correlation analysis
- Supports CSV, JSON, and text formats

**Example:**

```ruby
analyzer = SharedTools::Tools::CompositeAnalysisTool.new
analyzer.execute(
  data_source: "./sales_data.csv",
  analysis_type: "comprehensive",
  options: {include_correlations: true}
)
```

---

### DatabaseQueryTool

Safe, read-only database query execution with security controls.

**Key Features:**

- SELECT-only queries for security
- Automatic LIMIT clause enforcement
- Query timeout protection
- Prepared statement support
- Connection pooling
- Supports PostgreSQL, MySQL, SQLite, and more

**Example:**

```ruby
db_query = SharedTools::Tools::DatabaseQueryTool.new
db_query.execute(
  query: "SELECT * FROM users WHERE active = ?",
  params: [true],
  limit: 50
)
```

---

### Docker ComposeRunTool

Execute Docker Compose commands safely within containers.

**Key Features:**

- Run commands in Docker containers
- Service specification support
- Automatic container cleanup
- Build and run in one step
- Working directory support

**Example:**

```ruby
docker = SharedTools::Tools::Docker::ComposeRunTool.new
docker.execute(
  service: "app",
  command: "rspec",
  args: ["spec/main_spec.rb"]
)
```

---

### ErrorHandlingTool

Reference implementation demonstrating robust error handling patterns.

**Key Features:**

- Multiple error type handling
- Retry mechanisms with exponential backoff
- Input/output validation
- Resource cleanup patterns
- Detailed error categorization
- Support reference IDs for debugging

**Example:**

```ruby
error_tool = SharedTools::Tools::ErrorHandlingTool.new
error_tool.execute(
  operation: "process",
  data: {name: "test", value: 42},
  max_retries: 3
)
```

---

## Tool Architecture

All tools share common architectural patterns:

### Facade Pattern

Each tool acts as a facade, providing a unified interface to complex operations:

```ruby
# Single tool, multiple related actions
tool.execute(action: "action_one", params...)
tool.execute(action: "action_two", params...)
```

### Action-Based Interface

Tools use an action parameter to specify the operation:

```ruby
tool.execute(
  action: "specific_action",
  param1: "value1",
  param2: "value2"
)
```

### Driver Architecture

Tools delegate to driver implementations for flexibility:

```ruby
# Use built-in driver
tool = SharedTools::Tools::SomeTool.new

# Or provide custom driver
custom_driver = MyCustomDriver.new
tool = SharedTools::Tools::SomeTool.new(driver: custom_driver)
```

### Authorization Integration

Tools respect the global authorization setting:

```ruby
# Default: requires confirmation
SharedTools.execute?(tool: 'tool_name', stuff: 'operation details')

# Disable for automation
SharedTools.auto_execute(true)
```

## Tool Comparison

| Tool | Primary Use | Authorization | Requires External Gem |
|------|-------------|---------------|----------------------|
| BrowserTool | Web automation | No | Yes (watir) |
| DiskTool | File operations | No | No |
| EvalTool | Code execution | Yes | No (Python for python action) |
| DocTool | Document processing | No | Yes (pdf-reader) |
| DatabaseTool | SQL operations | No | Yes (sqlite3 or pg) |
| ComputerTool | System automation | No | Yes (platform-specific) |
| CalculatorTool | Math calculations | No | Yes (dentaku - included) |
| WeatherTool | Weather data | No | Yes (openweathermap - included) |
| WorkflowManagerTool | Workflow orchestration | No | No |
| CompositeAnalysisTool | Data analysis | No | No |
| DatabaseQueryTool | Read-only SQL queries | No | Yes (sequel - included) |
| Docker ComposeRunTool | Container commands | No | No (requires Docker) |
| ErrorHandlingTool | Reference/example | No | No |

## Common Usage Patterns

### Pattern 1: Resource Management

```ruby
tool = SharedTools::Tools::BrowserTool.new
begin
  tool.execute(action: "visit", url: "https://example.com")
  # Do work...
ensure
  tool.cleanup!  # Always clean up
end
```

### Pattern 2: Error Handling

```ruby
begin
  result = tool.execute(action: "some_action", param: "value")
rescue ArgumentError => e
  puts "Invalid parameters: #{e.message}"
rescue StandardError => e
  puts "Operation failed: #{e.message}"
end
```

### Pattern 3: Multi-Tool Workflows

```ruby
# Combine tools for complex workflows
browser = SharedTools::Tools::BrowserTool.new
disk = SharedTools::Tools::DiskTool.new
database = SharedTools::Tools::DatabaseTool.new(driver: driver)

# 1. Scrape data
html = browser.execute(action: "page_inspect", full_html: true)

# 2. Save raw data
disk.execute(action: "file_write", path: "./raw.html", text: html)

# 3. Store in database
database.execute(statements: ["INSERT INTO pages (content) VALUES ('#{html}')"])

browser.cleanup!
```

## Tool Selection Guide

### Choose BrowserTool when you need to:

- Interact with web pages
- Fill forms and click buttons
- Scrape dynamic content
- Take screenshots of web pages

### Choose DiskTool when you need to:

- Read or write files
- Manage directory structures
- Search and replace in files
- Work with the file system safely

### Choose EvalTool when you need to:

- Execute Ruby code dynamically
- Run Python scripts
- Execute shell commands
- Process data with code

### Choose DocTool when you need to:

- Extract text from PDFs
- Read specific document pages
- Process document content

### Choose DatabaseTool when you need to:

- Execute SQL queries
- Manage database records
- Perform CRUD operations
- Work with relational data

### Choose ComputerTool when you need to:

- Automate mouse and keyboard actions
- Control system-level operations
- Simulate user interactions
- Automate GUI applications

### Choose CalculatorTool when you need to:

- Perform safe mathematical calculations
- Evaluate mathematical expressions
- Avoid code execution risks
- Get precise numeric results

### Choose WeatherTool when you need to:

- Get real-time weather data
- Access weather forecasts
- Retrieve atmospheric conditions
- Work with weather APIs

### Choose WorkflowManagerTool when you need to:

- Manage multi-step processes
- Track workflow state across sessions
- Coordinate complex operations
- Persist workflow progress

### Choose CompositeAnalysisTool when you need to:

- Analyze data from multiple sources
- Generate statistical insights
- Get visualization suggestions
- Perform correlation analysis

### Choose DatabaseQueryTool when you need to:

- Execute read-only database queries
- Ensure query security with SELECT-only access
- Manage query timeouts
- Use parameterized queries safely

### Choose Docker ComposeRunTool when you need to:

- Run commands in containers
- Execute tests in isolated environments
- Work with Docker Compose services
- Automate containerized workflows

## Next Steps

- View detailed documentation for each tool
- [Basic Usage Guide](../getting-started/basic-usage.md) - Learn common patterns
- [Authorization System](../guides/authorization.md) - Control operation approval
- [Working with Drivers](../guides/drivers.md) - Create custom drivers
