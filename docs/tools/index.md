# Tools Overview

SharedTools provides a collection of LLM-callable tools for common operations. Each tool follows a consistent facade pattern with an action-based interface.

## Core Tools

### [BrowserTool](browser.md)

Web browser automation using Watir for visiting pages, inspecting content, clicking elements, filling forms, and capturing screenshots.

**Actions:** `visit`, `page_inspect`, `ui_inspect`, `selector_inspect`, `click`, `text_field_set`, `screenshot`

```ruby
browser = SharedTools::Tools::BrowserTool.new
browser.execute(action: "visit", url: "https://example.com")
browser.execute(action: "click", selector: "button.login")
```

[View BrowserTool Documentation →](browser.md)

---

### [DiskTool](disk.md)

Secure file system operations with path traversal protection.

**Actions:** `file_create`, `file_read`, `file_write`, `file_delete`, `file_move`, `file_replace`, `directory_create`, `directory_list`, `directory_move`, `directory_delete`

```ruby
disk = SharedTools::Tools::DiskTool.new
disk.execute(action: "file_write", path: "./data.txt", text: "Hello")
content = disk.execute(action: "file_read", path: "./data.txt")
```

[View DiskTool Documentation →](disk.md)

---

### [EvalTool](eval.md)

Execute code in multiple languages with authorization controls.

**Languages:** `ruby`, `python`, `shell`

```ruby
eval_tool = SharedTools::Tools::EvalTool.new
result = eval_tool.execute(language: "ruby", code: "[1,2,3].sum")
```

[View EvalTool Documentation →](eval.md)

---

### [DocTool](doc.md)

Read and process documents: plain text, PDF, Word (.docx), and spreadsheets (CSV, XLSX, ODS, XLSM).

**Actions:** `text_read`, `pdf_read`, `docx_read`, `spreadsheet_read`

```ruby
doc = SharedTools::Tools::DocTool.new

doc.execute(action: "text_read", doc_path: "./notes.txt")
doc.execute(action: "pdf_read", doc_path: "./report.pdf", page_numbers: "1-5")
doc.execute(action: "docx_read", doc_path: "./meeting.docx")
doc.execute(action: "spreadsheet_read", doc_path: "./data.xlsx", sheet: "Q1")
```

[View DocTool Documentation →](doc.md)

---

### [DatabaseTool](database.md)

Execute SQL statements (CREATE, INSERT, SELECT, UPDATE, DELETE) with pluggable drivers.

```ruby
driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)
database.execute(statements: ["SELECT * FROM users"])
```

[View DatabaseTool Documentation →](database.md)

---

### [DatabaseQueryTool](database.md)

Safe, read-only SQL queries with automatic LIMIT enforcement and timeout protection.

```ruby
db_query = SharedTools::Tools::DatabaseQueryTool.new
db_query.execute(query: "SELECT * FROM users WHERE active = ?", params: [true], limit: 50)
```

[View DatabaseQueryTool Documentation →](database.md)

---

### [ComputerTool](computer.md)

System-level automation for mouse, keyboard, and screen control.

**Actions:** `mouse_click`, `mouse_move`, `mouse_position`, `type`, `key`, `hold_key`, `scroll`, `wait`

```ruby
computer = SharedTools::Tools::ComputerTool.new
computer.execute(action: "mouse_click", coordinate: {x: 100, y: 200})
computer.execute(action: "type", text: "Hello, World!")
```

[View ComputerTool Documentation →](computer.md)

---

## Data & Analysis Tools

### [CalculatorTool](calculator.md)

Safe mathematical expression evaluation using the Dentaku parser.

**Features:** Basic arithmetic, math functions (sqrt, round, abs), trigonometry (sin, cos, tan), configurable precision

```ruby
calculator = SharedTools::Tools::CalculatorTool.new
calculator.execute(expression: "sqrt(16) * 2", precision: 4)
# => {success: true, result: 8.0}
```

[View CalculatorTool Documentation →](calculator.md)

---

### [DataScienceKit](data_science_kit.md)

Real statistical analysis performed on actual data — not simulated results.

**Analysis types:** `statistical_summary`, `correlation_analysis`, `time_series`, `clustering`, `prediction`

**Data sources:** File path (`data_source`) or inline string (`data`) — supports pipe-delimited tables, CSV, JSON, and comma-separated numbers.

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

[View DataScienceKit Documentation →](data_science_kit.md)

---

### CompositeAnalysisTool

Multi-stage data analysis orchestration for comprehensive insights.

**Features:** Automatic data source detection, structure analysis, statistical insights, visualisation suggestions, correlation analysis, CSV/JSON/text support

```ruby
analyzer = SharedTools::Tools::CompositeAnalysisTool.new
analyzer.execute(
  data_source: "./sales_data.csv",
  analysis_type: "comprehensive",
  options: {include_correlations: true}
)
```

---

## Network & System Tools

### [DnsTool](dns_tool.md)

DNS resolution, WHOIS queries, IP geolocation, and external IP detection. No API key required.

**Actions:** `a`, `aaaa`, `mx`, `ns`, `txt`, `cname`, `reverse`, `all`, `external_ip`, `ip_location`, `whois`

```ruby
dns = SharedTools::Tools::DnsTool.new

dns.execute(action: "a", host: "example.com")
dns.execute(action: "external_ip")
dns.execute(action: "ip_location", host: "8.8.8.8")
dns.execute(action: "whois", host: "ruby-lang.org")
```

[View DnsTool Documentation →](dns_tool.md)

---

### [WeatherTool](weather.md)

Real-time weather data from OpenWeatherMap. Combine with DnsTool for automatic local forecasts.

**Features:** Current conditions, 3-day forecast, metric/imperial/kelvin units, global city coverage

```ruby
weather = SharedTools::Tools::WeatherTool.new
weather.execute(city: "London,UK", units: "metric", include_forecast: true)
```

[View WeatherTool Documentation →](weather.md)

---

### [NotificationTool](notification_tool.md)

Cross-platform desktop notifications, modal alert dialogs, and text-to-speech. Supports macOS and Linux with no gem dependencies.

**Actions:** `notify`, `alert`, `speak`

```ruby
tool = SharedTools::Tools::NotificationTool.new

tool.execute(action: "notify", message: "Build complete", title: "CI")

result = tool.execute(action: "alert", message: "Deploy to prod?", buttons: ["Yes", "No"])
result[:button]  # => "Yes" or "No"

tool.execute(action: "speak", message: "Task finished", voice: "Samantha")
```

[View NotificationTool Documentation →](notification_tool.md)

---

### CurrentDateTimeTool

Returns the current date, time, and day of week from the system clock — preventing LLMs from hallucinating temporal information.

**Formats:** `"date"`, `"time"`, `"datetime"`, `"day_of_week"`, `"iso8601"`

```ruby
dt = SharedTools::Tools::CurrentDateTimeTool.new
dt.execute(format: "date")
# => { date: "2026-03-25", day_of_week: "Wednesday", ... }
```

---

### SystemInfoTool

System hardware and OS information: CPU, memory, disk, platform details.

```ruby
info = SharedTools::Tools::SystemInfoTool.new
info.execute
```

---

### ClipboardTool

Read and write the system clipboard.

```ruby
clipboard = SharedTools::Tools::ClipboardTool.new
clipboard.execute(action: "read")
clipboard.execute(action: "write", text: "Hello from the LLM!")
```

---

### CronTool

Cron expression parsing and next-run time calculation.

```ruby
cron = SharedTools::Tools::CronTool.new
cron.execute(expression: "0 9 * * MON-FRI")
```

---

## Workflow & DevOps Tools

### WorkflowManagerTool

Manage persistent multi-step workflows with JSON file storage.

**Actions:** `start`, `step`, `status`, `complete`, `list`

```ruby
workflow = SharedTools::Tools::WorkflowManagerTool.new

result = workflow.execute(action: "start", step_data: {project: "release-v2.0"})
workflow_id = result[:workflow_id]

workflow.execute(action: "step", workflow_id: workflow_id, step_data: {task: "run_tests"})
workflow.execute(action: "status", workflow_id: workflow_id)
workflow.execute(action: "list")
workflow.execute(action: "complete", workflow_id: workflow_id)
```

---

### Docker ComposeRunTool

Execute Docker Compose commands safely within containers.

```ruby
docker = SharedTools::Tools::Docker::ComposeRunTool.new
docker.execute(service: "app", command: "rspec", args: ["spec/main_spec.rb"])
```

---

### ErrorHandlingTool

Reference implementation demonstrating robust error handling patterns: retries with exponential backoff, input validation, resource cleanup.

```ruby
error_tool = SharedTools::Tools::ErrorHandlingTool.new
error_tool.execute(operation: "process", data: {name: "test", value: 42}, max_retries: 3)
```

---

## Tool Comparison

| Tool | Primary Use | Requires Gem | Requires API Key |
|------|-------------|-------------|-----------------|
| BrowserTool | Web automation | watir | No |
| DiskTool | File operations | None | No |
| EvalTool | Code execution | None (Python optional) | No |
| DocTool | Document reading | pdf-reader, docx, roo | No |
| DatabaseTool | SQL read/write | sqlite3 or pg | No |
| DatabaseQueryTool | Read-only SQL | sequel | No |
| ComputerTool | System automation | Platform-specific | No |
| CalculatorTool | Math expressions | dentaku (included) | No |
| DataScienceKit | Statistical analysis | None | No |
| CompositeAnalysisTool | Data analysis | None | No |
| DnsTool | DNS / WHOIS / geolocation | None | No |
| WeatherTool | Weather data | openweathermap (included) | Yes (free) |
| CurrentDateTimeTool | Date and time | None | No |
| SystemInfoTool | System info | None | No |
| ClipboardTool | Clipboard | None | No |
| CronTool | Cron scheduling | None | No |
| NotificationTool | Desktop notifications, alerts, TTS | None (OS commands) | No |
| WorkflowManagerTool | Workflow orchestration | None | No |
| Docker ComposeRunTool | Container commands | Docker installed | No |
| ErrorHandlingTool | Reference patterns | None | No |

## Tool Selection Guide

| I need to... | Use |
|--------------|-----|
| Browse a website and extract content | BrowserTool |
| Read, write, or organise files | DiskTool |
| Execute code dynamically | EvalTool |
| Read a PDF, Word doc, or spreadsheet | DocTool |
| Run SQL queries | DatabaseTool / DatabaseQueryTool |
| Automate mouse and keyboard | ComputerTool |
| Evaluate a math expression | CalculatorTool |
| Analyse data statistically | DataScienceKit |
| Look up DNS records or WHOIS | DnsTool |
| Get current weather | WeatherTool |
| Auto-detect my location from IP | DnsTool (ip_location) |
| Get the current date and day | CurrentDateTimeTool |
| Show a desktop notification | NotificationTool (notify) |
| Speak text aloud | NotificationTool (speak) |
| Prompt user with a dialog | NotificationTool (alert) |
| Orchestrate a multi-step process | WorkflowManagerTool |
| Run a command in a Docker container | Docker ComposeRunTool |

## Next Steps

- [Basic Usage Guide](../getting-started/basic-usage.md) — Learn common patterns
- [Authorization System](../guides/authorization.md) — Control operation approval
- [Working with Drivers](../guides/drivers.md) — Create custom drivers
- [Examples](../examples/index.md) — Runnable demo scripts for every tool
