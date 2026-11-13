# Changelog

## Unreleased

#### Fixes
- `README.md`: the `EvalTool` example now passes `action:` (it raised `ArgumentError: missing keyword: :action`); also corrected the minimum Ruby version, the license and RubyLLM links, which gems are optional, and the test commands.
- `BrowserTool` and the `Browser::*` tools now require `ferrum` (preferred) or `watir` on demand when no `driver:` is passed. Before, they only checked `defined?(Ferrum)` / `defined?(Watir)`, and nothing loaded those gems when the tools were loaded through `SharedTools.load_all_tools` (as aia does), so they raised `LoadError` even with the gem installed (#3). `BrowserTool` also used Watir only, never Ferrum. Driver selection now lives in `SharedTools::Tools::Browser::DefaultDriver`, replacing eight per-tool `default_driver` methods. The `Browser::*` tools now also pass their logger to the driver they build (it was still `nil` at that point).
- `ComputerTool` now requires the `macos` gem on demand when no `driver:` is passed. Before, it only checked `defined?(MacOS)`, and nothing loaded the gem when the tool was loaded through `SharedTools.load_all_tools` (as aia does), so it raised `LoadError` on macOS even with the gem installed. Same cause as #3. The error message now names the `macos` gem.
- `ComputerTool`'s `hold_key` and `scroll` actions on macOS raised `NameError: uninitialized constant SharedTools::Tools::Computer::MacDriver::Library`; `MacDriver` now refers to `MacOS::Library::CoreGraphics`. `hold_key` also releases the key if it is interrupted while held.
- **Behavior change:** with both `ferrum` and `watir` installed, `BrowserTool` now uses Ferrum (headless Chrome, no chromedriver), matching the `Browser::*` tools. To keep Watir, pass `driver: SharedTools::Tools::Browser::WatirDriver.new`.
- `Disk::LocalDriver`, and custom drivers built on `Disk::BaseDriver`, now normalize `..` segments in a path before checking that the path is under `root:`, so a path such as `sub/../../file.txt` raises `SecurityError` like `../file.txt` already did. `root:` is made absolute when the driver is built, so a relative root such as `"."` now works. The `SecurityError` message now shows the path as given.
- Removed four leftover scripts that crashed when run: `test_gem_conflicts.rb` and `test_version_detection.rb` at the repo root (they called `SharedTools.check_gem_conflicts` / `load_ruby_llm_tools`, which no longer exist), and `examples/ruby_llm_config.rb` / `examples/ruby_llm_config_test.rb` (the test required `amazing_print`, which is not a dependency; `examples/common.rb` provides the shared setup) (#11).
- `Git::CheckoutTool` now runs `git checkout [-b] <ref> --`, so git reads `ref` only as a branch or commit. Before, a `ref` that named a tracked file (e.g. `notes.txt`) was taken as a pathspec and restored that file from the index, discarding its uncommitted changes (#10).

#### ruby_llm 2.1 migration (breaking)
- **Breaking:** Requires `ruby_llm >= 2.1.1, < 3`. Under ruby_llm 2.x every tool that used the 1.x `params do ... end` macro raised `NoMethodError` inside its class body; the constant already existed, so a half-built class loaded without `#execute`, and calling the tool failed with `NotImplementedError: Subclasses must implement #execute`. All 81 tool files now use `parameters do ... end` (same block DSL, now provided by `schematist`), and `Tools::Enabler`'s `param :tool, desc:` is now `parameter :tool, description:`. The generated argument schemas are unchanged apart from the top-level `"strict": true` marker that ruby_llm 1.x added and 2.x does not. Read a tool's schema with `tool.parameters_schema` (was `params_schema`).
- **Breaking:** Dropped the `ruby_llm-mcp` dependency; it cannot be loaded alongside ruby_llm 2.1's built-in `RubyLLM::MCP`, which has no `add_client` / `clients` registry. Each MCP client in `lib/shared_tools/mcp/` is now a `RubyLLM::MCP` subclass that describes one server with the class DSL (`command`, `env`, `url`, `bearer_token`, `timeout`): `SharedTools::MCP::GitHub`, `Notion`, `Slack`, `HuggingFace`, `Tavily`, `Memory`, `SequentialThinking`, `Chart`, `BraveSearch`, `Playwright`. Pass the class to a chat or robot (`RubyLLM.chat.with_mcp(SharedTools::MCP::GitHub)`, `RobotLab.build(mcp: [SharedTools::MCP::GitHub])`) instead of looking it up with `RubyLLM::MCP.clients["github"]`.
- **Breaking:** Requiring a client file no longer has side effects. It does not check environment variables, does not run `brew`/`apt`/`dnf`, and does not connect; environment variables are read when the server process starts. Use `Klass.available?` / `missing_envars` / `verify!` (raises `LoadError` like before) and `Klass.install_packages!`. `require 'shared_tools/mcp'` loads every definition, records availability for `SharedTools.mcp_status`, and `SharedTools::MCP.available` lists the usable classes.
- **Breaking:** MCP server names are now symbol-friendly: `brave-search` → `brave_search`, `hugging-face` → `hugging_face`, `sequential-thinking` → `sequential_thinking` (others unchanged). These are the names in `SharedTools.mcp_status` and `chat.mcp[...]`.
- Removed `lib/shared_tools/mcp/streamable_http_patch.rb`; it patched a `ruby_llm-mcp` internal. ruby_llm 2.1's spec-compliant SSE parser already handles mixed CRLF/LF line endings.
- Added `description` to `SharedTools::MCP::ClientSupport` (class macro plus instance reader; subclasses inherit it) and gave every MCP client one. robot_lab's `mcp_discovery: true` scores servers by name plus description, so it can now pick e.g. `SharedTools::MCP::GitHub` for "open a pull request" and `Playwright` for "take a screenshot of the page".
- Added `csv` as a runtime dependency. It is a bundled (not default) gem since Ruby 3.4, so `CsvReadTool`/`CsvWriteTool` -- and `SharedTools.tools` / `load_all_tools`, which eager-load them -- raised `LoadError: cannot load such file -- csv` in any bundle that did not list it.
- Added `test/shared_tools/tool_classes_test.rb`: every shipped `RubyLLM::Tool` subclass must define its own `#execute`, expose an object `parameters_schema` whose properties `#execute` accepts, and no 1.x `params do` / `param :` may remain in `lib/`. It also calls `current_date_time`, `system_info` and `dns` (used by aia's demo 18) through `Tool#call` and checks the data they return. Added `test/shared_tools/mcp/clients_test.rb` (class-level only; no servers are started).
- Updated the MCP examples, `lib/shared_tools/mcp/README.md`, `README.md` and `docs/` for the new MCP classes.

#### Tools
- Added Git tools, ported from `ruby_llm-toolbox`: `SharedTools::Tools::Git::StatusTool`, `DiffTool`, `LogTool`, `ShowTool`, `BlameTool`, `BranchTool`, and `GrepTool` (read-only), plus `AddTool`, `CommitTool`, and `CheckoutTool` (mutating, require `SharedTools.execute?` authorization). All shell out to `git` with `core.fsmonitor` disabled and `--no-ext-diff --no-textconv`, so an untrusted checkout can't turn a read into command execution; refs are validated against option injection and paths are confined to `repo_root`. Also added `SharedTools::Tools::GitTool`, a facade dispatching on `action`.
- Added `SharedTools::Tools::JsonQueryTool`, `YamlQueryTool`, and `TomlQueryTool` — query JSON/YAML/TOML (from a file or inline string) with a dot/bracket path expression (`users[0].name`, `services[].image`), or pretty-print with no query. YAML uses `safe_load`; TOML is parsed with a new dependency-free `SharedTools::TomlParser`, also ported from `ruby_llm-toolbox`. Path traversal is shared via a new `SharedTools::DataPath` module.
- Added `SharedTools::Tools::CsvReadTool` (read-only) and `SharedTools::Tools::CsvWriteTool` (mutating, requires authorization).
- Added `SharedTools::Tools::DiffTool`, ported from `ruby_llm-toolbox` — compares two in-memory blocks of text and returns a readable unified diff, via a new dependency-free `SharedTools::TextDiff` module. Read-only, no filesystem access.
- Added `SharedTools::Tools::MultiEditTool` — applies several find/replace edits to one file atomically; each edit's `old_string` must match exactly once (or `replace_all`) or the whole batch is rejected and nothing is written. Mutating, requires `SharedTools.execute?` authorization.
- Added `SharedTools::Tools::ApplyPatchTool` — applies a unified diff via `git apply`, validated with `--check` first; every touched path is confined to `root`. Set `check: true` for a dry run. Mutating, requires authorization.
- Added `SharedTools::Tools::GlobTool`, ported from `ruby_llm-toolbox` — finds files matching a glob pattern (`**/*.rb`), returns sorted paths relative to `base`. Read-only, in-process.
- Added `SharedTools::Tools::TreeTool`, ported from `ruby_llm-toolbox` — renders a depth-limited directory tree, skipping `.git`/`node_modules`/hidden entries by default. Read-only, in-process.
- **Breaking:** Replaced `SharedTools::Tools::SearchCodebaseTool`'s implementation with a pure-Ruby scanner ported from `ruby_llm-toolbox`'s `grep_files`, dropping the `rg`/`grep` shell-out dependency entirely. The regex is compiled with a per-match timeout so a malicious pattern can't hang the process (ReDoS guard), and `context`/`before`/`after` params add grep-style context lines around matches. **Param changes:** `term:` → `pattern:` (already treated as a regex by `rg`/`grep`, now explicit and validated), `extension:` → `glob:` (a filename glob like `"*.rb"` instead of a bare extension like `"rb"`). `max_results:` is unchanged. `result[:tool]` now always reports `"ruby"` instead of `"rg"`/`"grep"`.
- Added `SharedTools::Tools::ReplaceInFilesTool` — batch find/replace across files matching a glob (literal or regex, ReDoS-guarded), with `dry_run` preview. Mutating, requires authorization.
- Added Ruby dev tools, ported from `ruby_llm-toolbox`: `SharedTools::Tools::GemTool` (read-only RubyGems.org metadata lookup), `BundleTool` (Bundler install/update/outdated/check/lock/add), `LintTool` (RuboCop/Standard, auto-detected), and `ParseRubyTool` (structural outline of a Ruby file via a new `SharedTools::RubyOutline` module — Prism on Ruby 3.3+, Ripper stdlib fallback otherwise). Bundle/Lint require authorization; Gem/ParseRuby are read-only.
- Added background process management, ported from `ruby_llm-toolbox`: `SharedTools::Tools::ProcessStartTool`, `ProcessListTool`, `ProcessOutputTool`, and `ProcessKillTool`, backed by new `SharedTools::ProcessRegistry`/`ManagedProcess` support (thread-safe registry, bounded output buffers, SIGTERM→SIGKILL escalation across the whole process group, all processes cleaned up at exit). `ProcessStartTool` requires an executable on `allowed_commands` (empty by default) via a new `SharedTools::CommandGuard`, and requires authorization. `ProcessKillTool` requires no authorization — always available so a runaway can be stopped.
- Added guarded network tools, ported from `ruby_llm-toolbox`: `SharedTools::Tools::WebFetchTool` (fetch a URL, HTML stripped to text; read-only), `HttpRequestTool` (general HTTP client; GET/HEAD read-only, POST/PUT/PATCH/DELETE require authorization), and `DownloadFileTool` (download a URL to a file within `root`; requires authorization). All three go through a new `SharedTools::UrlGuard` (SSRF protection: http/https only, no embedded credentials, blocks private/loopback/link-local/cloud-metadata addresses, and pins the connection to the vetted IP to close the DNS-rebinding window).
- Added `SharedTools::Tools::TodoWriteTool` — maintains a replace-the-whole-list task tracker for multi-step work. Read-only (in-memory only), no authorization needed.
- Added `SharedTools::Tools::BashTool` — runs one allowlisted executable with argv-only arguments (no shell, so no pipes/redirects/globs/injection surface). `allowed_commands` is empty by default. Requires authorization.
- Added `SharedTools::Tools::RunTestsTool` (RSpec/Minitest, auto-detected) and `SharedTools::Tools::PythonTestsTool` (pytest/unittest), both via a new `SharedTools::Tools::ToolchainHelpers` module shared with BundleTool/LintTool. Both require authorization.
- **Scope note:** `ruby_llm-toolbox`'s `run_rust`/`run_python`/`run_ruby` (Docker-sandboxed code execution) were intentionally not ported — they depend on a much larger Docker sandbox subsystem this gem doesn't have. Also dropped: the toolbox's `allow_unsafe`/operator-override escape hatches on `bash_tool`, `process_start`, `http_request`, and `web_fetch` — shared_tools has no equivalent global-override concept, so commands/URLs are simply allowed or refused.

#### Tests
- Added `test/shared_tools/tools/git/*_tool_test.rb` (10 files) and `test/shared_tools/tools/git_tool_test.rb` covering all git tools, including ref-injection and path-jail rejection.
- Added `test/shared_tools/tools/{json,yaml,toml,csv}_*_tool_test.rb` covering the structured-data tools.
- Added `test/shared_tools/tools/{diff,multi_edit,apply_patch,replace_in_files}_tool_test.rb` covering the file-editing tools, including atomicity-on-failure and path-jail rejection.
- Added `test/shared_tools/tools/{glob,tree}_tool_test.rb` and rewrote `test/shared_tools/tools/search_codebase_tool_test.rb` for the new `pattern:`/`glob:` params, context blocks, and regex-error handling.
- Added `test/shared_tools/tools/{gem,bundle,lint,parse_ruby}_tool_test.rb` covering the Ruby dev tools.
- Added `test/shared_tools/tools/process_{start,list,output,kill}_tool_test.rb` covering the process-management tools, including allowlist rejection, the concurrency limit, and full start/list/output/kill lifecycles.
- Added `test/shared_tools/tools/{web_fetch,http_request,download_file}_tool_test.rb` covering the network tools, including live SSRF-block assertions against loopback and cloud-metadata addresses.
- Added `test/shared_tools/url_guard_test.rb` and `test/shared_tools/command_guard_test.rb` covering the new security modules directly.
- Added `test/shared_tools/tools/{todo_write,bash,run_tests,python_tests}_tool_test.rb`.
- Added `init_git_repo` / `git_commit_all` test helpers to `test/test_helper.rb`.
- `test/test_helper.rb` now pins SimpleCov's `root` to the project directory. When run from inside `test/`, it measured no lines (reported as 100%, so `minimum_coverage` always passed) and wrote its report to `test/coverage/`, which had been committed. That report is no longer tracked.

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
