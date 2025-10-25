# Facade Pattern in SharedTools

Complex tools in SharedTools use the Facade pattern to provide a simple, unified interface while delegating to specialized sub-tools. This guide explains the architecture, benefits, and implementation patterns.

## What is the Facade Pattern?

The Facade pattern provides a simplified interface to a complex subsystem. In SharedTools:

- **Facade Tool**: A high-level tool (e.g., BrowserTool) that LLMs interact with
- **Sub-tools**: Specialized tools (e.g., VisitTool, ClickTool) that do the actual work
- **Driver**: The underlying implementation (e.g., WatirDriver) that interfaces with external systems

```
┌─────────────────────────────────────────────────┐
│              BrowserTool (Facade)                │
│  - Unified execute(action:, **params) interface │
│  - Parameter validation                          │
│  - Action routing                                │
└────────┬────────────────────────────────────────┘
         │
         ├─────────────┬──────────────┬─────────────┐
         │             │              │             │
    ┌────▼─────┐  ┌───▼──────┐  ┌───▼──────┐  ┌──▼──────┐
    │VisitTool │  │ClickTool │  │InspectToo│  │Screenshot│
    │          │  │          │  │l         │  │Tool      │
    └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘
         │             │              │             │
         └─────────────┴──────────────┴─────────────┘
                            │
                     ┌──────▼──────┐
                     │WatirDriver  │
                     │(Browser API)│
                     └─────────────┘
```

## Why Use the Facade Pattern?

### Benefits for LLMs

1. **Single Interface**: LLMs interact with one tool instead of many
2. **Consistent API**: All actions use the same `execute` method
3. **Action-based**: Natural verb-based interface (visit, click, inspect)
4. **Parameter Validation**: Centralized validation before delegation

### Benefits for Developers

1. **Separation of Concerns**: Each sub-tool handles one responsibility
2. **Testability**: Test sub-tools independently
3. **Maintainability**: Changes to one action don't affect others
4. **Extensibility**: Add new actions by adding sub-tools

### Benefits for Users

1. **Simplicity**: One tool to learn instead of many
2. **Discoverability**: All actions documented in one place
3. **Consistency**: Similar patterns across all tools

## Facade Architecture

### The Facade Tool

The facade tool provides the public interface:

```ruby
module SharedTools
  module Tools
    class BrowserTool < ::RubyLLM::Tool
      def self.name = 'browser_tool'

      # Define action constants
      module Action
        VISIT = "visit"
        CLICK = "click"
        PAGE_INSPECT = "page_inspect"
        SCREENSHOT = "screenshot"
      end

      # Comprehensive description
      description <<~TEXT
        Automates a web browser to perform various actions...

        1. `visit` - Navigate to a website
        2. `click` - Click an element
        3. `page_inspect` - Get page HTML
        4. `screenshot` - Take a screenshot
      TEXT

      # Define all possible parameters
      param :action, desc: "The action to perform"
      param :url, desc: "URL (required for visit)"
      param :selector, desc: "CSS selector (required for click)"
      param :full_html, desc: "Get full HTML vs summary"

      def initialize(driver: nil, logger: nil)
        @driver = driver || default_driver
        @logger = logger || RubyLLM.logger
      end

      # Central routing method
      def execute(action:, **params)
        case action.to_s.downcase
        when Action::VISIT
          require_param!(:url, params[:url])
          visit_tool.execute(url: params[:url])

        when Action::CLICK
          require_param!(:selector, params[:selector])
          click_tool.execute(selector: params[:selector])

        when Action::PAGE_INSPECT
          page_inspect_tool.execute(full_html: params[:full_html] || false)

        when Action::SCREENSHOT
          screenshot_tool.execute

        else
          raise ArgumentError, "Unknown action: #{action}"
        end
      end

      private

      # Lazy-load sub-tools
      def visit_tool
        @visit_tool ||= Browser::VisitTool.new(
          driver: @driver,
          logger: @logger
        )
      end

      def click_tool
        @click_tool ||= Browser::ClickTool.new(
          driver: @driver,
          logger: @logger
        )
      end

      def page_inspect_tool
        @page_inspect_tool ||= Browser::PageInspectTool.new(
          driver: @driver,
          logger: @logger
        )
      end

      def screenshot_tool
        @screenshot_tool ||= Browser::PageScreenshotTool.new(
          driver: @driver,
          logger: @logger
        )
      end

      def require_param!(name, value)
        raise ArgumentError, "#{name} required for this action" if value.nil?
      end

      def default_driver
        if defined?(Watir)
          Browser::WatirDriver.new(logger: @logger)
        else
          raise LoadError, "BrowserTool requires watir gem or a driver"
        end
      end
    end
  end
end
```

### Sub-tools

Sub-tools handle specific operations:

```ruby
module SharedTools
  module Tools
    module Browser
      # Sub-tool for visiting URLs
      class VisitTool
        def initialize(driver:, logger:)
          @driver = driver
          @logger = logger
        end

        def execute(url:)
          @logger.info("Visiting #{url}")
          @driver.goto(url: url)
          "Navigated to #{url}"
        end
      end

      # Sub-tool for clicking elements
      class ClickTool
        def initialize(driver:, logger:)
          @driver = driver
          @logger = logger
        end

        def execute(selector:)
          @logger.info("Clicking #{selector}")
          @driver.click(selector: selector)
          "Clicked element: #{selector}"
        end
      end

      # Sub-tool for page inspection
      class PageInspectTool
        def initialize(driver:, logger:)
          @driver = driver
          @logger = logger
        end

        def execute(full_html: false, summarize: false)
          @logger.info("Inspecting page (full: #{full_html}, summary: #{summarize})")

          if full_html
            @driver.html
          elsif summarize
            HTMLSummarizer.new(@driver.html).summarize
          else
            @driver.html
          end
        end
      end
    end
  end
end
```

### Sub-tool Guidelines

1. **Single Responsibility**: Each sub-tool does one thing
2. **No RubyLLM::Tool**: Sub-tools are plain Ruby classes
3. **Shared Dependencies**: Driver and logger passed from facade
4. **Simple Interface**: Usually one `execute` method
5. **Return Values**: Return meaningful results

## Real-World Examples

### DiskTool Facade

```ruby
class DiskTool < ::RubyLLM::Tool
  module Action
    FILE_READ = "file_read"
    FILE_WRITE = "file_write"
    FILE_CREATE = "file_create"
    FILE_DELETE = "file_delete"
    FILE_MOVE = "file_move"
    FILE_REPLACE = "file_replace"
    DIRECTORY_CREATE = "directory_create"
    DIRECTORY_DELETE = "directory_delete"
    DIRECTORY_MOVE = "directory_move"
    DIRECTORY_LIST = "directory_list"
  end

  def execute(action:, path:, **params)
    case action
    when Action::FILE_READ
      @driver.file_read(path: path)
    when Action::FILE_WRITE
      @driver.file_write(path: path, text: params[:text])
    when Action::FILE_CREATE
      @driver.file_create(path: path)
    when Action::FILE_DELETE
      @driver.file_delete(path: path)
    when Action::FILE_MOVE
      @driver.file_move(path: path, destination: params[:destination])
    when Action::FILE_REPLACE
      @driver.file_replace(
        path: path,
        old_text: params[:old_text],
        new_text: params[:new_text]
      )
    when Action::DIRECTORY_CREATE
      @driver.directory_create(path: path)
    when Action::DIRECTORY_DELETE
      @driver.directory_delete(path: path)
    when Action::DIRECTORY_MOVE
      @driver.directory_move(path: path, destination: params[:destination])
    when Action::DIRECTORY_LIST
      @driver.directory_list(path: path)
    end
  end
end
```

Note: DiskTool delegates directly to driver methods rather than sub-tools. This is valid when operations are simple enough not to require separate classes.

### DatabaseTool Facade

```ruby
class DatabaseTool < ::RubyLLM::Tool
  def execute(statements:)
    results = []

    statements.each do |statement|
      result = perform(statement: statement)
      results << result.merge(statement: statement)
      break unless result[:status] == :ok
    end

    results
  end

  private

  def perform(statement:)
    @logger&.info("Executing: #{statement}")
    @driver.perform(statement: statement)
  end
end
```

DatabaseTool uses a simpler pattern with statement execution loop.

## Implementation Patterns

### Pattern 1: Sub-tool Delegation

Best for complex operations requiring multiple steps:

```ruby
def execute(action:, **params)
  case action
  when "complex_action"
    complex_action_tool.execute(**params)
  end
end

private

def complex_action_tool
  @complex_action_tool ||= ComplexActionTool.new(
    driver: @driver,
    logger: @logger,
    config: @config
  )
end
```

### Pattern 2: Direct Driver Delegation

Best for simple operations:

```ruby
def execute(action:, path:)
  case action
  when "simple_action"
    @driver.simple_action(path: path)
  end
end
```

### Pattern 3: Mixed Approach

Use sub-tools for complex operations, direct calls for simple ones:

```ruby
def execute(action:, **params)
  case action
  when "complex_action"
    complex_tool.execute(**params)  # Delegate to sub-tool
  when "simple_action"
    @driver.simple_action(**params)  # Direct driver call
  end
end
```

## Parameter Handling

### Extracting Required Parameters

```ruby
def execute(action:, **params)
  case action
  when Action::VISIT
    url = params.fetch(:url) { raise ArgumentError, "url required" }
    visit_tool.execute(url: url)

  when Action::CLICK
    selector = params.fetch(:selector) { raise "selector required" }
    click_tool.execute(selector: selector)
  end
end
```

### Optional Parameters with Defaults

```ruby
def execute(action:, **params)
  case action
  when Action::PAGE_INSPECT
    full_html = params.fetch(:full_html, false)
    context_size = params.fetch(:context_size, 2)

    page_inspect_tool.execute(
      full_html: full_html,
      context_size: context_size
    )
  end
end
```

### Parameter Validation Helper

```ruby
private

def require_param!(name, value)
  raise ArgumentError, "#{name} is required for this action" if value.nil?
end

def require_params!(params, *names)
  names.each do |name|
    require_param!(name, params[name])
  end
end

# Usage
def execute(action:, **params)
  case action
  when Action::TEXT_FIELD_SET
    require_params!(params, :selector, :value)
    text_field_tool.execute(
      selector: params[:selector],
      value: params[:value]
    )
  end
end
```

## Testing Facade Tools

### Test the Facade

```ruby
RSpec.describe SharedTools::Tools::BrowserTool do
  let(:driver) { instance_double(Browser::WatirDriver) }
  let(:tool) { described_class.new(driver: driver) }

  describe "action routing" do
    it "routes visit action to driver" do
      expect(driver).to receive(:goto).with(url: "https://test.com")
      tool.execute(action: "visit", url: "https://test.com")
    end

    it "routes click action to driver" do
      expect(driver).to receive(:click).with(selector: ".button")
      tool.execute(action: "click", selector: ".button")
    end

    it "raises error for invalid action" do
      expect {
        tool.execute(action: "invalid")
      }.to raise_error(ArgumentError, /Unknown action/)
    end
  end

  describe "parameter validation" do
    it "requires url for visit action" do
      expect {
        tool.execute(action: "visit")
      }.to raise_error(ArgumentError, /url.*required/)
    end

    it "requires selector for click action" do
      expect {
        tool.execute(action: "click")
      }.to raise_error(ArgumentError, /selector.*required/)
    end
  end
end
```

### Test Sub-tools Independently

```ruby
RSpec.describe SharedTools::Tools::Browser::VisitTool do
  let(:driver) { instance_double(Browser::WatirDriver) }
  let(:logger) { instance_double(Logger) }
  let(:tool) { described_class.new(driver: driver, logger: logger) }

  it "navigates to URL" do
    expect(driver).to receive(:goto).with(url: "https://test.com")
    expect(logger).to receive(:info).with(/Visiting/)

    result = tool.execute(url: "https://test.com")
    expect(result).to include("Navigated")
  end
end
```

## Advanced Patterns

### Action Registry

For tools with many actions:

```ruby
class BrowserTool < ::RubyLLM::Tool
  ACTIONS = {
    "visit" => :handle_visit,
    "click" => :handle_click,
    "inspect" => :handle_inspect
  }.freeze

  def execute(action:, **params)
    handler = ACTIONS[action.to_s.downcase]
    raise ArgumentError, "Unknown action: #{action}" unless handler

    send(handler, **params)
  end

  private

  def handle_visit(url:, **_)
    visit_tool.execute(url: url)
  end

  def handle_click(selector:, **_)
    click_tool.execute(selector: selector)
  end

  def handle_inspect(full_html: false, **_)
    inspect_tool.execute(full_html: full_html)
  end
end
```

### Middleware Pattern

Add cross-cutting concerns:

```ruby
class BrowserTool < ::RubyLLM::Tool
  def execute(action:, **params)
    with_authorization(action, params) do
      with_timing(action) do
        with_error_handling(action) do
          route_action(action, **params)
        end
      end
    end
  end

  private

  def with_authorization(action, params)
    return yield if SharedTools.auto_execute

    if SharedTools.execute?(tool: self.class.name, stuff: describe_action(action, params))
      yield
    end
  end

  def with_timing(action)
    start = Time.now
    result = yield
    @logger.info("#{action} took #{Time.now - start}s")
    result
  end

  def with_error_handling(action)
    yield
  rescue => e
    @logger.error("#{action} failed: #{e.message}")
    raise
  end

  def route_action(action, **params)
    case action
    when "visit" then visit_tool.execute(**params)
    when "click" then click_tool.execute(**params)
    end
  end
end
```

## When to Use Facades

### Use Facades When:

- Tool has multiple related operations (visit, click, inspect)
- Operations share common resources (driver, logger)
- LLM needs simple, action-based interface
- Sub-operations are complex enough to warrant separate classes

### Don't Use Facades When:

- Tool has only one operation
- Operations are too simple to warrant sub-tools
- No shared state or resources
- Direct driver delegation is clearer

## Next Steps

- Learn about [Driver Interfaces](./driver-interface.md)
- Review the [RubyLLM::Tool Base Class](./tool-base.md)
- Explore [BrowserTool implementation](https://github.com/madbomber/shared_tools/blob/main/lib/shared_tools/tools/browser_tool.rb)
- See [Example Workflows](../examples/workflows.md) using facades
