# SharedTools MCP Clients

These MCP (Model Context Protocol) clients require the ruby_llm-mcp gem version >= 0.7.0

## About ruby_llm-mcp v0.7.0

Version 0.7.0 includes the following improvements:
- **Requires RubyLLM 1.9+**: This version mandates RubyLLM 1.9 or higher
- **Automatic Complex Parameters**: Complex parameter support (arrays, nested objects) is now enabled by default
- **Deprecated**: `support_complex_parameters!` method is deprecated and will be removed in v0.8.0

## Available MCP Clients

### iMCP Server
**File**: `imcp.rb`
**Purpose**: Provides access to macOS Notes, Calendar, Contacts, etc.
**Installation**: `brew install --cask loopwork/tap/iMCP`
**Documentation**: https://github.com/loopwork/iMCP

### GitHub MCP Server
**File**: `github_mcp_server.rb`
**Purpose**: GitHub repository management and operations
**Installation**: `brew install github-mcp-server`
**Requires**: `GITHUB_PERSONAL_ACCESS_TOKEN` environment variable

### Tavily MCP Server
**File**: `tavily_mcp_server.rb`
**Purpose**: Web search and research capabilities
**Requires**: `TAVILY_API_KEY` environment variable

## Usage

To use these MCP clients, simply require them in your Ruby application:

```ruby
require 'shared_tools/mcp/imcp'           # For iMCP server
require 'shared_tools/mcp/github_mcp_server'  # For GitHub
require 'shared_tools/mcp/tavily_mcp_server'  # For Tavily

# The clients are automatically registered with RubyLLM::MCP
# Access their tools via RubyLLM::MCP.client("client-name")
```

## Configuration

Each client file contains its own configuration using `RubyLLM::MCP.add_client()`. You can customize the configuration by modifying the respective files or creating your own client configurations.
