⏺ Try the official Playwright MCP server package:

  npm install -g @playwright/mcp

  Then configure it in your Claude Code settings:

  {
    "mcpServers": {
      "playwright": {
        "command": "npx",
        "args": ["@playwright/mcp"]
      }
    }
  }

  If you prefer the ExecuteAutomation version (which has additional features like screenshots and test code generation), you can
   use:

  npm install -g @executeautomation/playwright-mcp-server

  With configuration:
  {
    "mcpServers": {
      "playwright": {
        "command": "npx",
        "args": ["@executeautomation/playwright-mcp-server"]
      }
    }
  }
