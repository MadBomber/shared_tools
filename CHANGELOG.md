# Changelog

## Unreleased

### [0.4.4] - 2026-06-06

#### Tools
- Added `SearchCodebaseTool` (`tools/search_codebase_tool.rb`) — read-only codebase search using ripgrep (`rg`) with grep fallback; supports `path`, `extension`, and `max_results` parameters; returns matches with file path and line number; no authorization prompt required
- Enhanced `ShellEvalTool`: added optional `workdir` parameter to set the working directory for command execution; validates the directory exists before running
- Enhanced `ShellEvalTool`: output is now truncated at 5000 bytes (stdout) and 2000 bytes (stderr) to prevent oversized tool responses; truncated output is marked with `[truncated]`
- Moved `require "open3"` to the top of `ShellEvalTool` instead of inline inside `execute`

#### Tests
- Added `test/shared_tools/tools/search_codebase_tool_test.rb` — 16 tests covering search, extension filtering, `max_results` capping, truncation flag, error cases, and tool-key reporting
- Added 4 tests to `test/shared_tools/tools/eval/shell_eval_tool_test.rb` covering `workdir` execution, missing-directory error, stdout truncation, and non-truncation of short output

### [0.4.2] - 2026-03-27

#### MCP Clients
- Added Playwright MCP client (`mcp/playwright_client.rb`) — browser automation via the official `@playwright/mcp` package (npx auto-download, no pre-installation required)
- Added `mcp/tool_schema_patch.rb` — strips `$schema` from MCP tool input schemas before API serialization; fixes `BadRequestError` from Claude's API when MCP servers annotate schemas with JSON Schema Draft 2020-12 meta-fields
- Added demo script: `examples/mcp/playwright_demo.rb`

## Released

### [0.4.1] - 2026-03-26

#### MCP Clients
- Added `SharedTools.mcp_status` — prints a formatted table of loaded vs. skipped clients
- Added `SharedTools.mcp_loaded` — returns array of successfully loaded client names
- Added `SharedTools.mcp_failed` — returns hash of skipped client names mapped to their error messages
- Added `SharedTools.record_mcp_result` — thread-safe internal method used by `mcp.rb` to record each client's load outcome
- Fixed `mcp.rb` thread exception handling: changed `rescue => e` to `rescue Exception => e` so `LoadError` (a `ScriptError`, not a `StandardError`) is caught and the thread does not terminate with an unhandled exception
- Added SSE line-ending normalization patch (`mcp/streamable_http_patch.rb`) for MCP servers that mix `\n` and `\r\n` line endings in SSE responses (e.g. Tavily), fixing a 30-second `tools/list` timeout
- Added brew-installed MCP clients: Notion (`notion_client.rb`), Slack (`slack_client.rb`), Hugging Face (`hugging_face_client.rb`)
- All `package_install` methods now raise `LoadError` on failure (consistent with `verify_envars`)
- Added demo scripts: `examples/mcp/notion_demo.rb`, `examples/mcp/slack_demo.rb`, `examples/mcp/hugging_face_demo.rb`

#### Tests
- Added `test/shared_tools/utilities_test.rb` — 28 tests covering `verify_envars`, `brew_install`, `npm_install`, `gem_install`, `package_install`, and MCP load tracking methods
- Added `test/shared_tools/mcp/streamable_http_patch_test.rb` — 15 tests covering SSE buffer normalization for all line-ending variants (`\n\n`, `\r\n\r\n`, mixed `\n\r\n`, bare `\r`)

#### Documentation
- Updated `README.md` with MCP Clients section covering all three transport categories
- Updated `examples/README.md` with entries for all 10 `examples/mcp/` demos and expanded environment variables table
- Updated `docs/getting-started/installation.md` with MCP client setup section
- Updated `docs/index.md` and `lib/shared_tools/mcp/README.md` with Notion, Slack, and Hugging Face client details

### [0.4.0] - 2026-03-25

#### MCP Clients
- Added Tavily MCP client (`mcp/tavily_client.rb`) — AI-optimized web search via remote HTTP transport
- Added GitHub MCP client (`mcp/github_client.rb`) — repos, issues, PRs, code search via brew-installed binary
- Added Memory MCP client (`mcp/memory_client.rb`) — persistent knowledge graph via npx
- Added Sequential Thinking MCP client (`mcp/sequential_thinking_client.rb`) — chain-of-thought reasoning via npx
- Added Chart MCP client (`mcp/chart_client.rb`) — chart generation via npx
- Added Brave Search MCP client (`mcp/brave_search_client.rb`) — web/news search via npx
- Added `mcp.rb` bulk loader — requires all available clients concurrently in parallel threads; missing-key clients silently skipped
- Added `SharedTools.verify_envars` — raises `LoadError` listing missing environment variable names
- Added `SharedTools.package_install`, `brew_install`, `apt_install`, `dnf_install`, `npm_install`, `gem_install` in `utilities.rb`

#### Tools
- Added `NotificationTool` — cross-platform desktop notifications (`notify`), modal alert dialogs (`alert`), and text-to-speech (`speak`) for macOS and Linux
- Added screenshot capability to `BrowserTool`
- Added array argument support to `Docker::ComposeRunTool`

#### Examples
- Added `examples/mcp/` subdirectory with individual demo scripts for each MCP client
- Added `examples/mcp/common.rb` shared helper for MCP demos


### [0.2.1] 2025-07-03
- iMCP server app for MacOS is noisy logger so redirect stderr to /dev/null

### [0.2.0] 2025-07-01
- added ruby_llm/mcp/github_mcp_server.rb example
- added SharedTools.mcp_servers as an Array of MCP servers
- added class method name to tool classes as a snake_case of the class name
- added ruby_llm/mcp/imcp.rb to get stuff from MacOS apps
- added ruby_llm/incomplete directory with some under-development example tools

### [0.1.3] 2025-06-18
- tweaking the load all tools process

### [0.1.2] 2025-06-10
- added `zeitwerk` gem

### [0.1.0] - 2025-06-05
- Initial gem release
- SharedTools core module with automatic logger integration
- RubyLlm tools: EditFile, ListFiles, PdfPageReader, ReadFile, RunShellCommand
