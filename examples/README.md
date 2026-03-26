# SharedTools Examples

Runnable demo scripts showing how to use SharedTools with the RubyLLM framework. Each demo drives a real LLM conversation and exercises a specific tool or set of tools.

## Prerequisites

**All demos require:**

1. **SharedTools gem and dependencies**
   ```bash
   bundle install
   ```

2. **LLM Provider** — a running LLM service (one of):
   - **Ollama** (recommended for local development)
     ```bash
     # Install Ollama from https://ollama.ai
     ollama pull llama3.2
     ```
   - **OpenAI API** — set `OPENAI_API_KEY`
   - **Anthropic API** — set `ANTHROPIC_API_KEY`

3. **Shared helper** — `common.rb` in this directory provides `title()`, `ask()`, `new_chat`, and a pre-configured `@chat` session. It is automatically loaded by all demos via `require_relative 'common'`.

## Running Demos

All demos are run from the project root with the examples directory on the load path:

```bash
bundle exec ruby -I examples examples/weather_tool_demo.rb
```

Debug mode shows every LLM tool call:

```bash
RUBY_LLM_DEBUG=true bundle exec ruby -I examples examples/eval_tool_demo.rb
```

Demos make real LLM API calls and may take 10–60 seconds depending on the number of sections and the model in use.

---

## Available Demos

### `browser_tool_demo.rb`

Web browser automation: navigate pages, inspect HTML, find elements by text or selector, click buttons, fill forms, take screenshots, and complete login workflows.

**Requires:** `watir` gem + Chrome or Firefox installed

```bash
bundle exec ruby -I examples examples/browser_tool_demo.rb
```

---

### `calculator_tool_demo.rb`

Safe mathematical expression evaluation: basic arithmetic, complex expressions, square root, exponentiation, percentages, precision control, and multi-step conversational calculations.

**Requires:** `dentaku` gem (included in gem dependencies)

> **Note:** Modern frontier LLMs perform arithmetic accurately without a calculator tool. This demo is most valuable for learning the tool integration pattern, for smaller or older models, or for compliance/audit workflows where calculations must go through a deterministic evaluator.

```bash
bundle exec ruby -I examples examples/calculator_tool_demo.rb
```

---

### `clipboard_tool_demo.rb`

Read and write the system clipboard.

```bash
bundle exec ruby -I examples examples/clipboard_tool_demo.rb
```

---

### `composite_analysis_tool_demo.rb`

Multi-stage data analysis orchestration: automatic data source detection, structure analysis, statistical insights, visualisation suggestions, and correlation analysis. Supports CSV, JSON, and text formats.

```bash
bundle exec ruby -I examples examples/composite_analysis_tool_demo.rb
```

---

### `computer_tool_demo.rb`

System-level automation: mouse movements and clicks (single, double, right-click), drag and drop, keyboard typing, shortcuts (Cmd+C, Cmd+V, etc.), holding keys, scrolling, and automated form-filling.

**Requires:** macOS + accessibility permissions granted in System Settings → Privacy → Accessibility

```bash
bundle exec ruby -I examples examples/computer_tool_demo.rb
```

---

### `cron_tool_demo.rb`

Cron expression parsing and next-run time calculation.

```bash
bundle exec ruby -I examples examples/cron_tool_demo.rb
```

---

### `current_date_time_tool_demo.rb`

Fetch the real current date, time, and day of week from the system clock. Demonstrates how this prevents LLMs from hallucinating temporal information such as the wrong day of the week.

```bash
bundle exec ruby -I examples examples/current_date_time_tool_demo.rb
```

---

### `data_science_kit_demo.rb`

Real statistical analysis (not simulated) on actual data:

- Statistical summary (mean, median, std dev, quartiles)
- Correlation analysis (Pearson r between columns)
- Time series trend detection and moving averages
- K-means clustering
- Linear regression prediction

All prompts instruct the LLM to pass data **inline** using the `data` parameter as a pipe-delimited table, so no files are required.

```bash
bundle exec ruby -I examples examples/data_science_kit_demo.rb
```

---

### `database_tool_demo.rb`

Full SQL operations on an in-memory SQLite database: CREATE TABLE, INSERT, SELECT with WHERE and JOIN, UPDATE, DELETE, aggregate functions (COUNT, AVG), and transaction-like sequential execution.

**Requires:** `sqlite3` gem

```bash
bundle exec ruby -I examples examples/database_tool_demo.rb
```

---

### `database_query_tool_demo.rb`

Safe read-only SQL queries: SELECT-only access, parameterised queries for SQL injection prevention, automatic LIMIT enforcement, query timeout protection, joins, and aggregations.

**Requires:** `sequel` and `sqlite3` gems (included in gem dependencies)

```bash
bundle exec ruby -I examples examples/database_query_tool_demo.rb
```

---

### `disk_tool_demo.rb`

Secure file system operations: create, read, write, delete, and move files and directories; find and replace text within files; list directory contents; path traversal protection; complete project structure generation.

```bash
bundle exec ruby -I examples examples/disk_tool_demo.rb
```

---

### `dns_tool_demo.rb`

DNS resolution, WHOIS queries, IP geolocation, and external IP detection — all with no API key required:

- A, AAAA, MX, NS, TXT, CNAME record lookups
- Reverse DNS
- Full record dump (`all`)
- External IP detection via public services
- IP geolocation via ip-api.com (city, region, country, timezone, ISP)
- WHOIS for domain names and IP addresses
- Combined workflow: detect IP → geolocate → WHOIS the ISP domain

```bash
bundle exec ruby -I examples examples/dns_tool_demo.rb
```

---

### `doc_tool_demo.rb`

Document reading across all supported formats. Creates sample documents from scratch to keep the demo self-contained:

- **Plain text** — reads a Ruby style guide `.txt` file
- **PDF** — reads specific pages and page ranges (requires a PDF file)
- **Microsoft Word** — builds a minimal `.docx` meeting notes file from scratch using `rubyzip` and reads it with the `docx` gem
- **CSV** — reads an expense report CSV with aggregation and filtering questions
- **Multi-sheet XLSX** — builds a quarterly sales workbook from scratch and reads individual sheets

**Requires:** `docx` and `roo` gems for Word and spreadsheet support

```bash
bundle exec ruby -I examples examples/doc_tool_demo.rb
```

---

### `error_handling_tool_demo.rb`

Reference implementation for robust error handling: input validation with helpful suggestions, network retry with exponential backoff, authorisation checks, resource cleanup, error categorisation, operation metadata tracking, and configurable retry mechanisms.

```bash
bundle exec ruby -I examples examples/error_handling_tool_demo.rb
```

---

### `eval_tool_demo.rb`

Code evaluation in multiple languages:

- Ruby code with result and stdout capture
- Python code (requires `python3` in PATH)
- Shell command execution

Authorization system is bypassed for this demo. In production, keep `SharedTools.auto_execute(false)`.

**Requires:** Python 3 installed for Python examples

```bash
bundle exec ruby -I examples examples/eval_tool_demo.rb
```

---

### `notification_tool_demo.rb`

Cross-platform desktop notifications, modal alert dialogs, and text-to-speech covering all three actions:

- **notify** — banner notifications with title, subtitle, and sound options
- **speak** — TTS at default rate and with explicit words-per-minute override
- **alert** — single-button checkpoint dialog and a two-button Yes/No that reports which was clicked
- **Combined workflow** — all three actions chained in a single LLM prompt

> **Note:** This demo triggers real OS interactions. `alert` **blocks** until you click a button. `speak` will use your system TTS engine out loud.

**Linux prerequisites (optional):**
```bash
sudo apt install libnotify-bin zenity espeak-ng
```

```bash
bundle exec ruby -I examples examples/notification_tool_demo.rb
```

---

### `mcp_client_demo.rb`

Model Context Protocol (MCP) client overview: loading multiple clients, using MCP tools in LLM conversations, and multi-client orchestration.

**Requires:** `ruby_llm-mcp` gem

```bash
bundle exec ruby -I examples examples/mcp_client_demo.rb
```

---

## MCP Client Demos (`mcp/` subdirectory)

Individual demos for each MCP client. Run from the project root with both `examples` and `examples/mcp` on the load path:

```bash
bundle exec ruby -I lib -I examples examples/mcp/tavily_demo.rb
```

All MCP demos share a `examples/mcp/common.rb` helper and use the same `title`/`ask`/`new_chat` helpers as the main demos.

---

### `mcp/tavily_demo.rb`

AI-optimized web search, news, research, and URL extraction via the Tavily API. Uses the remote HTTP transport — no local binary required.

**Requires:** `TAVILY_API_KEY` (free tier at https://tavily.com)

```bash
export TAVILY_API_KEY="your-key"
bundle exec ruby -I lib -I examples examples/mcp/tavily_demo.rb
```

---

### `mcp/github_demo.rb`

GitHub repository exploration: listing repos, reading issues and PRs, code search, contributor analysis, and release history.

**Requires:**
- `GITHUB_PERSONAL_ACCESS_TOKEN`
- Homebrew (auto-installs `github-mcp-server`)

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="your-token"
bundle exec ruby -I lib -I examples examples/mcp/github_demo.rb
```

---

### `mcp/notion_demo.rb`

Full Notion workspace access: search pages and databases, read content, explore recent activity, and retrieve page summaries.

**Requires:**
- `NOTION_TOKEN` (create at https://www.notion.so/profile/integrations)
- Homebrew (auto-installs `notion-mcp-server`)
- Pages and databases must be shared with the integration

```bash
export NOTION_TOKEN="ntn_..."
bundle exec ruby -I lib -I examples examples/mcp/notion_demo.rb
```

---

### `mcp/slack_demo.rb`

Slack workspace browsing: channel overview, recent message summaries, thread deep-dives, and team activity analysis.

**Requires:**
- `SLACK_MCP_XOXP_TOKEN` (user OAuth, recommended) **or** `SLACK_MCP_XOXB_TOKEN` (bot token)
- Homebrew (auto-installs `slack-mcp-server`)

```bash
export SLACK_MCP_XOXP_TOKEN="xoxp-..."
bundle exec ruby -I lib -I examples examples/mcp/slack_demo.rb
```

---

### `mcp/hugging_face_demo.rb`

Browse the Hugging Face Hub: trending models, Ruby/Rails model search, small model discovery, dataset exploration, and model card retrieval.

**Requires:**
- `HF_TOKEN` (create at https://huggingface.co/settings/tokens)
- Homebrew (auto-installs `hf-mcp-server`)

```bash
export HF_TOKEN="hf_..."
bundle exec ruby -I lib -I examples examples/mcp/hugging_face_demo.rb
```

---

### `mcp/memory_demo.rb`

Persistent knowledge graph across conversations using the `@modelcontextprotocol/server-memory` npm package. Store and retrieve facts, entities, and relations.

**Requires:** Node.js / npx (package auto-downloaded on first use)

```bash
bundle exec ruby -I lib -I examples examples/mcp/memory_demo.rb
```

---

### `mcp/sequential_thinking_demo.rb`

Structured chain-of-thought reasoning using the `@modelcontextprotocol/server-sequential-thinking` npm package.

**Requires:** Node.js / npx (package auto-downloaded on first use)

```bash
bundle exec ruby -I lib -I examples examples/mcp/sequential_thinking_demo.rb
```

---

### `mcp/chart_demo.rb`

Chart and visualisation generation using the `@antv/mcp-server-chart` npm package.

**Requires:** Node.js / npx (package auto-downloaded on first use)

```bash
bundle exec ruby -I lib -I examples examples/mcp/chart_demo.rb
```

---

### `mcp/brave_search_demo.rb`

Web and news search via the Brave Search API using the `@modelcontextprotocol/server-brave-search` npm package.

**Requires:**
- `BRAVE_API_KEY` (free tier at https://brave.com/search/api/)
- Node.js / npx (package auto-downloaded on first use)

```bash
export BRAVE_API_KEY="your-key"
bundle exec ruby -I lib -I examples examples/mcp/brave_search_demo.rb
```

---

### `system_info_tool_demo.rb`

System hardware and OS information: CPU model and core count, memory, disk usage, Ruby version, platform details.

```bash
bundle exec ruby -I examples examples/system_info_tool_demo.rb
```

---

### `weather_tool_demo.rb`

Real-time weather data from OpenWeatherMap:

- Current conditions for individual cities
- Metric and imperial unit lookups
- Current weather + 3-day forecast
- Multi-city travel recommendation (Paris vs Barcelona vs Amsterdam)
- Packing advice with forecast data
- Temperature comparison across extreme climates
- **Local forecast** — combines `DnsTool` (external IP → city geolocation) and `CurrentDateTimeTool` (real day of week) with `WeatherTool` to automatically detect your location and give an accurate forecast without hallucinating the day of the week

**Requires:** `OPENWEATHER_API_KEY` environment variable (free at https://openweathermap.org/api)

```bash
export OPENWEATHER_API_KEY="your-key-here"
bundle exec ruby -I examples examples/weather_tool_demo.rb
```

---

### `workflow_manager_tool_demo.rb`

Multi-step workflow orchestration with persistent JSON state:

- **List all workflows** — before starting, shows any workflows from prior runs
- **Start a workflow** — initialises a v2.0.0 release pipeline
- **Execute steps** — LLM drives each phase: tests, security scan, staging deploy, QA, production deploy, stakeholder notification, completion summary
- **Status checks** — inspect progress mid-workflow
- **Complete** — finalise and summarise the workflow

Workflow state persists in `.workflows/` and survives process restarts.

```bash
bundle exec ruby -I examples examples/workflow_manager_tool_demo.rb
```

---

### `comprehensive_workflow_demo.rb`

End-to-end multi-tool pipeline demonstrating how tools compose together in a realistic scenario:

1. **Web scraping phase** — BrowserTool navigates a product catalogue and extracts structured data
2. **Database storage phase** — DatabaseTool creates tables, inserts products, and generates statistics
3. **Report generation phase** — DiskTool creates a report directory and writes Markdown, JSON, and CSV output files

**Requires:** `sqlite3` gem

```bash
bundle exec ruby -I examples examples/comprehensive_workflow_demo.rb
```

---

## common.rb — Shared Helper

All demos `require_relative 'common'`, which provides:

| Helper | Description |
|--------|-------------|
| `title(label, char: '=')` | Prints a formatted section header |
| `ask(prompt)` | Sends a prompt to `@chat` and prints the response |
| `new_chat` | Creates a fresh chat session (resets conversation context) |
| `@chat` | Default chat session shared across demo sections |

Debug logging (`RUBY_LLM_DEBUG=true`) is set in each demo's header so tool calls are visible in the output.

---

## Environment Variables

| Variable | Required by |
|----------|------------|
| `OPENAI_API_KEY` | All demos (if using OpenAI) |
| `ANTHROPIC_API_KEY` | All demos (if using Anthropic) |
| `OLLAMA_HOST` | All demos (if using Ollama; default: `http://localhost:11434`) |
| `OPENWEATHER_API_KEY` | `weather_tool_demo.rb` |
| `TAVILY_API_KEY` | `mcp/tavily_demo.rb` |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | `mcp/github_demo.rb` |
| `NOTION_TOKEN` | `mcp/notion_demo.rb` |
| `SLACK_MCP_XOXP_TOKEN` | `mcp/slack_demo.rb` (user OAuth, recommended) |
| `SLACK_MCP_XOXB_TOKEN` | `mcp/slack_demo.rb` (bot token alternative) |
| `HF_TOKEN` | `mcp/hugging_face_demo.rb` |
| `BRAVE_API_KEY` | `mcp/brave_search_demo.rb` |
| `MEMORY_FILE_PATH` | `mcp/memory_demo.rb` (optional — path to `.jsonl` persistence file) |

---

## Troubleshooting

### `LoadError: cannot load such file — ruby_llm`

```bash
bundle install
```

### LLM connection errors

- **Ollama refused**: run `ollama serve`, check `ollama list` for the model
- **API errors**: verify the key is exported and has credits

### `LoadError` for a specific gem

Each demo's header lists what it requires. Install the missing gem:

```bash
gem install pdf-reader   # DocTool — PDF
gem install docx         # DocTool — Word
gem install roo          # DocTool — spreadsheets
gem install sqlite3      # DatabaseTool
gem install watir        # BrowserTool
```

### Browser automation fails

1. Ensure Chrome or Firefox is installed
2. Install `webdrivers`: `gem install webdrivers`

### Computer automation fails on macOS

Grant accessibility permissions: **System Settings → Privacy & Security → Accessibility** → add your Terminal or IDE.

### PDF reading returns empty text

The PDF is likely image-based (scanned). OCR is not supported. Try a text-based PDF.

---

## Action Constants Reference

Tools define their action names as constants for use in direct (non-LLM) code:

```ruby
SharedTools::Tools::BrowserTool::Action::VISIT
SharedTools::Tools::DiskTool::Action::FILE_CREATE
SharedTools::Tools::ComputerTool::Action::MOUSE_CLICK
SharedTools::Tools::EvalTool::Action::RUBY
SharedTools::Tools::DocTool::Action::PDF_READ
SharedTools::Tools::DocTool::Action::DOCX_READ
SharedTools::Tools::DocTool::Action::SPREADSHEET_READ
SharedTools::Tools::DocTool::Action::TEXT_READ
```

String literals work equally well in LLM tool calls and are shown throughout these demos.

---

## Further Reading

- [SharedTools Documentation](../README.md)
- [Full Tool Reference](../docs/tools/index.md)
- [RubyLLM Framework](https://github.com/mariochavez/ruby_llm)
- [Tool Source Code](../lib/shared_tools/tools/)

## License

All examples are released under the same MIT license as SharedTools.
