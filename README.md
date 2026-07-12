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

- 🔧 **30+ Production Tools** — Browser automation, file discovery and editing (glob/tree/diff/multi-edit/patch), git, structured data (JSON/YAML/TOML/CSV), database queries, code evaluation, document processing, DNS and WHOIS lookups, IP geolocation, data science, weather data, workflow management, system utilities, notifications, and more
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

### 🔍 File Discovery Tools

Find files and content without shelling out to `rg`/`grep`/`find`. Pure Ruby, no external binary dependency.

- **`GlobTool`** — finds files matching a glob pattern (`**/*.rb`, `app/models/*.rb`), returns sorted paths relative to `base`.
- **`TreeTool`** — renders a depth-limited directory tree, skipping `.git`/`node_modules`/hidden entries by default.
- **`SearchCodebaseTool`** — searches file contents for a regular expression, returning `path:line: text` hits (or context blocks with `context`/`before`/`after`). ReDoS-guarded with a per-match regex timeout, and caps results at `max_results` (default 50, max 500).

```ruby
glob = SharedTools::Tools::GlobTool.new
glob.execute(pattern: "**/*.rb", base: "./lib")

tree = SharedTools::Tools::TreeTool.new
tree.execute(path: "./lib", max_depth: 2)

search = SharedTools::Tools::SearchCodebaseTool.new
search.execute(pattern: "def execute", glob: "*.rb")
search.execute(pattern: "TODO", context: 2) # 2 lines of context around each match
```

> **Note:** `SearchCodebaseTool`'s implementation changed from shelling out to `rg`/`grep` to a pure-Ruby, ReDoS-guarded scanner. The `term:` and `extension:` params were renamed to `pattern:` (a regex) and `glob:` (a filename glob, e.g. `"*.rb"` instead of `"rb"`); `max_results:` is unchanged. The `tool:` result key now always reports `"ruby"`.

---

### ✂️ File Editing Tools

Precise, deterministic text editing that complements `DiskTool` and `GitTool` — an alternative to `Disk::FileReplaceTool`'s single global replace for coding-agent workflows.

- **`DiffTool`** — compares two in-memory blocks of text and returns a readable unified diff. Read-only, no filesystem access.
- **`MultiEditTool`** — applies several find/replace edits to one file atomically. Each edit's `old_string` must match exactly once (add context or set `replace_all`) or the whole batch is rejected and nothing is written. Requires authorization.
- **`ApplyPatchTool`** — applies a unified diff (as produced by `git diff`, `DiffTool`, or `diff -u`) via `git apply`, validating with `--check` first. Every touched path is confined to `root`. Set `check: true` for a dry run. Requires authorization.

```ruby
diff = SharedTools::Tools::DiffTool.new
diff.execute(old: old_text, new: new_text)

multi_edit = SharedTools::Tools::MultiEditTool.new(root: "./my-project")
multi_edit.execute(path: "lib/foo.rb", edits: [
  { old_string: "def bar", new_string: "def baz" },
  { old_string: "BAR", new_string: "BAZ", replace_all: true }
])

apply_patch = SharedTools::Tools::ApplyPatchTool.new(root: "./my-project")
apply_patch.execute(patch: unified_diff_text, check: true) # dry run
apply_patch.execute(patch: unified_diff_text)
```

---

### 🔀 Git Tools

Read a repository's history and working-tree state, and make basic mutating changes. Read-only actions (`status`, `diff`, `log`, `show`, `blame`, `branch`, `grep`) require no authorization; mutating actions (`add`, `commit`, `checkout`) require user authorization. External diff drivers, textconv filters, and `core.fsmonitor` are disabled so an untrusted checkout can't turn a read into command execution.

**Actions:** `status`, `diff`, `log`, `show`, `blame`, `branch`, `grep`, `add`, `commit`, `checkout`

```ruby
git = SharedTools::Tools::GitTool.new(repo_root: "./my-project")
git.execute(action: "status")
git.execute(action: "diff", staged: true)
git.execute(action: "log", count: 10, path: "lib/foo.rb")
git.execute(action: "blame", path: "lib/foo.rb", start_line: 10, end_line: 20)
git.execute(action: "commit", message: "Fix the thing", all: true)
```

Each action is also available as a standalone tool, e.g. `SharedTools::Tools::Git::StatusTool`, `SharedTools::Tools::Git::DiffTool`, `SharedTools::Tools::Git::CommitTool`.

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

### 🧩 Structured Data Tools

Query and edit JSON, YAML, TOML, and CSV without writing a parser. Each query tool accepts either a file path or an inline string, and supports a dot/bracket path expression to extract a value (`users[0].name`, `services[].image`, `dependencies.serde.version`) — omit the query to pretty-print the whole document. YAML is loaded with `safe_load` (no arbitrary object deserialization) and TOML is parsed with a small dependency-free parser.

```ruby
json = SharedTools::Tools::JsonQueryTool.new
json.execute(path: "./config.json", query: "servers[0].host")

yaml = SharedTools::Tools::YamlQueryTool.new
yaml.execute(path: "./docker-compose.yml", query: "services[].image")

toml = SharedTools::Tools::TomlQueryTool.new
toml.execute(path: "./Cargo.toml", query: "dependencies.serde.version")

csv_read = SharedTools::Tools::CsvReadTool.new
csv_read.execute(path: "./sales.csv", limit: 20)

csv_write = SharedTools::Tools::CsvWriteTool.new
csv_write.execute(path: "./out.csv", headers: ["name", "age"], rows: [["Alice", "30"]])
```

`CsvWriteTool` is mutating and requires user authorization (see [Authorization System](#authorization-system)); the query tools and `CsvReadTool` are read-only.

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

### 🔔 Notification Tool

Cross-platform desktop notifications, modal alert dialogs, and text-to-speech. Supports macOS and Linux with no gem dependencies.

**Actions:** `notify`, `alert`, `speak`

```ruby
tool = SharedTools::Tools::NotificationTool.new

# Non-blocking desktop banner
tool.execute(action: "notify", message: "Build complete", title: "CI", sound: "Glass")

# Modal dialog — blocks until user clicks; returns clicked button label
result = tool.execute(action: "alert", message: "Deploy to production?", buttons: ["Yes", "No"])
result[:button]  # => "Yes" or "No"

# Text-to-speech
tool.execute(action: "speak", message: "Task finished", voice: "Samantha", rate: 160)
```

| Action | macOS | Linux |
|--------|-------|-------|
| `notify` | osascript | notify-send |
| `alert` | osascript dialog | zenity or terminal fallback |
| `speak` | say | espeak-ng / espeak |

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

## MCP Clients

SharedTools bundles [Model Context Protocol](https://modelcontextprotocol.io) clients that connect AI agents to external services. Each client is opt-in — require only the ones you need.

### Remote HTTP (API key only)

| Client | Env var | Provides |
|--------|---------|----------|
| `require 'shared_tools/mcp/tavily_client'` | `TAVILY_API_KEY` | Web search, news, research, URL extraction |

### Brew-installed (auto-installs via Homebrew)

| Client | Env var | Provides |
|--------|---------|----------|
| `require 'shared_tools/mcp/github_client'` | `GITHUB_PERSONAL_ACCESS_TOKEN` | Repos, issues, PRs, code search |
| `require 'shared_tools/mcp/notion_client'` | `NOTION_TOKEN` | Pages, databases, search, content CRUD |
| `require 'shared_tools/mcp/slack_client'` | `SLACK_MCP_XOXP_TOKEN` | Channels, messages, threads, user info |
| `require 'shared_tools/mcp/hugging_face_client'` | `HF_TOKEN` | Models, datasets, Spaces, model cards |

### npx Auto-download (Node.js required)

| Client | Provides |
|--------|----------|
| `require 'shared_tools/mcp/memory_client'` | Persistent knowledge graph |
| `require 'shared_tools/mcp/sequential_thinking_client'` | Chain-of-thought reasoning |
| `require 'shared_tools/mcp/chart_client'` | Chart and visualisation generation |
| `require 'shared_tools/mcp/brave_search_client'` | Web and news search (`BRAVE_API_KEY`) |
| `require 'shared_tools/mcp/playwright_client'` | Browser automation: navigate, click, fill, screenshot, extract |

```ruby
# Load all available clients at once (skips any whose env vars are missing)
require 'shared_tools/mcp'

# Or load a specific client
require 'shared_tools/mcp/notion_client'
client = RubyLLM::MCP.clients["notion"]
chat   = RubyLLM.chat.with_tools(*client.tools)
chat.ask("Find my project planning pages and summarise what's in them")
```

See [MCP Clients README](lib/shared_tools/mcp/README.md) for full configuration details.

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
| `mcp_client_demo.rb` | MCP client overview |
| `mcp/tavily_demo.rb` | Tavily web search (HTTP) |
| `mcp/github_demo.rb` | GitHub repos, issues, PRs |
| `mcp/notion_demo.rb` | Notion pages and databases |
| `mcp/slack_demo.rb` | Slack channels and messages |
| `mcp/hugging_face_demo.rb` | Hugging Face models and datasets |
| `mcp/memory_demo.rb` | Persistent knowledge graph |
| `mcp/sequential_thinking_demo.rb` | Chain-of-thought reasoning |
| `mcp/chart_demo.rb` | Chart generation |
| `mcp/brave_search_demo.rb` | Brave web search |
| `mcp/playwright_demo.rb` | Browser automation via Playwright |
| `notification_tool_demo.rb` | Desktop notifications, alerts, TTS |
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

Also checkout the wonderful ruby gem [ruby_llm-toolbox](https://rubygems.org/gems/ruby_llm-toolbox)

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
