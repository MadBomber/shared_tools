# Driver Interface Documentation

Drivers are pluggable components that allow tools to work with different underlying implementations. This guide covers the driver interface pattern, implementing custom drivers, and using mock drivers for testing.

## What is a Driver?

A driver is an adapter that translates tool commands into operations on an external system:

```
┌──────────────┐     ┌──────────────┐     ┌─────────────────┐
│     Tool     │────▶│    Driver    │────▶│ External System │
│ (BrowserTool)│     │(WatirDriver) │     │  (Web Browser)  │
└──────────────┘     └──────────────┘     └─────────────────┘
```

### Benefits

1. **Swappable Implementations**: Use different browser engines, databases, etc.
2. **Testing**: Use mock drivers for fast, deterministic tests
3. **Platform Independence**: Different drivers for Mac, Linux, Windows
4. **Development**: Mock responses during development

## Driver Types in SharedTools

### BrowserDriver

Interfaces with web browsers:

- **WatirDriver**: Uses Watir gem for browser automation
- **MockBrowserDriver**: Returns predefined HTML for testing

### DatabaseDriver

Interfaces with databases:

- **SqliteDriver**: SQLite database operations
- **PostgresDriver**: PostgreSQL database operations
- **MockDatabaseDriver**: In-memory database simulation

### DiskDriver

Interfaces with file systems:

- **LocalDriver**: Real file system operations
- **MockDiskDriver**: In-memory file system for testing

### ComputerDriver

Interfaces with operating systems:

- **MacDriver**: macOS-specific operations (screenshots, mouse, keyboard)
- **LinuxDriver**: Linux-specific operations (future)

## BaseDriver Classes

Each driver type has a base class defining the interface:

### Browser::BaseDriver

```ruby
module SharedTools
  module Tools
    module Browser
      class BaseDriver
        TIMEOUT = Integer(ENV.fetch("OMNIAI_BROWSER_TIMEOUT", 10))

        def initialize(logger: Logger.new(IO::NULL))
          @logger = logger
        end

        # Close the browser
        def close
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # Get current URL
        # @return [String]
        def url
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # Get page title
        # @return [String]
        def title
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # Get page HTML
        # @return [String]
        def html
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # Take screenshot
        # @yield [file]
        def screenshot
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # Navigate to URL
        # @param url [String]
        # @return [Hash]
        def goto(url:)
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # Fill in form field
        # @param selector [String]
        # @param text [String]
        # @return [Hash]
        def fill_in(selector:, text:)
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # Click element
        # @param selector [String]
        # @return [Hash]
        def click(selector:)
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end
      end
    end
  end
end
```

### Database::BaseDriver

```ruby
module SharedTools
  module Tools
    module Database
      class BaseDriver
        # Execute SQL statement
        # @param statement [String] e.g. "SELECT * FROM users"
        # @return [Hash] e.g. { status: :ok, result: [[1, "John"], [2, "Jane"]] }
        def perform(statement:)
          raise NotImplementedError, "#{self.class}##{__method__} undefined"
        end
      end
    end
  end
end
```

### Disk::BaseDriver

```ruby
module SharedTools
  module Tools
    module Disk
      class BaseDriver
        # Directory operations
        def directory_create(path:)
          raise NotImplementedError
        end

        def directory_delete(path:)
          raise NotImplementedError
        end

        def directory_move(path:, destination:)
          raise NotImplementedError
        end

        def directory_list(path:)
          raise NotImplementedError
        end

        # File operations
        def file_create(path:)
          raise NotImplementedError
        end

        def file_delete(path:)
          raise NotImplementedError
        end

        def file_move(path:, destination:)
          raise NotImplementedError
        end

        def file_read(path:)
          raise NotImplementedError
        end

        def file_write(path:, text:)
          raise NotImplementedError
        end

        def file_replace(path:, old_text:, new_text:)
          raise NotImplementedError
        end
      end
    end
  end
end
```

### Computer::BaseDriver

```ruby
module SharedTools
  module Tools
    module Computer
      class BaseDriver
        def screenshot
          raise NotImplementedError
        end

        def screen_info
          raise NotImplementedError
        end

        def mouse_move(x:, y:)
          raise NotImplementedError
        end

        def mouse_click(button: :left)
          raise NotImplementedError
        end

        def keyboard_type(text:)
          raise NotImplementedError
        end

        def clipboard_get
          raise NotImplementedError
        end

        def clipboard_set(text:)
          raise NotImplementedError
        end
      end
    end
  end
end
```

## Implementing Custom Drivers

### Example: Custom Browser Driver

```ruby
require 'selenium-webdriver'

module SharedTools
  module Tools
    module Browser
      class SeleniumDriver < BaseDriver
        def initialize(browser: :chrome, logger: Logger.new(IO::NULL))
          super(logger: logger)
          @driver = Selenium::WebDriver.for(browser)
        end

        def close
          @driver.quit
        end

        def url
          @driver.current_url
        end

        def title
          @driver.title
        end

        def html
          @driver.page_source
        end

        def screenshot
          tempfile = Tempfile.new(['screenshot', '.png'])
          @driver.save_screenshot(tempfile.path)
          yield tempfile
        ensure
          tempfile.close
          tempfile.unlink
        end

        def goto(url:)
          @logger.info("Navigating to #{url}")
          @driver.get(url)
          { status: :ok, message: "Navigated to #{url}" }
        end

        def fill_in(selector:, text:)
          @logger.info("Filling #{selector} with text")
          element = @driver.find_element(:css, selector)
          element.clear
          element.send_keys(text)
          { status: :ok }
        end

        def click(selector:)
          @logger.info("Clicking #{selector}")
          element = @driver.find_element(:css, selector)
          element.click
          { status: :ok }
        end
      end
    end
  end
end

# Usage
driver = SharedTools::Tools::Browser::SeleniumDriver.new(browser: :firefox)
browser = SharedTools::Tools::BrowserTool.new(driver: driver)
```

### Example: Custom Database Driver

```ruby
require 'mysql2'

module SharedTools
  module Tools
    module Database
      class MysqlDriver < BaseDriver
        def initialize(host:, database:, username:, password:)
          @client = Mysql2::Client.new(
            host: host,
            database: database,
            username: username,
            password: password
          )
        end

        def perform(statement:)
          if statement.match?(/^\s*SELECT/i)
            result = @client.query(statement)
            rows = result.map { |row| row.values }
            { status: :ok, result: rows }
          else
            @client.query(statement)
            { status: :ok, result: "#{@client.affected_rows} rows affected" }
          end
        rescue Mysql2::Error => e
          { status: :error, result: e.message }
        end

        def close
          @client.close
        end
      end
    end
  end
end

# Usage
driver = SharedTools::Tools::Database::MysqlDriver.new(
  host: 'localhost',
  database: 'mydb',
  username: 'user',
  password: 'pass'
)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)
```

### Example: Custom Disk Driver (S3)

```ruby
require 'aws-sdk-s3'

module SharedTools
  module Tools
    module Disk
      class S3Driver < BaseDriver
        def initialize(bucket:, region: 'us-east-1')
          @bucket = bucket
          @s3 = Aws::S3::Client.new(region: region)
        end

        def file_read(path:)
          response = @s3.get_object(bucket: @bucket, key: path)
          response.body.read
        rescue Aws::S3::Errors::NoSuchKey
          raise "File not found: #{path}"
        end

        def file_write(path:, text:)
          @s3.put_object(
            bucket: @bucket,
            key: path,
            body: text
          )
          "Wrote to s3://#{@bucket}/#{path}"
        end

        def file_delete(path:)
          @s3.delete_object(bucket: @bucket, key: path)
          "Deleted s3://#{@bucket}/#{path}"
        end

        def directory_list(path:)
          response = @s3.list_objects_v2(
            bucket: @bucket,
            prefix: path
          )
          response.contents.map(&:key)
        end

        # Implement other required methods...
      end
    end
  end
end

# Usage
driver = SharedTools::Tools::Disk::S3Driver.new(bucket: 'my-bucket')
disk = SharedTools::Tools::DiskTool.new(driver: driver)
```

## Mock Drivers for Testing

### MockBrowserDriver

```ruby
class MockBrowserDriver < SharedTools::Tools::Browser::BaseDriver
  attr_reader :current_url, :actions

  def initialize(responses: {})
    @responses = responses
    @current_url = nil
    @actions = []
  end

  def goto(url:)
    @actions << { action: :goto, url: url }
    @current_url = url
    "Navigated to #{url}"
  end

  def html
    @responses[@current_url] || "<html><body><h1>Default Page</h1></body></html>"
  end

  def title
    "Mock Page"
  end

  def url
    @current_url
  end

  def click(selector:)
    @actions << { action: :click, selector: selector }
    "Clicked #{selector}"
  end

  def fill_in(selector:, text:)
    @actions << { action: :fill_in, selector: selector, text: text }
    "Filled #{selector}"
  end

  def screenshot
    # Return mock PNG data
    yield StringIO.new("fake-png-data")
  end

  def close
    # No-op
  end
end

# Usage in tests
RSpec.describe "Web scraping" do
  let(:responses) do
    {
      "https://example.com/products" => <<~HTML
        <html>
          <body>
            <div class="product">Widget</div>
          </body>
        </html>
      HTML
    }
  end

  let(:driver) { MockBrowserDriver.new(responses: responses) }
  let(:browser) { SharedTools::Tools::BrowserTool.new(driver: driver) }

  it "scrapes products" do
    browser.execute(action: "visit", url: "https://example.com/products")
    html = browser.execute(action: "page_inspect", full_html: true)

    expect(html).to include("Widget")
    expect(driver.actions).to include(
      hash_including(action: :goto, url: "https://example.com/products")
    )
  end
end
```

### MockDatabaseDriver

```ruby
class MockDatabaseDriver < SharedTools::Tools::Database::BaseDriver
  def initialize
    @tables = {}
    @statements = []
  end

  def perform(statement:)
    @statements << statement

    case statement
    when /CREATE TABLE (\w+)/
      table_name = $1
      @tables[table_name] = []
      { status: :ok, result: "Table #{table_name} created" }

    when /INSERT INTO (\w+).*VALUES \((.*)\)/
      table_name = $1
      values = $2.split(',').map(&:strip).map { |v| v.gsub(/['"]/, '') }
      @tables[table_name] ||= []
      @tables[table_name] << values
      { status: :ok, result: "1 row inserted" }

    when /SELECT \* FROM (\w+)/
      table_name = $1
      { status: :ok, result: @tables[table_name] || [] }

    else
      { status: :error, result: "Unsupported statement" }
    end
  end

  attr_reader :statements, :tables
end

# Usage in tests
RSpec.describe "Database operations" do
  let(:driver) { MockDatabaseDriver.new }
  let(:database) { SharedTools::Tools::DatabaseTool.new(driver: driver) }

  it "creates table and inserts data" do
    results = database.execute(statements: [
      "CREATE TABLE users (id, name)",
      "INSERT INTO users VALUES (1, 'Alice')",
      "SELECT * FROM users"
    ])

    expect(results.last[:result]).to eq([["1", "Alice"]])
    expect(driver.tables["users"]).to eq([["1", "Alice"]])
  end
end
```

## Driver Configuration

### Environment-based Configuration

```ruby
class BrowserTool < ::RubyLLM::Tool
  def initialize(driver: nil, logger: nil)
    @driver = driver || default_driver
    @logger = logger || RubyLLM.logger
  end

  private

  def default_driver
    case ENV.fetch('BROWSER_DRIVER', 'watir')
    when 'watir'
      Browser::WatirDriver.new(logger: @logger)
    when 'selenium'
      Browser::SeleniumDriver.new(logger: @logger)
    else
      raise "Unknown browser driver: #{ENV['BROWSER_DRIVER']}"
    end
  end
end
```

### Configuration Objects

```ruby
class DriverConfig
  attr_accessor :browser_driver, :database_driver, :disk_driver

  def initialize
    @browser_driver = :watir
    @database_driver = :sqlite
    @disk_driver = :local
  end
end

SharedTools.configure do |config|
  config.browser_driver = :selenium
  config.database_driver = :postgres
end
```

## Driver Best Practices

### 1. Implement All Required Methods

```ruby
class MyDriver < BaseDriver
  # Implement EVERY method from BaseDriver
  # Use NotImplementedError for unsupported operations:
  def unsupported_method
    raise NotImplementedError, "This driver does not support this operation"
  end
end
```

### 2. Handle Errors Consistently

```ruby
def perform(statement:)
  result = execute_statement(statement)
  { status: :ok, result: result }
rescue SpecificError => e
  { status: :error, result: e.message }
end
```

### 3. Log Operations

```ruby
def goto(url:)
  @logger.info("Navigating to #{url}")
  perform_navigation(url)
  @logger.info("Navigation complete")
end
```

### 4. Clean Up Resources

```ruby
def close
  @connection&.close
  @temp_files.each(&:unlink)
  @connection = nil
end
```

### 5. Provide Helpful Error Messages

```ruby
def click(selector:)
  element = find_element(selector)
  raise "Element not found: #{selector}" unless element

  element.click
rescue ElementNotClickableError => e
  raise "Cannot click #{selector}: #{e.message}"
end
```

## Testing Drivers

```ruby
RSpec.describe SharedTools::Tools::Browser::WatirDriver do
  let(:driver) { described_class.new }

  after { driver.close }

  it "navigates to URL" do
    result = driver.goto(url: "https://example.com")
    expect(result).to include(status: :ok)
    expect(driver.url).to eq("https://example.com")
  end

  it "gets page HTML" do
    driver.goto(url: "https://example.com")
    html = driver.html
    expect(html).to include("<html")
  end

  it "clicks elements" do
    driver.goto(url: "https://example.com")
    expect {
      driver.click(selector: "#button")
    }.not_to raise_error
  end
end
```

## Next Steps

- Review [Tool Base Class](./tool-base.md) documentation
- Learn about [Facade Pattern](./facade-pattern.md)
- See [Example Implementations](../examples/index.md)
- Check out existing [Driver Source Code](https://github.com/madbomber/shared_tools/tree/main/lib/shared_tools/tools)
