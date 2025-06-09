<div align="center">
  <h1>Shared Tools</h1>
  <img src="images/shared_tools.png" alt="Two Robots sharing the same set of tools.">
</div>

A Ruby gem providing a collection of shared tools and utilities for Ruby applications, including configurable logging and AI-related tools.

> Is this an anti-Model Context Protocol (MCP) push back? Not really. The MCP is getting better. There is, however, still a need to support the local tool implementations in a way that is consistent with the Ruby library being used - especially when it comes to integrating with libraries that do not support the MCP. Using locally defined tools consistent with the primary library may save a few cycles of latency by eliminating the MCP layer in the architecture.

> Warning: **NOT NOT NOT NOT READY FOR PRODUCTION**
>
> While this gem is in development your best approach if you see a tool within this gem that you want to use is to just copy it into your project without the `SharedTools` namespace and modify it to your needs. Think of this repository like your friendly neighborhood library where you can find and check out interesting books and keep them for as long as you want.
>
> If you find an issue with any of these tools please help us with a fix. If you find a tool tailored to one LLM API wrapper gem but not the one you are using, make a copy refactor as needed to work with your gem and feed it back here.

## Libraries Supported

- ruby_llm: multi-provider `gem install ruby_llm`
- llm: multi-provider `gem install llm.rb`
- omniai: multi-provider `gem install omniai-tools` (Not part of the SharedTools namespace)
- more to come ...

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'shared_tools'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install shared_tools
```

## Usage

### Basic Loading

```ruby
require 'shared_tools'
```

### Loading RubyLLM Tools

RubyLLM tools are loaded conditionally when needed:

```ruby
require 'shared_tools'

# Load all RubyLLM tools (requires ruby_llm gem to be available)
SharedTools.load_ruby_llm_tools

# Or load a specific tool directly
require 'shared_tools/ruby_llm/edit_file'
require 'shared_tools/ruby_llm/read_file'
require 'shared_tools/ruby_llm/python_eval'
# etc.
```

### Rails and Autoloader Compatibility

This gem uses Zeitwerk for autoloading, making it fully compatible with Rails and other Ruby applications that use modern autoloaders. RubyLLM tools are excluded from autoloading and loaded manually to avoid namespace conflicts.

## Shared Logging

All classes within the SharedTools namespace automatically have access to a configurable logger without requiring any explicit includes or setup.

### Basic Usage

Within any class in the SharedTools namespace, you can directly use the logger:

```ruby
module SharedTools
  class MyTool
    def perform_action
      logger.info "Starting action"
      # Do something
      logger.debug "Details about action"
      # Handle errors
    rescue => e
      logger.error "Action failed: #{e.message}"
      raise
    ensure
      logger.info "Action completed"
    end
  end
end
```

### Configuration

The logger can be configured using the `configure_logger` method:

```ruby
# Configure the logger in your application initialization
SharedTools.configure_logger do |config|
  config.level = Logger::DEBUG                   # Set log level
  config.log_device = "logs/shared_tools.log"    # Set output file
  config.formatter = proc do |severity, time, progname, msg|
    "[#{time.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
  end
end
```

### Using with Rails

SharedTools is fully compatible with Rails applications and uses Zeitwerk for autoloading, so it integrates seamlessly with Rails' autoloader.

To use the SharedTools logger with Rails and make it use the same logger instance:

```ruby
# In config/initializers/shared_tools.rb
Rails.application.config.after_initialize do
  # Make SharedTools use the Rails logger
  SharedTools.logger = Rails.logger

  # Load RubyLLM tools if needed
  SharedTools.load_ruby_llm_tools if defined?(RubyLLM)

  # Alternatively, configure the Rails logger to use SharedTools settings
  # SharedTools.configure_logger do |config|
  #   config.level = Rails.logger.level
  #   config.log_device = Rails.logger.instance_variable_get(:@logdev).dev
  # end
  # Rails.logger = SharedTools.logger

  Rails.logger.info "SharedTools integrated with Rails logger"
end
```

### Available Log Levels

The logger supports the standard Ruby Logger levels:

- `logger.debug` - Detailed debug information
- `logger.info` - General information messages
- `logger.warn` - Warning messages
- `logger.error` - Error messages
- `logger.fatal` - Fatal error messages

### Thread Safety

The shared logger is thread-safe and can be used across multiple threads in your application.

---

### Special Thanks

A special shout-out to Kevin's [omniai-tools](https://github.com/your-github-url/omniai-tools) gem, which is a curated collection of tools for use with his OmniAI gem.
