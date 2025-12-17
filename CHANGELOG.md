# Changelog

## Unreleased

## Released
### [0.3.1] 2025-12-17

- added ClipboardTool for cross-platform clipboard read/write operations
- added CronTool for cron expression parsing and scheduling
- added CurrentDateTimeTool for date/time retrieval with timezone support
- added DnsTool for DNS lookups and resolution
- added SystemInfoTool for system information retrieval
- updated gem dependencies and Zeitwerk configuration
- improved BrowserTool, ComputerTool, and DatabaseTool implementations
- updated GitHub Pages deployment workflow
- fixed a problem with eager loading when used with the `aia` gem

### [0.3.0] 2025-11-08
- changed focus of shared_tools to only support the ruby_llm and ruby_llm-mcp ecosystem

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
