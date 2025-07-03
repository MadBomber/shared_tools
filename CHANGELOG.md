# Changelog

## Unreleased

## Released
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
