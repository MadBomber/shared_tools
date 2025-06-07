# <div align="center">Shared Tools</div>
<div align="center">
  ![Image of two robots sharing tools](images/shared_tools.png?raw=true "Friends Share Tools")
</div>

A Ruby gem providing a collection of shared tools and utilities for Ruby applications, including configurable logging and AI-related tools.

> Is this an anti-Model Context Protocol (MCP) push back? Not really. The MCP is getting better. There is, however, still a need to support the local tool implementations in a way that is consistent with the Ruby library being used - especially when it comes to integrating with libraries that do not support the MCP. Using locally defined tools consistent with the primary library may save a few cycles of latency by eliminating the MCP layer in the architecture.

## Libraries Supported

- ruby_llm: multi-provider `gem install ruby_llm`
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

```ruby
# To load all tools for a specific library
require 'shared_tools/ruby_llm'

# OR you can load a specific tool
require 'shared_tools/ruby_llm/edit_file'
```

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

To use the SharedTools logger with Rails and make it use the same logger instance:

```ruby
# In config/initializers/shared_tools.rb
Rails.application.config.after_initialize do
  # Make SharedTools use the Rails logger
  SharedTools.logger = Rails.logger

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
