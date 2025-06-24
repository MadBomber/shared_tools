<div align="center">
  <h1>Shared Tools</h1>
  <img src="images/shared_tools.png" alt="Two Robots sharing the same set of tools.">
</div>

A Ruby gem providing a collection of common tools (call-back functions) for use with the following gems:

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

# Load all RubyLLM tools (requires ruby_llm gem to be available and loaded first)
require 'shared_tools/ruby_llm'

# Or load a specific tool directly
require 'shared_tools/ruby_llm/edit_file'
require 'shared_tools/ruby_llm/read_file'
require 'shared_tools/ruby_llm/python_eval'
# etc.
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
