# Testing Guide

Comprehensive guide to testing SharedTools, including unit tests, integration tests, and testing strategies for LLM applications.

## Testing Philosophy

SharedTools follows Test-Driven Development (TDD):

1. Write test first
2. Watch it fail
3. Write minimal code to pass
4. Refactor
5. Repeat

## Test Structure

### Directory Organization

```
spec/
├── spec_helper.rb              # Test configuration
├── support/                    # Shared test utilities
│   ├── mock_drivers.rb        # Mock driver implementations
│   └── shared_examples.rb      # Shared example groups
├── fixtures/                   # Test data files
│   ├── sample.html
│   └── test.pdf
└── shared_tools/
    └── tools/
        ├── browser_tool_spec.rb
        ├── browser/
        │   ├── visit_tool_spec.rb
        │   └── watir_driver_spec.rb
        ├── disk_tool_spec.rb
        └── database_tool_spec.rb
```

### spec_helper.rb Configuration

```ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'ruby_llm'
require 'shared_tools'

# SimpleCov for coverage
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  minimum_coverage 80
end

# RSpec configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = true

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.order = :random
  Kernel.srand config.seed
end
```

## Unit Testing Tools

### Basic Tool Tests

```ruby
RSpec.describe SharedTools::Tools::MyTool do
  let(:tool) { described_class.new }

  describe ".name" do
    it "returns snake_case name" do
      expect(described_class.name).to eq('my_tool')
    end
  end

  describe "#initialize" do
    it "initializes without parameters" do
      expect { described_class.new }.not_to raise_error
    end

    it "accepts logger parameter" do
      logger = instance_double(Logger)
      tool = described_class.new(logger: logger)
      expect(tool.instance_variable_get(:@logger)).to eq(logger)
    end

    it "accepts driver parameter" do
      driver = instance_double(Driver)
      tool = described_class.new(driver: driver)
      expect(tool.instance_variable_get(:@driver)).to eq(driver)
    end
  end

  describe "#execute" do
    context "with valid action" do
      it "executes successfully" do
        result = tool.execute(action: "valid_action", param: "value")
        expect(result).to be_truthy
      end

      it "returns expected result" do
        result = tool.execute(action: "valid_action", param: "value")
        expect(result).to eq("expected result")
      end
    end

    context "with invalid action" do
      it "raises ArgumentError" do
        expect {
          tool.execute(action: "invalid_action")
        }.to raise_error(ArgumentError, /Unknown action/)
      end
    end

    context "parameter validation" do
      it "requires action parameter" do
        expect {
          tool.execute(param: "value")
        }.to raise_error(ArgumentError)
      end

      it "validates required parameters" do
        expect {
          tool.execute(action: "needs_param")
        }.to raise_error(ArgumentError, /param.*required/)
      end

      it "uses default for optional parameters" do
        result = tool.execute(action: "with_default")
        expect(result).to include("default_value")
      end
    end
  end
end
```

### Testing with Mock Drivers

```ruby
RSpec.describe SharedTools::Tools::BrowserTool do
  let(:mock_driver) do
    instance_double(
      SharedTools::Tools::Browser::BaseDriver,
      goto: { status: :ok },
      html: "<html><body>Test</body></html>",
      title: "Test Page",
      url: "https://example.com",
      click: { status: :ok },
      fill_in: { status: :ok },
      screenshot: nil,
      close: nil
    )
  end

  let(:tool) { described_class.new(driver: mock_driver) }

  describe "visit action" do
    it "calls driver goto method" do
      expect(mock_driver).to receive(:goto).with(url: "https://test.com")
      tool.execute(action: "visit", url: "https://test.com")
    end

    it "returns navigation message" do
      result = tool.execute(action: "visit", url: "https://test.com")
      expect(result).to include("Navigated")
    end
  end

  describe "page_inspect action" do
    it "returns HTML from driver" do
      result = tool.execute(action: "page_inspect", full_html: true)
      expect(result).to include("<html>")
    end

    it "calls driver html method" do
      expect(mock_driver).to receive(:html)
      tool.execute(action: "page_inspect", full_html: true)
    end
  end
end
```

### Shared Examples

Create reusable test patterns:

```ruby
# spec/support/shared_examples.rb
RSpec.shared_examples "a tool" do
  it "has a name method" do
    expect(described_class).to respond_to(:name)
  end

  it "returns snake_case name" do
    expect(described_class.name).to match(/^[a-z_]+$/)
  end

  it "extends RubyLLM::Tool" do
    expect(described_class.ancestors).to include(RubyLLM::Tool)
  end

  it "has execute method" do
    expect(described_class.new).to respond_to(:execute)
  end
end

# Usage
RSpec.describe SharedTools::Tools::MyTool do
  it_behaves_like "a tool"
end
```

## Integration Testing

### Testing with Real Drivers

```ruby
RSpec.describe SharedTools::Tools::BrowserTool, :integration do
  let(:driver) { SharedTools::Tools::Browser::WatirDriver.new }
  let(:tool) { described_class.new(driver: driver) }

  after { driver.close }

  it "navigates to real website" do
    result = tool.execute(action: "visit", url: "https://example.com")
    expect(result).to include("Navigated")
    expect(driver.url).to eq("https://example.com")
  end

  it "gets real page HTML" do
    tool.execute(action: "visit", url: "https://example.com")
    html = tool.execute(action: "page_inspect", full_html: true)
    expect(html).to include("Example Domain")
  end
end
```

### Testing Database Operations

```ruby
RSpec.describe SharedTools::Tools::DatabaseTool do
  let(:db) { SQLite3::Database.new(':memory:') }
  let(:driver) { SharedTools::Tools::Database::SqliteDriver.new(db: db) }
  let(:tool) { described_class.new(driver: driver) }

  after { db.close }

  it "creates table" do
    results = tool.execute(statements: [
      "CREATE TABLE users (id INTEGER, name TEXT)"
    ])

    expect(results.first[:status]).to eq(:ok)
  end

  it "inserts and queries data" do
    tool.execute(statements: [
      "CREATE TABLE users (id INTEGER, name TEXT)",
      "INSERT INTO users VALUES (1, 'Alice')",
      "INSERT INTO users VALUES (2, 'Bob')"
    ])

    results = tool.execute(statements: ["SELECT * FROM users"])
    expect(results.first[:result]).to have(2).items
  end
end
```

### Testing File Operations

```ruby
RSpec.describe SharedTools::Tools::DiskTool do
  let(:temp_dir) { Dir.mktmpdir }
  let(:driver) { SharedTools::Tools::Disk::LocalDriver.new(root: temp_dir) }
  let(:tool) { described_class.new(driver: driver) }

  after { FileUtils.rm_rf(temp_dir) }

  it "creates and reads file" do
    tool.execute(action: "file_create", path: "./test.txt")
    tool.execute(action: "file_write", path: "./test.txt", text: "Hello")

    content = tool.execute(action: "file_read", path: "./test.txt")
    expect(content).to eq("Hello")
  end

  it "creates directory" do
    tool.execute(action: "directory_create", path: "./subdir")
    expect(File.directory?(File.join(temp_dir, "subdir"))).to be true
  end
end
```

## Testing Workflows

### Multi-Tool Integration

```ruby
RSpec.describe "Web scraping workflow" do
  let(:html_response) do
    <<~HTML
      <html>
        <body>
          <div class="product">Widget A</div>
          <div class="product">Widget B</div>
        </body>
      </html>
    HTML
  end

  let(:browser_driver) do
    instance_double(
      SharedTools::Tools::Browser::BaseDriver,
      goto: nil,
      html: html_response
    )
  end

  let(:db) { SQLite3::Database.new(':memory:') }
  let(:db_driver) { SharedTools::Tools::Database::SqliteDriver.new(db: db) }

  let(:browser) { SharedTools::Tools::BrowserTool.new(driver: browser_driver) }
  let(:database) { SharedTools::Tools::DatabaseTool.new(driver: db_driver) }

  after { db.close }

  it "scrapes and stores data" do
    # Phase 1: Scrape
    browser.execute(action: "visit", url: "https://example.com")
    html = browser.execute(action: "page_inspect", full_html: true)

    # Parse products (simplified)
    products = html.scan(/Widget \w/)

    # Phase 2: Store
    database.execute(statements: [
      "CREATE TABLE products (name TEXT)"
    ])

    products.each do |product|
      database.execute(statements: [
        "INSERT INTO products VALUES ('#{product}')"
      ])
    end

    # Verify
    results = database.execute(statements: ["SELECT * FROM products"])
    expect(results.first[:result]).to have(2).items
  end
end
```

## Test Fixtures

### HTML Fixtures

```ruby
# spec/fixtures/sample.html
<!DOCTYPE html>
<html>
  <head><title>Test Page</title></head>
  <body>
    <h1>Welcome</h1>
    <button id="submit">Submit</button>
  </body>
</html>

# Usage in tests
let(:sample_html) { File.read('spec/fixtures/sample.html') }
let(:mock_driver) do
  instance_double(Driver, html: sample_html)
end
```

### Database Fixtures

```ruby
# spec/support/database_helper.rb
module DatabaseHelper
  def setup_test_database(db)
    db.execute(<<~SQL)
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE
      );

      INSERT INTO users VALUES (1, 'Alice', 'alice@example.com');
      INSERT INTO users VALUES (2, 'Bob', 'bob@example.com');
    SQL
  end
end

RSpec.configure do |config|
  config.include DatabaseHelper
end

# Usage
RSpec.describe "Database queries" do
  let(:db) { SQLite3::Database.new(':memory:') }

  before { setup_test_database(db) }

  it "queries users" do
    results = db.execute("SELECT * FROM users")
    expect(results).to have(2).items
  end
end
```

## Mock Driver Implementations

### Complete Mock Browser Driver

```ruby
# spec/support/mock_browser_driver.rb
class MockBrowserDriver < SharedTools::Tools::Browser::BaseDriver
  attr_reader :current_url, :actions, :form_data

  def initialize(responses: {})
    @responses = responses
    @current_url = nil
    @actions = []
    @form_data = {}
  end

  def goto(url:)
    @actions << { type: :goto, url: url }
    @current_url = url
    "Navigated to #{url}"
  end

  def html
    @responses[@current_url] || "<html><body><h1>Default</h1></body></html>"
  end

  def title
    "Mock Page - #{@current_url}"
  end

  def url
    @current_url
  end

  def click(selector:)
    @actions << { type: :click, selector: selector }
    "Clicked #{selector}"
  end

  def fill_in(selector:, text:)
    @actions << { type: :fill_in, selector: selector, text: text }
    @form_data[selector] = text
    "Filled #{selector}"
  end

  def screenshot
    @actions << { type: :screenshot }
    StringIO.new("fake-png-data")
  end

  def close
    @actions << { type: :close }
  end

  # Helper methods for assertions
  def visited?(url)
    @actions.any? { |a| a[:type] == :goto && a[:url] == url }
  end

  def clicked?(selector)
    @actions.any? { |a| a[:type] == :click && a[:selector] == selector }
  end

  def filled?(selector, text)
    @form_data[selector] == text
  end
end
```

### Complete Mock Database Driver

```ruby
# spec/support/mock_database_driver.rb
class MockDatabaseDriver < SharedTools::Tools::Database::BaseDriver
  attr_reader :statements, :tables

  def initialize
    @statements = []
    @tables = {}
  end

  def perform(statement:)
    @statements << statement

    case statement
    when /CREATE TABLE (\w+)/i
      create_table($1)
    when /INSERT INTO (\w+).*VALUES\s*\((.*)\)/i
      insert_into($1, $2)
    when /SELECT \* FROM (\w+)/i
      select_from($1)
    when /DELETE FROM (\w+)/i
      delete_from($1)
    else
      { status: :error, result: "Unsupported: #{statement}" }
    end
  end

  private

  def create_table(name)
    @tables[name] = []
    { status: :ok, result: "Table #{name} created" }
  end

  def insert_into(table, values)
    @tables[table] ||= []
    row = values.split(',').map { |v| v.strip.gsub(/['"]/, '') }
    @tables[table] << row
    { status: :ok, result: "1 row inserted" }
  end

  def select_from(table)
    { status: :ok, result: @tables[table] || [] }
  end

  def delete_from(table)
    count = @tables[table]&.size || 0
    @tables[table] = []
    { status: :ok, result: "#{count} rows deleted" }
  end
end
```

## Test Coverage

### Running Coverage Reports

```bash
# Generate coverage report
COVERAGE=true bundle exec rspec

# Open in browser
open coverage/index.html
```

### Coverage Requirements

- Minimum 80% overall coverage
- 90%+ for critical paths
- 100% for utility methods
- Lower acceptable for:
  - Error handling branches
  - Logging statements
  - Defensive code

### Improving Coverage

```ruby
# Before: Untested error branch
def execute(action:)
  case action
  when "valid" then "ok"
  else raise "Invalid"  # Untested!
  end
end

# After: Test the error
it "raises error for invalid action" do
  expect {
    tool.execute(action: "invalid")
  }.to raise_error(/Invalid/)
end
```

## Performance Testing

### Benchmarking

```ruby
require 'benchmark'

RSpec.describe "Performance" do
  it "executes within time limit" do
    time = Benchmark.realtime do
      1000.times { tool.execute(action: "fast_action") }
    end

    expect(time).to be < 1.0  # Should complete in under 1 second
  end
end
```

### Memory Testing

```ruby
require 'memory_profiler'

RSpec.describe "Memory usage" do
  it "doesn't leak memory" do
    report = MemoryProfiler.report do
      1000.times { tool.execute(action: "action") }
    end

    expect(report.total_allocated_memsize).to be < 10_000_000  # 10MB
  end
end
```

## Testing LLM Interactions

### Mocking RubyLLM

```ruby
RSpec.describe "LLM integration" do
  let(:mock_llm) do
    instance_double(
      RubyLLM::Agent,
      call: { tool: "browser_tool", parameters: { action: "visit", url: "https://example.com" } }
    )
  end

  it "tool is called by LLM" do
    response = mock_llm.call("Visit example.com")
    tool_name = response[:tool]
    params = response[:parameters]

    tool = SharedTools::Tools.const_get(tool_name.camelize)
    result = tool.new.execute(**params)

    expect(result).to include("Navigated")
  end
end
```

## Best Practices

### DO:

- Write tests before code (TDD)
- Test one thing per test
- Use descriptive test names
- Clean up resources (after blocks)
- Use let for test data
- Mock external dependencies
- Test error cases
- Test edge cases

### DON'T:

- Test implementation details
- Have interdependent tests
- Use sleep for timing
- Leave temp files
- Test private methods directly
- Ignore flaky tests
- Skip error cases
- Hard-code test data

## Debugging Tests

```ruby
# Add focus to run one test
it "specific test", :focus do
  # ...
end

# Use binding.pry for debugging
it "debuggable test" do
  result = tool.execute(action: "test")
  binding.pry  # Drops into console
  expect(result).to eq("expected")
end

# Print debug info
it "test with output" do
  result = tool.execute(action: "test")
  puts "Result: #{result.inspect}"
  expect(result).to be_truthy
end
```

## Next Steps

- Review [Contributing Guidelines](./contributing.md)
- Understand [Architecture](./architecture.md)
- Explore [Example Tests](https://github.com/madbomber/shared_tools/tree/main/spec/shared_tools/tools)
- Read [Error Handling Guide](../guides/error-handling.md)
