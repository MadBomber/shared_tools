# Examples

Practical demonstrations showing how to use SharedTools with LLM agents. All examples are in the `/examples` directory and use a shared `common.rb` helper that sets up the LLM chat session.

## Running the Examples

```bash
bundle install

# Run any demo
bundle exec ruby -I examples examples/weather_tool_demo.rb
bundle exec ruby -I examples examples/dns_tool_demo.rb
bundle exec ruby -I examples examples/doc_tool_demo.rb
```

Some demos require environment variables:

```bash
# WeatherTool demos
export OPENWEATHER_API_KEY="your_key_here"
```

---

## Tool Demos

### [browser_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/browser_tool_demo.rb)

Web automation: navigate pages, inspect content, click elements, fill forms, take screenshots.

---

### [calculator_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/calculator_tool_demo.rb)

Safe mathematical expression evaluation: arithmetic, functions, trigonometry, configurable precision.

---

### [clipboard_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/clipboard_tool_demo.rb)

Read and write the system clipboard.

---

### [composite_analysis_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/composite_analysis_tool_demo.rb)

Multi-stage data analysis orchestration: structure analysis, statistical insights, visualisation suggestions.

---

### [computer_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/computer_tool_demo.rb)

System-level automation: mouse clicks and movement, keyboard typing and shortcuts, screenshots, scrolling.

---

### [cron_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/cron_tool_demo.rb)

Cron expression parsing, scheduling utilities, and next-run time calculations.

---

### [current_date_time_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/current_date_time_tool_demo.rb)

Fetch the real current date, time, and day of week — prevents LLMs from hallucinating temporal information.

---

### [data_science_kit_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/data_science_kit_demo.rb)

Statistical summary, correlation analysis, time series, clustering, and prediction — using both file-based and inline pipe-delimited data.

---

### [database_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/database_tool_demo.rb)

Full SQL operations (CREATE, INSERT, SELECT, UPDATE, DELETE) with the pluggable driver architecture.

---

### [database_query_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/database_query_tool_demo.rb)

Safe read-only SQL queries with automatic LIMIT enforcement and timeout protection.

---

### [disk_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/disk_tool_demo.rb)

Secure file system operations: create, read, write, delete, move files and directories.

---

### [dns_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/dns_tool_demo.rb)

DNS lookups (A, AAAA, MX, NS, TXT, CNAME, reverse), WHOIS queries for domains and IPs, external IP detection, and IP geolocation. Demonstrates combining multiple actions in a single LLM workflow.

---

### [doc_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/doc_tool_demo.rb)

Document reading across all supported formats:
- Plain text files
- PDF documents (specific pages and page ranges)
- Microsoft Word (.docx) documents built from scratch
- CSV expense reports
- Multi-sheet Excel (.xlsx) workbooks

---

### [error_handling_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/error_handling_tool_demo.rb)

Reference implementation for robust error handling: retries with exponential backoff, input validation, resource cleanup, and error categorisation.

---

### [eval_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/eval_tool_demo.rb)

Code evaluation in Ruby, Python, and shell — with authorization controls.

---

### [notification_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/notification_tool_demo.rb)

Cross-platform desktop notifications, modal dialogs, and text-to-speech across five sections:

- **Notify** — banner notifications with title, subtitle, and sound
- **Speak** — TTS with and without a rate override
- **Alert** — single-button checkpoint and a Yes/No dialog that reports which button was clicked
- **Combined workflow** — chains all three actions in one LLM prompt

> **Note:** This demo triggers real OS interactions. The `alert` action **blocks** until you click a button; `speak` will use your system TTS engine.

```bash
bundle exec ruby -I examples examples/notification_tool_demo.rb
```

---

### [mcp_client_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/mcp_client_demo.rb)

MCP (Model Context Protocol) client integration example.

---

### [system_info_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/system_info_tool_demo.rb)

System hardware and OS information: CPU, memory, disk, platform details.

---

### [weather_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/weather_tool_demo.rb)

Real-time weather data for multiple cities, travel recommendations, packing advice, and — most notably — a local forecast that auto-detects your location via DnsTool and uses CurrentDateTimeTool to get the correct day of week.

Requires `OPENWEATHER_API_KEY`.

---

### [workflow_manager_tool_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/workflow_manager_tool_demo.rb)

Multi-step workflow orchestration: start a workflow, list all existing workflows, execute steps, check status, and complete. Demonstrates a full software release pipeline tracked from creation to completion.

---

### [comprehensive_workflow_demo.rb](https://github.com/madbomber/shared_tools/blob/main/examples/comprehensive_workflow_demo.rb)

End-to-end multi-tool workflow combining web scraping, database storage, and report generation.

---

## Shared Helper: common.rb

All demos require `common.rb`, which provides:

- `title(label, char: '=')` — prints a formatted section header
- `ask(prompt)` — sends a prompt to the shared `@chat` session and prints the response
- `new_chat` — creates a fresh chat session (used to reset context between demo sections)
- `@chat` — the default chat session with `ENV['RUBY_LLM_DEBUG'] = 'true'` enabled

```ruby
# Run any demo with the examples directory in the load path
bundle exec ruby -I examples examples/some_tool_demo.rb
```

---

## Demo Categories

### By Capability

| Category | Demos |
|----------|-------|
| Web & Network | browser_tool_demo, dns_tool_demo |
| Files & Documents | disk_tool_demo, doc_tool_demo |
| Data & Analysis | data_science_kit_demo, composite_analysis_tool_demo, database_tool_demo, database_query_tool_demo |
| System & Utilities | computer_tool_demo, system_info_tool_demo, clipboard_tool_demo, current_date_time_tool_demo, cron_tool_demo, notification_tool_demo |
| External APIs | weather_tool_demo |
| Workflow | workflow_manager_tool_demo, comprehensive_workflow_demo |
| Code Execution | eval_tool_demo, calculator_tool_demo |

### By Complexity

| Level | Demos |
|-------|-------|
| Beginner | calculator_tool_demo, current_date_time_tool_demo, disk_tool_demo |
| Intermediate | dns_tool_demo, doc_tool_demo, data_science_kit_demo, weather_tool_demo |
| Advanced | comprehensive_workflow_demo, workflow_manager_tool_demo |
