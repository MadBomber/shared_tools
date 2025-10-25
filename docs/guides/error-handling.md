# Error Handling Patterns

Comprehensive guide to error handling in SharedTools, covering common patterns, best practices, and recovery strategies.

## Error Handling Philosophy

SharedTools follows these principles:

1. **Fail Fast**: Detect errors early
2. **Clear Messages**: Provide actionable error information
3. **Graceful Degradation**: Handle errors without crashing
4. **User Feedback**: Return errors to LLMs in usable format
5. **Security**: Don't expose sensitive information in errors

## Error Categories

### 1. Validation Errors

Raised when parameters are invalid:

```ruby
def execute(action:, url: nil)
  raise ArgumentError, "url is required for visit action" if action == "visit" && url.nil?
  raise ArgumentError, "url must be a string" unless url.is_a?(String)
  raise ArgumentError, "url must be absolute" unless url.start_with?("http")

  perform_visit(url)
end
```

**When to use**: Parameter validation, precondition checks

**How to handle**: Let the exception propagate to LLM

### 2. Missing Dependency Errors

Raised when required gems or resources are unavailable:

```ruby
def default_driver
  if defined?(Watir)
    Browser::WatirDriver.new
  else
    raise LoadError, "BrowserTool requires the 'watir' gem. " \
                    "Install it with: gem install watir"
  end
end
```

**When to use**: Missing gems, unavailable system features

**How to handle**: Provide installation instructions

### 3. Operational Errors

Errors during normal operation:

```ruby
def execute(action:, selector:)
  begin
    element = driver.find_element(selector)
    element.click
  rescue ElementNotFoundError => e
    raise "Element not found: #{selector}. " \
          "Check the selector and try again. " \
          "Available selectors: #{list_available_selectors}"
  end
end
```

**When to use**: Network errors, missing elements, file not found

**How to handle**: Provide context and recovery suggestions

### 4. System Errors

Errors from external systems:

```ruby
def perform(statement:)
  begin
    result = @db.execute(statement)
    { status: :ok, result: result }
  rescue SQLite3::SQLException => e
    { status: :error, result: "SQL error: #{e.message}" }
  rescue SQLite3::BusyException => e
    { status: :error, result: "Database locked, try again" }
  end
end
```

**When to use**: Database errors, filesystem errors, OS errors

**How to handle**: Catch and convert to structured responses

## Error Handling Patterns

### Pattern 1: Explicit Validation

Validate early, fail fast:

```ruby
def execute(action:, path:, text: nil)
  # Validate action
  unless VALID_ACTIONS.include?(action)
    raise ArgumentError, "Invalid action: #{action}. " \
                        "Valid actions: #{VALID_ACTIONS.join(', ')}"
  end

  # Validate path
  raise ArgumentError, "path cannot be empty" if path.empty?
  raise ArgumentError, "path cannot contain .." if path.include?("..")

  # Validate text for write actions
  if action == "write" && text.nil?
    raise ArgumentError, "text is required for write action"
  end

  perform_action(action, path, text)
end
```

### Pattern 2: Structured Error Responses

Return errors as data structures:

```ruby
def execute(statements:)
  results = []

  statements.each do |statement|
    result = perform_statement(statement)
    results << {
      statement: statement,
      status: result[:status],
      result: result[:result]
    }

    # Stop on first error
    break if result[:status] == :error
  end

  results
end

def perform_statement(statement)
  result = @driver.execute(statement)
  { status: :ok, result: result }
rescue DatabaseError => e
  { status: :error, result: e.message }
end
```

### Pattern 3: Retry with Exponential Backoff

For transient errors:

```ruby
def execute_with_retry(action:, max_retries: 3)
  retries = 0

  begin
    perform_action(action)
  rescue TransientError => e
    retries += 1

    if retries <= max_retries
      sleep_time = 2 ** retries  # 2, 4, 8 seconds
      @logger.warn("Retry #{retries}/#{max_retries} after #{sleep_time}s: #{e.message}")
      sleep sleep_time
      retry
    else
      raise "Failed after #{max_retries} retries: #{e.message}"
    end
  end
end
```

### Pattern 4: Fallback Values

Provide defaults when operations fail:

```ruby
def execute(action:, path:)
  case action
  when "read"
    begin
      File.read(path)
    rescue Errno::ENOENT
      @logger.warn("File not found: #{path}, returning empty string")
      ""
    rescue Errno::EACCES
      @logger.error("Permission denied: #{path}")
      raise
    end
  end
end
```

### Pattern 5: Error Context

Include context in error messages:

```ruby
def execute(action:, selector:)
  begin
    @driver.click(selector: selector)
  rescue ElementNotFoundError => e
    page_url = @driver.url
    page_title = @driver.title
    available = @driver.find_all_selectors

    raise "Element not found: #{selector}\n" \
          "Page: #{page_title} (#{page_url})\n" \
          "Available selectors: #{available.join(', ')}\n" \
          "Original error: #{e.message}"
  end
end
```

### Pattern 6: Safe Resource Cleanup

Ensure cleanup even on errors:

```ruby
def execute(action:, path:)
  file = nil

  begin
    file = File.open(path, 'w')
    file.write(content)
    "Successfully wrote to #{path}"
  rescue => e
    @logger.error("Failed to write #{path}: #{e.message}")
    raise
  ensure
    file&.close
  end
end
```

## Tool-Specific Patterns

### BrowserTool Error Handling

```ruby
def execute(action:, selector: nil, url: nil)
  case action
  when "visit"
    begin
      @driver.goto(url: url)
    rescue Watir::Exception::UnknownObjectException
      raise "Failed to navigate to #{url}: Invalid URL or page not accessible"
    rescue Net::ReadTimeout
      raise "Navigation timeout: #{url} took too long to load. " \
            "The site may be down or slow."
    rescue => e
      raise "Navigation error: #{e.message}"
    end

  when "click"
    begin
      @driver.click(selector: selector)
    rescue Watir::Exception::UnknownObjectException
      # Try to provide helpful context
      page_html = @driver.html
      similar_selectors = find_similar_selectors(page_html, selector)

      raise "Element not found: #{selector}\n" \
            "Did you mean one of these?\n" \
            "#{similar_selectors.map { |s| "  - #{s}" }.join("\n")}"
    rescue Watir::Exception::ObjectDisabledException
      raise "Element is disabled: #{selector}. " \
            "Wait for the page to fully load or check if element is interactive."
    end
  end
end
```

### DatabaseTool Error Handling

```ruby
def perform(statement:)
  @logger.info("Executing: #{statement}")

  begin
    if statement.match?(/^\s*SELECT/i)
      rows = @db.execute(statement)
      { status: :ok, result: rows }
    else
      @db.execute(statement)
      { status: :ok, result: "#{@db.changes} rows affected" }
    end

  rescue SQLite3::SQLException => e
    # Provide specific error messages
    case e.message
    when /no such table/
      { status: :error, result: "Table does not exist. Create it first." }
    when /syntax error/
      { status: :error, result: "SQL syntax error: #{e.message}" }
    when /constraint/
      { status: :error, result: "Constraint violation: #{e.message}" }
    else
      { status: :error, result: "Database error: #{e.message}" }
    end

  rescue SQLite3::BusyException
    { status: :error, result: "Database is locked. Try again in a moment." }

  rescue => e
    @logger.error("Unexpected error: #{e.class} - #{e.message}")
    { status: :error, result: "Unexpected error: #{e.message}" }
  end
end
```

### DiskTool Error Handling

```ruby
def execute(action:, path:, **params)
  begin
    validate_path!(path)

    case action
    when "file_read"
      File.read(resolve_path(path))
    when "file_write"
      File.write(resolve_path(path), params[:text])
    when "file_delete"
      File.delete(resolve_path(path))
      "Deleted #{path}"
    end

  rescue Errno::ENOENT
    raise "File or directory not found: #{path}"
  rescue Errno::EACCES
    raise "Permission denied: #{path}. Check file permissions."
  rescue Errno::EISDIR
    raise "#{path} is a directory, not a file. Use directory actions."
  rescue Errno::ENOTDIR
    raise "#{path} is a file, not a directory. Use file actions."
  rescue Errno::ENOSPC
    raise "No space left on device. Free up disk space and try again."
  rescue => e
    @logger.error("Filesystem error: #{e.class} - #{e.message}")
    raise "Filesystem error: #{e.message}"
  end
end

private

def validate_path!(path)
  raise ArgumentError, "path cannot be empty" if path.empty?
  raise ArgumentError, "path cannot contain .." if path.include?("..")
  raise ArgumentError, "path must be relative" if path.start_with?("/")
end
```

## Logging Errors

### Log Levels

```ruby
def execute(action:, path:)
  @logger.debug("Executing #{action} on #{path}")

  begin
    result = perform_action(action, path)
    @logger.info("Success: #{action} on #{path}")
    result

  rescue ArgumentError => e
    @logger.warn("Validation error: #{e.message}")
    raise

  rescue => e
    @logger.error("#{action} failed: #{e.class} - #{e.message}")
    @logger.debug(e.backtrace.join("\n"))
    raise
  end
end
```

### Structured Logging

```ruby
def execute(action:, **params)
  context = {
    tool: self.class.name,
    action: action,
    params: params.inspect
  }

  @logger.info(context.merge(status: 'start'))

  begin
    result = perform_action(action, **params)
    @logger.info(context.merge(status: 'success'))
    result

  rescue => e
    @logger.error(context.merge(
      status: 'error',
      error_class: e.class.name,
      error_message: e.message
    ))
    raise
  end
end
```

## User-Friendly Error Messages

### Before (Technical)

```ruby
raise "NoMethodError: undefined method `click' for nil:NilClass"
```

### After (User-Friendly)

```ruby
raise "Could not click element: #{selector}\n" \
      "\n" \
      "The element was not found on the page. This could mean:\n" \
      "- The page hasn't fully loaded yet\n" \
      "- The selector is incorrect\n" \
      "- The element is hidden or removed\n" \
      "\n" \
      "Current page: #{@driver.url}\n" \
      "Try: Wait for page load, check the selector, or inspect the page."
```

## Testing Error Handling

### Test Error Cases

```ruby
RSpec.describe SharedTools::Tools::BrowserTool do
  let(:driver) { instance_double(Browser::WatirDriver) }
  let(:tool) { described_class.new(driver: driver) }

  describe "error handling" do
    it "raises ArgumentError for invalid action" do
      expect {
        tool.execute(action: "invalid")
      }.to raise_error(ArgumentError, /Invalid action/)
    end

    it "raises helpful error when element not found" do
      allow(driver).to receive(:click).and_raise(
        Watir::Exception::UnknownObjectException
      )

      expect {
        tool.execute(action: "click", selector: ".missing")
      }.to raise_error(/Element not found.*missing/)
    end

    it "handles timeout gracefully" do
      allow(driver).to receive(:goto).and_raise(Net::ReadTimeout)

      expect {
        tool.execute(action: "visit", url: "https://slow.com")
      }.to raise_error(/timeout.*slow.com/)
    end
  end
end
```

### Test Error Recovery

```ruby
RSpec.describe "Error recovery" do
  it "retries on transient errors" do
    call_count = 0

    allow(driver).to receive(:perform) do
      call_count += 1
      raise TransientError if call_count < 3
      "success"
    end

    result = tool.execute_with_retry(action: "test")
    expect(result).to eq("success")
    expect(call_count).to eq(3)
  end

  it "gives up after max retries" do
    allow(driver).to receive(:perform).and_raise(TransientError)

    expect {
      tool.execute_with_retry(action: "test", max_retries: 2)
    }.to raise_error(/Failed after 2 retries/)
  end
end
```

## Best Practices

### DO:

- Validate inputs early
- Provide specific error messages
- Include context in errors
- Log errors appropriately
- Clean up resources
- Test error cases
- Document error conditions
- Return structured errors when appropriate

### DON'T:

- Catch all exceptions without reason
- Swallow errors silently
- Expose sensitive information
- Use generic error messages
- Forget to clean up resources
- Ignore error logs
- Assume operations succeed
- Return misleading error messages

## Advanced Patterns

### Circuit Breaker

For external services:

```ruby
class CircuitBreaker
  def initialize(failure_threshold: 5, timeout: 60)
    @failure_count = 0
    @failure_threshold = failure_threshold
    @timeout = timeout
    @last_failure_time = nil
  end

  def call
    raise "Circuit open" if open?

    begin
      result = yield
      reset
      result
    rescue => e
      record_failure
      raise
    end
  end

  private

  def open?
    return false if @failure_count < @failure_threshold

    Time.now - @last_failure_time < @timeout
  end

  def record_failure
    @failure_count += 1
    @last_failure_time = Time.now
  end

  def reset
    @failure_count = 0
    @last_failure_time = nil
  end
end
```

### Error Aggregation

For batch operations:

```ruby
def execute_batch(items:)
  results = []
  errors = []

  items.each do |item|
    begin
      result = process_item(item)
      results << { item: item, status: :ok, result: result }
    rescue => e
      errors << { item: item, status: :error, error: e.message }
    end
  end

  if errors.any?
    {
      status: :partial,
      completed: results.size,
      failed: errors.size,
      errors: errors
    }
  else
    {
      status: :ok,
      completed: results.size,
      results: results
    }
  end
end
```

## Next Steps

- Review [Testing Guide](../development/testing.md)
- Explore [Example Error Handling](https://github.com/madbomber/shared_tools/tree/main/examples)
- Read [API Documentation](../api/index.md)
- Check [Architecture Guide](../development/architecture.md)
