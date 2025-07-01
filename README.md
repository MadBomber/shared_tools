<div align="center">
  <h1>Shared Tools</h1>
  <img src="images/shared_tools.png" alt="Two Robots sharing the same set of tools.">
</div>

A Ruby gem providing a collection of common tools (call-back functions) for use with the following gems:

- ruby_llm: multi-provider `gem install ruby_llm`
- llm: multi-provider `gem install llm.rb`
- omniai: multi-provider `gem install omniai-tools` (Not part of the SharedTools namespace)
- more to come ...

## Recent Changes

### Version 0.2.0

- ability to use the `ruby_llm-mcp` gem was added with two example MCP client instances for some useful MCP servers: github-mcp-server and iMCP.app
- added `SharedTools.mcp_servers` Array to hold defined client instances.
- added a class method `name` to `RubyLLM::Tool` subclasses to define the snake_case String format of the class basename.

## Installation

```ruby
gem install shared_tools

# Load all RubyLLM tools (requires ruby_llm gem to be available and loaded first)
require 'shared_tools/ruby_llm' # multiple API libraries are supported besides ruby_llm

# Or load a specific tool directly
require 'shared_tools/ruby_llm/edit_file'
require 'shared_tools/ruby_llm/read_file'
require 'shared_tools/ruby_llm/python_eval'

# Or load clients for defined MCP servers
# Load all the MCP clients for the ruby_llm library
require 'shared_tools/ruby_llm/mcp'

# Or just the ones you want
require 'shared_tools/ruby_llm/mcp/github_mcp_server'
require 'shared_tools/ruby_llm/mcp/icmp' # MacOS data server

# The client instances for ruby_llm/mcp servers are available
SharedTools.mcp_servers # An Array of MCP clients

# In ruby_llm library access the tools from MCP servers
@tools = []
SharedTools.mcp_servers.size.time  do |server_inx|
  @tools += SharedTools.mcp_servers[server_inx].tools
end
chat = RubyLLM.chat
chat.with_tools(@tools)
```

## Tips for Tool Authors

- Provide a clear comprehensive description for your tool and its parameters
- Include usage examples in your documentation
- Ensure your tool is compatible with different Ruby versions and environments
- Make sure your tool is in the correct directory for the library to which it belongs

## Rails and Autoloader Compatibility

This gem uses Zeitwerk for autoloading, making it fully compatible with Rails and other Ruby applications that use modern autoloaders. RubyLLM tools are excluded from autoloading and loaded manually to avoid namespace conflicts.


 Special Thanks

A special shout-out to Kevin's [omniai-tools](https://github.com/your-github-url/omniai-tools) gem, which is a curated collection of tools for use with his OmniAI gem.
