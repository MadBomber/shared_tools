# SharedTools MCP Clients

MCP (Model Context Protocol) clients that require **no pre-installed binaries**.
Uses `ruby_llm-mcp` >= 0.7.0 and RubyLLM >= 1.9.0.

---

## Two Approaches

### Remote HTTP — `:streamable` transport

Connects to a cloud-hosted MCP endpoint. The user needs only an API key — no Node.js,
no local binary, nothing to install.

| File | Client name | Requires | Provides |
|------|-------------|----------|----------|
| `tavily_mcp_server.rb` | `"tavily"` | `TAVILY_API_KEY` | AI-optimized web search, news, research |

### npx Auto-download — `:stdio` transport via `npx -y`

The npm package is downloaded automatically on first use. The only prerequisite is
**Node.js / npx** being installed on the machine.

| File | Client name | Requires | Provides |
|------|-------------|----------|----------|
| `memory_mcp_server.rb` | `"memory"` | Node.js | Persistent knowledge graph across conversations |
| `sequential_thinking_mcp_server.rb` | `"sequential-thinking"` | Node.js | Structured chain-of-thought reasoning |
| `chart_mcp_server.rb` | `"chart"` | Node.js | Chart and visualisation generation (AntV) |
| `brave_search_mcp_server.rb` | `"brave-search"` | Node.js + `BRAVE_API_KEY` | Web and news search |

---

## Usage

Require the client file to register it, then attach its tools to a chat:

```ruby
require 'shared_tools/mcp/tavily_mcp_server'

client = RubyLLM::MCP.clients["tavily"]
chat   = RubyLLM.chat.with_tools(*client.tools)
chat.ask("Search for the latest Ruby 3.4 release notes")
```

Multiple clients can be combined:

```ruby
require 'shared_tools/mcp/memory_mcp_server'
require 'shared_tools/mcp/sequential_thinking_mcp_server'

tools = %w[memory sequential-thinking].flat_map { |n| RubyLLM::MCP.clients[n].tools }
chat  = RubyLLM.chat.with_tools(*tools)
```

---

## Environment Variables

| Variable | Used by | Where to get it |
|----------|---------|-----------------|
| `TAVILY_API_KEY` | `tavily_mcp_server.rb` | https://tavily.com (free tier) |
| `BRAVE_API_KEY` | `brave_search_mcp_server.rb` | https://brave.com/search/api/ (free tier) |
| `MEMORY_FILE_PATH` | `memory_mcp_server.rb` | Optional — path to `.jsonl` persistence file |

---

## Removed Clients

The following clients were removed because they required manual binary installation:

| Client | Reason removed |
|--------|---------------|
| `github_mcp_server.rb` | Required `brew install github-mcp-server` |
| `imcp.rb` | Required `brew install --cask loopwork/tap/iMCP` (macOS only) |

---

## Reference Files

- `mcp_server_chart.json` — Claude Code settings snippet for `@antv/mcp-server-chart`
- `playwright.md` — Notes on wiring up Playwright MCP in Claude Code settings
