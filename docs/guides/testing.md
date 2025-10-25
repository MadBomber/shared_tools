# Testing Tools in LLM Applications

Guide to testing SharedTools in LLM-powered applications, including strategies for testing tool interactions, LLM responses, and end-to-end workflows.

## Testing Challenges with LLMs

LLM applications present unique testing challenges:

1. **Non-determinism**: LLMs may return different outputs for the same input
2. **Tool Selection**: LLM chooses which tools to use
3. **Parameter Generation**: LLM generates tool parameters
4. **Multi-step Workflows**: LLM orchestrates multiple tool calls
5. **Cost**: API calls to LLMs can be expensive
6. **Speed**: LLM responses can be slow

## Testing Strategies

### Strategy 1: Unit Test Tools in Isolation

Test tools without involving the LLM:

```ruby
RSpec.describe SharedTools::Tools::BrowserTool do
  let(:mock_driver) { instance_double(Browser::WatirDriver) }
  let(:tool) { described_class.new(driver: mock_driver) }

  it "executes visit action" do
    expect(mock_driver).to receive(:goto).with(url: "https://test.com")
    result = tool.execute(action: "visit", url: "https://test.com")
    expect(result).to include("Navigated")
  end
end
```

**Benefits**:
- Fast
- Deterministic
- No LLM costs
- Easy to debug

**When to use**: Always, as foundation of test suite

### Strategy 2: Test Tool Selection Logic

Mock the LLM's tool selection:

```ruby
RSpec.describe "Tool selection" do
  let(:tools) do
    [
      SharedTools::Tools::BrowserTool.new(driver: mock_browser),
      SharedTools::Tools::DiskTool.new(driver: mock_disk)
    ]
  end

  it "selects BrowserTool for web scraping" do
    # Simulate LLM choosing browser tool
    selected_tool = select_tool_for_task(
      task: "Visit https://example.com",
      tools: tools
    )

    expect(selected_tool).to be_a(SharedTools::Tools::BrowserTool)
  end

  it "selects DiskTool for file operations" do
    selected_tool = select_tool_for_task(
      task: "Read file.txt",
      tools: tools
    )

    expect(selected_tool).to be_a(SharedTools::Tools::DiskTool)
  end
end
```

### Strategy 3: Test with Fixed LLM Responses

Record LLM responses and replay them:

```ruby
RSpec.describe "LLM integration" do
  let(:recorded_responses) do
    {
      "Visit example.com" => {
        tool: "browser_tool",
        action: "visit",
        url: "https://example.com"
      },
      "Read file.txt" => {
        tool: "disk_tool",
        action: "file_read",
        path: "./file.txt"
      }
    }
  end

  let(:mock_llm) do
    double("LLM").tap do |llm|
      allow(llm).to receive(:call) do |prompt|
        recorded_responses[prompt]
      end
    end
  end

  it "handles visit command" do
    response = mock_llm.call("Visit example.com")
    tool = get_tool(response[:tool])
    result = tool.execute(**response.except(:tool))

    expect(result).to include("Navigated")
  end
end
```

### Strategy 4: Test with Real LLM (Sparingly)

Use real LLM for integration tests:

```ruby
RSpec.describe "Full LLM integration", :slow, :integration do
  let(:agent) do
    RubyLLM::Agent.new(
      tools: [
        SharedTools::Tools::BrowserTool.new(driver: mock_browser),
        SharedTools::Tools::DiskTool.new(driver: mock_disk)
      ]
    )
  end

  it "scrapes and saves data" do
    # This makes a real LLM API call
    response = agent.process("Visit example.com and save the title to title.txt")

    # Verify the LLM used the right tools
    expect(mock_browser).to have_received(:goto)
    expect(mock_disk).to have_received(:file_write)
  end
end
```

**Run sparingly**:
```bash
# Skip slow tests by default
rspec

# Run slow tests explicitly
rspec --tag integration
```

## Testing Patterns

### Pattern 1: Mock LLM Agent

Create a predictable fake LLM:

```ruby
class MockLLMAgent
  def initialize(responses:)
    @responses = responses
    @call_count = 0
  end

  def call(prompt)
    @call_count += 1
    @responses[prompt] || raise("Unexpected prompt: #{prompt}")
  end

  attr_reader :call_count
end

RSpec.describe "LLM workflow" do
  let(:agent) do
    MockLLMAgent.new(
      responses: {
        "Scrape products" => {
          tool: "browser_tool",
          action: "visit",
          url: "https://shop.com/products"
        },
        "Save to database" => {
          tool: "database_tool",
          statements: ["INSERT INTO products..."]
        }
      }
    )
  end

  it "follows the workflow" do
    agent.call("Scrape products")
    agent.call("Save to database")
    expect(agent.call_count).to eq(2)
  end
end
```

### Pattern 2: Fixture-Based Testing

Store LLM responses as fixtures:

```ruby
# spec/fixtures/llm_responses/scrape_workflow.json
{
  "steps": [
    {
      "prompt": "Visit the products page",
      "response": {
        "tool": "browser_tool",
        "action": "visit",
        "url": "https://example.com/products"
      }
    },
    {
      "prompt": "Get page content",
      "response": {
        "tool": "browser_tool",
        "action": "page_inspect",
        "full_html": true
      }
    }
  ]
}

# In tests
let(:workflow) { JSON.parse(File.read('spec/fixtures/llm_responses/scrape_workflow.json')) }

it "executes workflow" do
  workflow['steps'].each do |step|
    response = step['response']
    tool = get_tool(response['tool'])
    result = tool.execute(**response.except('tool'))
    expect(result).to be_truthy
  end
end
```

### Pattern 3: Assertion on Tool Usage

Verify the LLM used tools correctly:

```ruby
RSpec.describe "Tool usage tracking" do
  let(:browser) { instance_spy(SharedTools::Tools::BrowserTool) }
  let(:disk) { instance_spy(SharedTools::Tools::DiskTool) }

  let(:agent) do
    LLMAgent.new(tools: [browser, disk])
  end

  it "uses browser before disk" do
    agent.process("Scrape example.com and save to file.txt")

    # Verify order of operations
    expect(browser).to have_received(:execute).ordered
    expect(disk).to have_received(:execute).ordered
  end

  it "passes correct parameters" do
    agent.process("Visit https://example.com")

    expect(browser).to have_received(:execute).with(
      hash_including(
        action: "visit",
        url: "https://example.com"
      )
    )
  end
end
```

### Pattern 4: Snapshot Testing

Record full LLM interactions for regression testing:

```ruby
RSpec.describe "LLM snapshots" do
  it "matches recorded interaction" do
    VCR.use_cassette("scraping_workflow") do
      result = agent.process("Scrape products from example.com")

      expect(result).to match_snapshot("scraping_workflow_result")
    end
  end
end
```

## Testing Tool Descriptions

Test that tool descriptions are accurate:

```ruby
RSpec.describe "Tool descriptions" do
  let(:tool) { SharedTools::Tools::BrowserTool }

  it "includes all actions in description" do
    description = tool.description

    SharedTools::Tools::BrowserTool::ACTIONS.each do |action|
      expect(description).to include(action)
    end
  end

  it "documents required parameters" do
    description = tool.description

    expect(description).to include("action")
    expect(description).to include("url")
    expect(description).to include("selector")
  end

  it "provides usage examples" do
    description = tool.description

    expect(description).to match(/"action":\s*"visit"/)
    expect(description).to match(/"action":\s*"click"/)
  end
end
```

## Testing Multi-Step Workflows

### Sequential Tool Calls

```ruby
RSpec.describe "Multi-step workflow" do
  let(:browser) { instance_double(SharedTools::Tools::BrowserTool) }
  let(:database) { instance_double(SharedTools::Tools::DatabaseTool) }
  let(:disk) { instance_double(SharedTools::Tools::DiskTool) }

  before do
    allow(browser).to receive(:execute).and_return("<html>...</html>")
    allow(database).to receive(:execute).and_return([{ status: :ok }])
    allow(disk).to receive(:execute).and_return("Saved")
  end

  it "completes workflow in order" do
    # Step 1: Scrape
    html = browser.execute(action: "visit", url: "https://example.com")
    expect(html).to be_a(String)

    # Step 2: Store
    results = database.execute(statements: ["INSERT..."])
    expect(results.first[:status]).to eq(:ok)

    # Step 3: Report
    report = disk.execute(action: "file_write", path: "./report.txt", text: "...")
    expect(report).to eq("Saved")
  end
end
```

### Error Recovery in Workflows

```ruby
RSpec.describe "Workflow error handling" do
  it "handles browser errors" do
    allow(browser).to receive(:execute).and_raise("Network error")

    expect {
      workflow.execute
    }.to raise_error(/Network error/)

    # Verify cleanup happened
    expect(browser).to have_received(:cleanup!)
  end

  it "continues after recoverable errors" do
    allow(browser).to receive(:execute).and_raise("Element not found")
    allow(workflow).to receive(:retry_browser_action).and_return("success")

    result = workflow.execute_with_retry

    expect(result).to eq("success")
    expect(workflow).to have_received(:retry_browser_action)
  end
end
```

## Performance Testing

### Measure Tool Execution Time

```ruby
RSpec.describe "Performance" do
  it "completes within acceptable time" do
    start_time = Time.now

    tool.execute(action: "complex_operation")

    elapsed = Time.now - start_time
    expect(elapsed).to be < 5.0  # 5 seconds max
  end
end
```

### Test with Large Datasets

```ruby
RSpec.describe "Scalability" do
  it "handles large result sets" do
    # Generate 10,000 test records
    records = 10_000.times.map { |i| ["Record #{i}"] }

    allow(database).to receive(:execute).and_return(records)

    result = tool.process_large_dataset

    expect(result).to be_truthy
  end
end
```

## Testing Authorization

Test human-in-the-loop confirmation:

```ruby
RSpec.describe "Authorization" do
  before do
    SharedTools.auto_execute(false)
  end

  it "prompts for confirmation" do
    allow(STDIN).to receive(:getch).and_return('y')

    expect(SharedTools).to receive(:execute?).and_return(true)

    tool.execute(action: "delete", path: "./important.txt")
  end

  it "skips confirmation in auto mode" do
    SharedTools.auto_execute(true)

    expect(SharedTools).not_to receive(:execute?)

    tool.execute(action: "delete", path: "./file.txt")
  end

  after do
    SharedTools.auto_execute(false)
  end
end
```

## Testing with Different LLM Providers

### Provider-Agnostic Tests

```ruby
RSpec.describe "LLM provider compatibility" do
  let(:tools) { [SharedTools::Tools::BrowserTool.new] }

  shared_examples "LLM provider" do |provider_name|
    it "works with #{provider_name}" do
      agent = create_agent_for(provider_name, tools: tools)

      result = agent.process("Visit example.com")

      expect(result).to be_truthy
    end
  end

  include_examples "LLM provider", :openai
  include_examples "LLM provider", :anthropic
  include_examples "LLM provider", :ollama
end
```

## Continuous Integration

### CI Configuration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: 3.2

    - name: Install dependencies
      run: bundle install

    - name: Run unit tests
      run: bundle exec rspec --tag ~integration --tag ~slow

    - name: Run integration tests
      run: bundle exec rspec --tag integration
      env:
        LLM_API_KEY: ${{ secrets.LLM_API_KEY }}
      # Only run on main branch to save API costs
      if: github.ref == 'refs/heads/main'
```

## Test Organization

### Directory Structure

```
spec/
├── unit/
│   ├── tools/
│   │   ├── browser_tool_spec.rb
│   │   ├── disk_tool_spec.rb
│   │   └── database_tool_spec.rb
│   └── drivers/
│       ├── watir_driver_spec.rb
│       └── sqlite_driver_spec.rb
├── integration/
│   ├── workflows/
│   │   ├── scraping_workflow_spec.rb
│   │   └── data_pipeline_spec.rb
│   └── llm/
│       ├── tool_selection_spec.rb
│       └── parameter_generation_spec.rb
├── fixtures/
│   ├── html/
│   ├── databases/
│   └── llm_responses/
└── support/
    ├── mock_drivers.rb
    ├── mock_llm.rb
    └── shared_examples.rb
```

### Test Configuration

```ruby
# spec/spec_helper.rb
RSpec.configure do |config|
  # Fast unit tests by default
  config.filter_run_excluding :integration, :slow

  # Tag LLM tests for special handling
  config.around(:each, :llm) do |example|
    skip "LLM tests disabled" unless ENV['RUN_LLM_TESTS']
    example.run
  end

  # Setup mock drivers globally
  config.before(:each) do
    @mock_browser = instance_double(Browser::WatirDriver)
    @mock_database = MockDatabaseDriver.new
    @mock_disk = MockDiskDriver.new
  end
end
```

## Best Practices

### DO:

- Test tools in isolation first
- Use mock drivers for unit tests
- Record LLM responses for deterministic tests
- Test error cases thoroughly
- Verify tool descriptions
- Test authorization system
- Use fixtures for complex data
- Tag expensive tests appropriately

### DON'T:

- Make real LLM API calls in unit tests
- Test implementation details
- Assume LLM will always choose correct tool
- Ignore non-deterministic behavior
- Skip integration tests entirely
- Hard-code test data
- Leave slow tests untagged
- Test with real databases/browsers unless necessary

## Debugging LLM Interactions

### Log LLM Requests and Responses

```ruby
RSpec.configure do |config|
  config.around(:each, :llm) do |example|
    logger = Logger.new('spec/logs/llm_interactions.log')

    # Wrap LLM calls with logging
    original_call = agent.method(:call)
    allow(agent).to receive(:call) do |prompt|
      logger.info("Prompt: #{prompt}")
      response = original_call.call(prompt)
      logger.info("Response: #{response.inspect}")
      response
    end

    example.run
  end
end
```

### Inspect Tool Parameters

```ruby
it "generates correct parameters" do
  tool = spy("BrowserTool")

  agent = LLMAgent.new(tools: [tool])
  agent.process("Visit example.com")

  # Inspect what parameters the LLM generated
  expect(tool).to have_received(:execute) do |**params|
    puts "LLM generated parameters: #{params.inspect}"
    expect(params[:url]).to eq("https://example.com")
  end
end
```

## Next Steps

- Review [Error Handling Guide](./error-handling.md)
- Explore [Testing Examples](https://github.com/madbomber/shared_tools/tree/main/spec)
- Read [Development Guide](../development/testing.md)
- Check [Example Workflows](../examples/workflows.md)
