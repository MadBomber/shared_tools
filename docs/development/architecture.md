# SharedTools Architecture

This document provides a comprehensive overview of SharedTools' architecture, design patterns, and implementation details.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    LLM Application                       │
└───────────────────────┬─────────────────────────────────┘
                        │
                        │ uses
                        ▼
┌─────────────────────────────────────────────────────────┐
│                   SharedTools Module                     │
│  ┌────────────────────────────────────────────────────┐ │
│  │           Authorization System                      │ │
│  │  - Human-in-the-loop (@auto_execute)              │ │
│  │  - execute? method for confirmations               │ │
│  └────────────────────────────────────────────────────┘ │
└───────────────────────┬─────────────────────────────────┘
                        │
                        │ provides
                        ▼
┌─────────────────────────────────────────────────────────┐
│                    Tool Layer                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐│
│  │ Browser  │  │   Disk   │  │ Database │  │Computer ││
│  │   Tool   │  │   Tool   │  │   Tool   │  │  Tool   ││
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬────┘│
│       │             │              │              │     │
│       │ delegates   │ delegates    │ delegates    │     │
│       ▼             ▼              ▼              ▼     │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐  ┌─────────┐│
│  │Sub-tools│   │ Driver  │   │ Driver  │  │ Driver  ││
│  └────┬────┘   └────┬────┘   └────┬────┘  └────┬────┘│
└───────┼─────────────┼─────────────┼────────────┼──────┘
        │             │              │             │
        │ uses        │ uses         │ uses        │ uses
        ▼             ▼              ▼             ▼
┌─────────────────────────────────────────────────────────┐
│              External Systems                            │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐│
│  │  Watir   │  │FileSystem│  │ Database │  │   OS    ││
│  │(Browser) │  │          │  │ (SQLite) │  │  API    ││
│  └──────────┘  └──────────┘  └──────────┘  └─────────┘│
└─────────────────────────────────────────────────────────┘
```

## Module Organization

### Core Module (`lib/shared_tools.rb`)

The main SharedTools module provides:

1. **Authorization System**:
```ruby
module SharedTools
  @auto_execute ||= false

  def self.auto_execute(wildwest=true)
    @auto_execute = wildwest
  end

  def self.execute?(tool: 'unknown', stuff: '')
    return true if @auto_execute == true

    # Prompt user for confirmation
    puts "The AI (tool: #{tool}) wants to do the following ..."
    puts stuff
    print "Is it okay to proceed? (y/N"
    STDIN.getch == "y"
  end
end
```

2. **Zeitwerk Autoloading**:
```ruby
require "zeitwerk"
loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/shared_tools/ruby_llm.rb")
loader.setup
```

### Tool Hierarchy

All tools follow this inheritance structure:

```
::RubyLLM::Tool (from ruby_llm gem)
    │
    ├── SharedTools::Tools::BrowserTool
    ├── SharedTools::Tools::DiskTool
    ├── SharedTools::Tools::DatabaseTool
    ├── SharedTools::Tools::ComputerTool
    ├── SharedTools::Tools::EvalTool
    └── SharedTools::Tools::DocTool
```

## Design Patterns

### 1. Facade Pattern

**Used by**: BrowserTool, ComputerTool

**Purpose**: Provide a simplified interface to complex subsystems

**Structure**:
```
BrowserTool (Facade)
    ├── Browser::VisitTool
    ├── Browser::ClickTool
    ├── Browser::InspectTool
    ├── Browser::PageInspectTool
    ├── Browser::SelectorInspectTool
    ├── Browser::TextFieldAreaSetTool
    └── Browser::PageScreenshotTool
```

**Benefits**:
- Single unified interface for LLMs
- Action-based routing
- Easier testing of individual operations
- Clear separation of concerns

### 2. Strategy Pattern (Driver Interface)

**Used by**: All tools that interact with external systems

**Purpose**: Make the implementation swappable

**Structure**:
```
Tool
  └── uses Driver (via strategy pattern)
        ├── WatirDriver (production)
        ├── SeleniumDriver (alternative)
        └── MockDriver (testing)
```

**Benefits**:
- Testability with mock drivers
- Platform independence
- Easy to add new implementations

### 3. Template Method Pattern

**Used by**: BaseDriver classes

**Purpose**: Define algorithm structure, let subclasses implement steps

**Example**:
```ruby
class BaseDriver
  def perform_action
    validate_input    # concrete
    execute_action    # abstract - subclass implements
    log_result       # concrete
  end

  def execute_action
    raise NotImplementedError
  end
end
```

### 4. Command Pattern

**Used by**: Action-based tools

**Purpose**: Encapsulate actions as objects

**Structure**:
```ruby
module Action
  VISIT = "visit"
  CLICK = "click"
end

def execute(action:, **params)
  case action
  when Action::VISIT then execute_visit(**params)
  when Action::CLICK then execute_click(**params)
  end
end
```

## Component Details

### Authorization System

#### Design Goals

1. **Safety First**: Default to requiring confirmation
2. **Flexibility**: Allow automation when needed
3. **Clarity**: Show exactly what will be executed
4. **Non-blocking**: Works with both interactive and automated contexts

#### Implementation

```ruby
module SharedTools
  class << self
    def auto_execute(wildwest=true)
      @auto_execute = wildwest
    end

    def execute?(tool: 'unknown', stuff: '')
      return true if @auto_execute == true

      # Present action to user
      puts "\n\nThe AI (tool: #{tool}) wants to do the following ..."
      puts "=" * 42
      puts(stuff.empty? ? "unknown strange and mysterious things" : stuff)
      puts "=" * 42

      sleep 0.2 if defined?(AIA) # Allow CLI spinner to recycle
      print "\nIs it okay to proceed? (y/N"
      STDIN.getch == "y"
    end
  end
end
```

#### Usage in Tools

```ruby
def execute(action:, path:)
  return unless SharedTools.execute?(
    tool: self.class.name,
    stuff: "#{action} on #{path}"
  )

  perform_action(action, path)
end
```

### Zeitwerk Autoloading

#### Configuration

```ruby
require "zeitwerk"
loader = Zeitwerk::Loader.for_gem

# Ignore aggregate loader files
loader.ignore("#{__dir__}/shared_tools/ruby_llm.rb")

loader.setup
```

#### Benefits

- Automatic code loading on first use
- Convention over configuration (file names match class names)
- Faster startup times
- Reloading support in development

#### File Naming Convention

```
lib/shared_tools/tools/browser_tool.rb
    └─▶ SharedTools::Tools::BrowserTool

lib/shared_tools/tools/browser/visit_tool.rb
    └─▶ SharedTools::Tools::Browser::VisitTool
```

### Tool Base Class Integration

All tools extend `RubyLLM::Tool`:

```ruby
class MyTool < ::RubyLLM::Tool
  # Class method for tool name
  def self.name = 'my_tool'

  # DSL for description
  description "What this tool does"

  # DSL for parameters
  param :action, desc: "Action to perform"
  param :path, desc: "Path parameter"

  # Initialize with optional dependencies
  def initialize(driver: nil, logger: nil)
    @driver = driver
    @logger = logger || RubyLLM.logger
  end

  # Execute method with keyword args
  def execute(action:, path:)
    # Implementation
  end
end
```

## Data Flow

### Simple Tool Execution

```
1. LLM decides to use tool
   └─▶ tool_name: "disk_tool"
       parameters: {action: "file_read", path: "./file.txt"}

2. RubyLLM routes to SharedTools::Tools::DiskTool

3. Authorization check
   └─▶ SharedTools.execute?
       ├─▶ auto_execute=true? → proceed
       └─▶ auto_execute=false? → ask user

4. Tool execution
   └─▶ execute(action: "file_read", path: "./file.txt")

5. Driver delegation
   └─▶ @driver.file_read(path: "./file.txt")

6. Return result to LLM
   └─▶ "File contents: ..."
```

### Complex Tool Execution (Facade)

```
1. LLM: BrowserTool with action="visit"

2. BrowserTool.execute(action: "visit", url: "...")
   ├─▶ Authorization check
   ├─▶ Parameter validation
   └─▶ Route to sub-tool

3. visit_tool.execute(url: "...")
   └─▶ Sub-tool logic

4. Driver call
   └─▶ @driver.goto(url: "...")

5. Watir/browser operation
   └─▶ Actual browser navigation

6. Result flows back
   └─▶ Sub-tool → Facade → RubyLLM → LLM
```

## Error Handling Architecture

### Error Propagation

```
External System Error
  └─▶ Driver catches and wraps
      └─▶ Tool handles or propagates
          └─▶ RubyLLM catches
              └─▶ LLM receives error message
```

### Error Types

1. **ArgumentError**: Invalid parameters
```ruby
raise ArgumentError, "url required for visit action" if url.nil?
```

2. **LoadError**: Missing dependencies
```ruby
raise LoadError, "watir gem required" unless defined?(Watir)
```

3. **NotImplementedError**: Unimplemented driver methods
```ruby
def unsupported_method
  raise NotImplementedError, "#{self.class}##{__method__} undefined"
end
```

4. **RuntimeError**: Operational errors
```ruby
raise "Element not found: #{selector}" unless element
```

### Error Responses (DatabaseTool pattern)

```ruby
def perform(statement:)
  result = execute(statement)
  { status: :ok, result: result }
rescue DatabaseError => e
  { status: :error, result: e.message }
end
```

## Testing Architecture

### Test Organization

```
spec/
├── shared_tools/
│   └── tools/
│       ├── browser_tool_spec.rb      # Tool tests
│       ├── browser/
│       │   ├── visit_tool_spec.rb    # Sub-tool tests
│       │   └── watir_driver_spec.rb  # Driver tests
│       └── disk_tool_spec.rb
└── spec_helper.rb
```

### Test Doubles Strategy

1. **Mock Drivers**: For tool testing
```ruby
let(:mock_driver) { instance_double(Browser::WatirDriver) }
let(:tool) { BrowserTool.new(driver: mock_driver) }
```

2. **Real Drivers**: For integration testing
```ruby
let(:driver) { Browser::WatirDriver.new }
after { driver.close }
```

3. **Fixture Data**: For consistent test data
```ruby
let(:sample_html) { File.read('spec/fixtures/sample.html') }
```

## Performance Considerations

### Lazy Loading

Sub-tools and drivers are loaded only when needed:

```ruby
def visit_tool
  @visit_tool ||= Browser::VisitTool.new(
    driver: @driver,
    logger: @logger
  )
end
```

### Connection Pooling

For database tools:

```ruby
@connection_pool = ConnectionPool.new(size: 5) do
  Database.connect
end
```

### Caching

Expensive operations can be cached:

```ruby
def expensive_operation
  @cache ||= {}
  @cache[key] ||= perform_expensive_operation
end
```

## Security Architecture

### Input Validation

All user inputs are validated:

```ruby
def execute(action:, path:)
  validate_action!(action)
  validate_path!(path)
  # ...
end
```

### Authorization Layer

```ruby
SharedTools.execute?(
  tool: self.class.name,
  stuff: describe_operation
)
```

### Safe Defaults

- `@auto_execute = false` by default
- Read-only operations don't require confirmation
- Destructive operations always show preview

## Extensibility Points

### Adding New Tools

1. Create class extending `RubyLLM::Tool`
2. Implement `self.name`, `description`, `param`s
3. Implement `execute` method
4. Add tests
5. Zeitwerk handles loading

### Adding New Drivers

1. Extend appropriate `BaseDriver`
2. Implement required methods
3. Register in tool's `default_driver` or pass explicitly

### Adding New Actions

For facade tools:

1. Add action constant
2. Add to description
3. Add to `execute` case statement
4. Create sub-tool if complex
5. Add tests

## Future Architecture Goals

### Planned Improvements

1. **Plugin System**: Load tools from external gems
2. **Middleware**: Chain operations (logging, caching, retry)
3. **Event System**: Hook into tool lifecycle
4. **Configuration**: Centralized tool configuration
5. **Metrics**: Built-in performance monitoring

## Diagrams

### Component Interaction

```
┌─────────┐ uses  ┌──────────────┐ delegates ┌────────────┐
│   LLM   │──────▶│ BrowserTool  │──────────▶│  Sub-tool  │
└─────────┘       └──────────────┘           └────────────┘
                         │                          │
                         │ uses                     │ uses
                         ▼                          ▼
                  ┌─────────────┐            ┌───────────┐
                  │ Authorization│            │  Driver   │
                  └─────────────┘            └───────────┘
                                                    │
                                                    │ uses
                                                    ▼
                                             ┌────────────┐
                                             │  External  │
                                             │   System   │
                                             └────────────┘
```

## Next Steps

- Review [Contributing Guidelines](./contributing.md)
- Learn about [Testing Strategies](./testing.md)
- Explore [Tool Implementation Examples](../examples/index.md)
