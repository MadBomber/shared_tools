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
| `tavily_client.rb` | `"tavily"` | `TAVILY_API_KEY` | AI-optimized web search, news, research |

### Brew-installed binary — `:stdio` transport

The binary is installed automatically via Homebrew if not already present.
Requires **Homebrew** (`https://brew.sh`).

| File | Client name | Requires | Provides |
|------|-------------|----------|----------|
| `github_client.rb` | `"github"` | `GITHUB_PERSONAL_ACCESS_TOKEN` | Repositories, issues, PRs, code search |
| `notion_client.rb` | `"notion"` | `NOTION_TOKEN` | Pages, databases, search, content CRUD |
| `slack_client.rb` | `"slack"` | `SLACK_MCP_XOXP_TOKEN` or `SLACK_MCP_XOXB_TOKEN` | Channels, messages, threads, user info |
| `hugging_face_client.rb` | `"hugging-face"` | `HF_TOKEN` | Models, datasets, Spaces, model cards |

### npx Auto-download — `:stdio` transport via `npx -y`

The npm package is downloaded automatically on first use. The only prerequisite is
**Node.js / npx** being installed on the machine.

| File | Client name | Requires | Provides |
|------|-------------|----------|----------|
| `memory_client.rb` | `"memory"` | Node.js | Persistent knowledge graph across conversations |
| `sequential_thinking_client.rb` | `"sequential-thinking"` | Node.js | Structured chain-of-thought reasoning |
| `chart_client.rb` | `"chart"` | Node.js | Chart and visualisation generation (AntV) |
| `brave_search_client.rb` | `"brave-search"` | Node.js + `BRAVE_API_KEY` | Web and news search |
| `playwright_client.rb` | `"playwright"` | Node.js | Browser automation: navigate, click, fill, screenshot, extract |

---

## Usage

Require the client file to register it, then attach its tools to a chat:

```ruby
require 'shared_tools/mcp/tavily_client'

client = RubyLLM::MCP.clients["tavily"]
chat   = RubyLLM.chat.with_tools(*client.tools)
chat.ask("Search for the latest Ruby 3.4 release notes")
```

Multiple clients can be combined:

```ruby
require 'shared_tools/mcp/memory_client'
require 'shared_tools/mcp/sequential_thinking_client'

tools = %w[memory sequential-thinking].flat_map { |n| RubyLLM::MCP.clients[n].tools }
chat  = RubyLLM.chat.with_tools(*tools)
```

---

## Environment Variables

| Variable | Used by | Where to get it |
|----------|---------|-----------------|
| `TAVILY_API_KEY` | `tavily_client.rb` | https://tavily.com (free tier) |
| `GITHUB_PERSONAL_ACCESS_TOKEN` | `github_client.rb` | https://github.com/settings/tokens |
| `NOTION_TOKEN` | `notion_client.rb` | https://www.notion.so/profile/integrations |
| `SLACK_MCP_XOXP_TOKEN` | `slack_client.rb` | Slack OAuth — user token (full access) |
| `SLACK_MCP_XOXB_TOKEN` | `slack_client.rb` | Slack OAuth — bot token (limited access) |
| `HF_TOKEN` | `hugging_face_client.rb` | https://huggingface.co/settings/tokens |
| `BRAVE_API_KEY` | `brave_search_client.rb` | https://brave.com/search/api/ (free tier) |
| `MEMORY_FILE_PATH` | `memory_client.rb` | Optional — path to `.jsonl` persistence file |

### Slack token types

| Token prefix | Type | Access |
|---|---|---|
| `xoxp-` | User OAuth | Full access to all channels, search, DMs the user can see |
| `xoxb-` | Bot token | Only channels the bot has been invited to; no message search |

### Notion integration setup

After creating an integration at https://www.notion.so/profile/integrations, you must
**share each page or database** with the integration for it to be accessible. The MCP server
can only see content that has been explicitly shared.

---

## Removed Clients

The following clients were removed because they required manual binary installation:

| Client | Reason removed |
|--------|---------------|
| `imcp.rb` | Required `brew install --cask loopwork/tap/iMCP` (macOS only) |

---

## Reference Files

- `mcp_server_chart.json` — Claude Code settings snippet for `@antv/mcp-server-chart`
- `playwright.md` — Notes on wiring up Playwright MCP in Claude Code settings
