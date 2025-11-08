# RubyLLM::Tool Base Class

All SharedTools extend `RubyLLM::Tool`, which provides a consistent DSL for defining tool parameters, descriptions, and execution logic. This guide covers the base class API and patterns.

## Overview

`RubyLLM::Tool` is the foundation class from the RubyLLM gem that provides:

- Parameter definition DSL
- Tool description methods
- Standardized execute interface
- Integration with RubyLLM's tool system

## Basic Tool Structure

Every tool follows this basic structure:

```ruby
module SharedTools
  module Tools
    class MyTool < ::RubyLLM::Tool
      # 1. Define tool name (as snake_case)
      def self.name = 'my_tool'

      # 2. Describe what the tool does
      description <<~TEXT
        A brief description of what this tool does.

        Include usage examples and important notes.
      TEXT

      # 3. Define parameters
      param :action, desc: "The action to perform"
      param :path, desc: "The file path (optional)", required: false

      # 4. Implement initialization
      def initialize(driver: nil, logger: nil)
        @driver = driver
        @logger = logger || RubyLLM.logger
      end

      # 5. Implement execute method
      def execute(action:, path: nil)
        @logger&.info("Executing #{action} on #{path}")
        # Implementation here
      end
    end
  end
end
```

## The Parameter DSL

### Defining Parameters with `param`

The `param` method defines the parameters your tool accepts:

```ruby
class BrowserTool < ::RubyLLM::Tool
  # Required parameter
  param :action, desc: "The browser action to perform"

  # Optional parameter
  param :url, desc: "The URL to visit (required for visit action)"

  # Parameter with detailed description
  param :selector, desc: <<~TEXT
    A CSS selector to locate an element:

    * 'button[type="submit"]': selects a submit button
    * '.class-name': selects elements by class
    * '#id-name': selects an element by ID

    Required for click and text_field_set actions.
  TEXT

  # Parameter with examples
  param :context_size, desc: <<~TEXT
    Number of parent elements to include (default: 2).

    Examples:
    - 1: Show only immediate parent
    - 2: Show parent and grandparent (default)
    - 3: Show three levels of context
  TEXT
end
```

### Parameter Description Best Practices

1. **Be Specific**: Clearly state what the parameter does
2. **Include Examples**: Show concrete usage examples
3. **Note Requirements**: Indicate when the parameter is required
4. **Explain Defaults**: Document default values
5. **List Options**: For enum-like parameters, list all valid values

Example of a well-documented parameter:

```ruby
param :action, desc: <<~TEXT
  The browser action to perform. Options:
  * `visit`: Navigate to a website (requires url)
  * `page_inspect`: Get page HTML or summary (optional: full_html)
  * `click`: Click an element (requires selector)
  * `text_field_set`: Enter text (requires selector and value)

  Example: action: "visit"
TEXT
```

## The Description Method

The `description` method provides a comprehensive overview of your tool:

```ruby
description <<~TEXT
  A tool for interacting with files and directories.

  This tool can:
  - Create, read, write, and delete files
  - Create, list, move, and delete directories
  - Replace text within files

  ## Important Notes

  - All paths are relative to the configured root directory
  - File operations require proper permissions
  - Use with caution as operations are destructive

  ## Example Usage

  Create and write to a file:
    {"action": "file_create", "path": "./demo.txt"}
    {"action": "file_write", "path": "./demo.txt", "text": "Hello"}

  Read a file:
    {"action": "file_read", "path": "./demo.txt"}

  Replace text in a file:
    {"action": "file_replace", "path": "./demo.txt",
     "old_text": "Hello", "new_text": "Hi"}
TEXT
```

### Description Best Practices

1. **Start with Purpose**: Begin with what the tool does
2. **List Capabilities**: Bullet point the main features
3. **Include Warnings**: Note any dangerous or destructive operations
4. **Provide Examples**: Show concrete usage examples
5. **Document Actions**: List all available actions with required parameters
6. **Add Context**: Explain when to use this tool vs others

## The Execute Method

The `execute` method is where your tool's logic lives:

### Method Signature

```ruby
def execute(action:, param1: nil, param2: default_value)
  # Implementation
end
```

Key points:

- Use **keyword arguments** for all parameters
- Provide **default values** for optional parameters
- Match parameters defined with `param` DSL
- Return consistent result types

### Parameter Validation

Always validate required parameters:

```ruby
def execute(action:, url: nil, selector: nil)
  case action
  when "visit"
    require_param!(:url, url)
    visit(url)
  when "click"
    require_param!(:selector, selector)
    click(selector)
  else
    raise ArgumentError, "Unknown action: #{action}"
  end
end

private

def require_param!(name, value)
  raise ArgumentError, "#{name} is required for this action" if value.nil?
end
```

### Action Routing Pattern

Use action constants and case statements for routing:

```ruby
module Action
  VISIT = "visit"
  CLICK = "click"
  SCREENSHOT = "screenshot"
end

ACTIONS = [Action::VISIT, Action::CLICK, Action::SCREENSHOT].freeze

def execute(action:, **params)
  case action.to_s.downcase
  when Action::VISIT
    handle_visit(**params)
  when Action::CLICK
    handle_click(**params)
  when Action::SCREENSHOT
    handle_screenshot(**params)
  else
    raise ArgumentError, "Unknown action: #{action}. " \
                        "Valid actions: #{ACTIONS.join(', ')}"
  end
end
```

### Return Values

Be consistent with return values:

```ruby
def execute(action:, path:)
  case action
  when "file_read"
    # Return string content
    File.read(path)

  when "file_write"
    File.write(path, text)
    # Return success message
    "Successfully wrote to #{path}"

  when "directory_list"
    # Return array of entries
    Dir.entries(path)

  when "database_query"
    # Return hash with status
    {
      status: :ok,
      result: db.execute(sql),
      rows_affected: db.changes
    }
  end
end
```

## Initialization Patterns

### Basic Initialization

```ruby
class SimpleTool < ::RubyLLM::Tool
  def initialize(logger: nil)
    @logger = logger || RubyLLM.logger
  end
end
```

### With Required Driver

```ruby
class DatabaseTool < ::RubyLLM::Tool
  def initialize(driver:, logger: nil)
    raise ArgumentError, "driver is required" if driver.nil?
    @driver = driver
    @logger = logger || RubyLLM.logger
  end
end
```

### With Optional Driver (Auto-detection)

```ruby
class BrowserTool < ::RubyLLM::Tool
  def initialize(driver: nil, logger: nil)
    @logger = logger || RubyLLM.logger
    @driver = driver || default_driver
  end

  private

  def default_driver
    if defined?(Watir)
      Browser::WatirDriver.new(logger: @logger)
    else
      raise LoadError, "BrowserTool requires a driver or the watir gem"
    end
  end
end
```

### With Configuration Options

```ruby
class CustomTool < ::RubyLLM::Tool
  def initialize(root: Dir.pwd, timeout: 30, logger: nil)
    @root = root
    @timeout = timeout
    @logger = logger || RubyLLM.logger
  end
end
```

## Logger Integration

All tools should support optional logging:

```ruby
class MyTool < ::RubyLLM::Tool
  def initialize(logger: nil)
    @logger = logger || RubyLLM.logger
  end

  def execute(action:, path:)
    @logger&.info("Executing #{action} on #{path}")

    begin
      result = perform_action(action, path)
      @logger&.debug("Result: #{result.inspect}")
      result
    rescue => e
      @logger&.error("Failed: #{e.message}")
      raise
    end
  end
end
```

### Logging Levels

Follow these conventions:

```ruby
# INFO: High-level operations
@logger.info("BrowserTool: Navigating to #{url}")

# DEBUG: Detailed parameter values
@logger.debug("Parameters: #{params.inspect}")

# WARN: Recoverable issues
@logger.warn("Element not found, retrying...")

# ERROR: Failures and exceptions
@logger.error("Failed to execute: #{e.message}")
```

## Tool Naming Convention

The `name` class method should return a snake_case string:

```ruby
class BrowserTool < ::RubyLLM::Tool
  def self.name = 'browser_tool'
end

class MyCustomTool < ::RubyLLM::Tool
  def self.name = 'my_custom_tool'
end
```

This name is used by:

- RubyLLM for tool registration
- LLM for tool invocation
- Logging and debugging
- Error messages

## Resource Cleanup

Tools that manage resources should provide cleanup methods:

```ruby
class BrowserTool < ::RubyLLM::Tool
  def initialize(driver: nil)
    @driver = driver || Browser::WatirDriver.new
  end

  def cleanup!
    @driver&.close
    @driver = nil
  end

  # Alternative: Use Ruby's ObjectSpace finalizer
  def initialize(driver: nil)
    @driver = driver || Browser::WatirDriver.new

    ObjectSpace.define_finalizer(self, self.class.finalize(@driver))
  end

  def self.finalize(driver)
    proc { driver&.close }
  end
end
```

Usage:

```ruby
browser = SharedTools::Tools::BrowserTool.new
begin
  browser.execute(action: "visit", url: "https://example.com")
ensure
  browser.cleanup!
end
```

## Testing Tool Implementations

### Unit Testing

Test the tool in isolation:

```ruby
RSpec.describe SharedTools::Tools::MyTool do
  let(:logger) { instance_double(Logger) }
  let(:tool) { described_class.new(logger: logger) }

  describe "#execute" do
    it "handles valid action" do
      result = tool.execute(action: "test_action", path: "./test")
      expect(result).to eq("success")
    end

    it "raises error for invalid action" do
      expect {
        tool.execute(action: "invalid")
      }.to raise_error(ArgumentError, /Unknown action/)
    end

    it "requires path parameter" do
      expect {
        tool.execute(action: "test_action")
      }.to raise_error(ArgumentError, /path is required/)
    end

    it "logs execution" do
      expect(logger).to receive(:info).with(/Executing test_action/)
      tool.execute(action: "test_action", path: "./test")
    end
  end
end
```

### Integration Testing

Test with real or mock drivers:

```ruby
RSpec.describe SharedTools::Tools::BrowserTool do
  let(:driver) { MockBrowserDriver.new }
  let(:tool) { described_class.new(driver: driver) }

  it "navigates to URL using driver" do
    expect(driver).to receive(:goto).with(url: "https://test.com")
    tool.execute(action: "visit", url: "https://test.com")
  end
end
```

## Common Patterns

### Parameter Extraction

```ruby
def execute(action:, **params)
  url = params[:url]
  selector = params[:selector]
  # Or use destructuring
  # url, selector = params.values_at(:url, :selector)

  perform_action(action, url, selector)
end
```

### Default Values

```ruby
def execute(action:, timeout: 30, retries: 3)
  options = {
    timeout: timeout,
    retries: retries
  }

  perform_with_options(action, options)
end
```

### Boolean Flags

```ruby
def execute(action:, full_html: false, summarize: true)
  if full_html
    get_full_html
  elsif summarize
    get_summary
  else
    get_basic_html
  end
end
```

### Array Parameters

```ruby
def execute(statements:)
  results = []

  statements.each do |statement|
    result = execute_single(statement)
    results << result
    break if result[:status] == :error
  end

  results
end
```

## Advanced Patterns

### Delegation to Sub-tools

```ruby
class BrowserTool < ::RubyLLM::Tool
  def execute(action:, **params)
    case action
    when "visit"
      visit_tool.execute(**params)
    when "click"
      click_tool.execute(**params)
    end
  end

  private

  def visit_tool
    @visit_tool ||= Browser::VisitTool.new(driver: @driver, logger: @logger)
  end

  def click_tool
    @click_tool ||= Browser::ClickTool.new(driver: @driver, logger: @logger)
  end
end
```

### Memoization

```ruby
def execute(action:, path:)
  case action
  when "read"
    cached_read(path)
  end
end

private

def cached_read(path)
  @cache ||= {}
  @cache[path] ||= File.read(path)
end
```

### Authorization Checks

```ruby
def execute(action:, path:)
  return unless authorize!(action, path)

  perform_action(action, path)
end

private

def authorize!(action, path)
  return true if SharedTools.auto_execute

  SharedTools.execute?(
    tool: self.class.name,
    stuff: "#{action} on #{path}"
  )
end
```

## Next Steps

- Learn about the [Facade Pattern](./facade-pattern.md) used by complex tools
- Understand [Driver Interfaces](./driver-interface.md) for pluggable backends
- Review [Example Tools](../examples/index.md) for implementation patterns
- Read about [Testing Strategies](../guides/testing.md)
