# Working with Drivers

SharedTools uses a driver architecture that provides flexibility and extensibility. Learn how to use built-in drivers and create custom implementations.

## Driver Architecture

Drivers are the backend implementations that actually perform operations. Tools delegate to drivers using a well-defined interface, following the **Strategy pattern**.

### Benefits

- **Flexibility**: Swap implementations without changing tool code
- **Extensibility**: Add support for new backends
- **Testability**: Mock drivers for testing
- **Separation of Concerns**: Tools focus on interface, drivers on implementation

### Architecture Diagram

```
┌─────────────────┐
│   Tool (Facade) │  ← User interacts with tool
└────────┬────────┘
         │ delegates to
         ▼
┌─────────────────┐
│  Driver (Impl)  │  ← Driver performs actual work
└─────────────────┘
         │
         ▼
┌─────────────────┐
│  Backend System │  ← File system, database, browser, etc.
└─────────────────┘
```

## Built-in Drivers

SharedTools includes several built-in drivers:

### Disk Drivers

#### LocalDriver

Default driver for local file system operations.

**Features:**

- Path traversal protection
- Sandboxing to root directory
- Standard file operations

**Usage:**

```ruby
require 'shared_tools'

# Default: uses current directory as root
disk = SharedTools::Tools::DiskTool.new

# Custom root directory
driver = SharedTools::Tools::Disk::LocalDriver.new(root: '/tmp')
disk = SharedTools::Tools::DiskTool.new(driver: driver)
```

**Path Security:**

```ruby
driver = SharedTools::Tools::Disk::LocalDriver.new(root: '/tmp')

# This works (within /tmp)
driver.file_read(path: './data.txt')  # Reads /tmp/data.txt

# This raises SecurityError (path traversal)
driver.file_read(path: '../../etc/passwd')  # Blocked!
```

### Browser Drivers

#### WatirDriver

Default driver for browser automation using Watir.

**Features:**

- Full browser control
- JavaScript execution
- Screenshot capture
- Multiple browser support

**Usage:**

```ruby
require 'watir'

# Default: uses Watir with Chrome
browser = SharedTools::Tools::BrowserTool.new

# Custom Watir configuration
driver = SharedTools::Tools::Browser::WatirDriver.new(
  browser: :firefox,
  headless: true
)
browser = SharedTools::Tools::BrowserTool.new(driver: driver)
```

### Database Drivers

#### SqliteDriver

Driver for SQLite databases.

**Usage:**

```ruby
require 'sqlite3'

db = SQLite3::Database.new('./app.db')
driver = SharedTools::Tools::Database::SqliteDriver.new(db: db)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)
```

#### PostgresDriver

Driver for PostgreSQL databases.

**Usage:**

```ruby
require 'pg'

conn = PG.connect(dbname: 'myapp', user: 'postgres')
driver = SharedTools::Tools::Database::PostgresDriver.new(db: conn)
database = SharedTools::Tools::DatabaseTool.new(driver: driver)
```

## Creating Custom Drivers

### Step 1: Understand the Interface

Each driver type has a base class that defines the required interface:

- `SharedTools::Tools::Disk::BaseDriver` - File operations
- `SharedTools::Tools::Browser::BaseDriver` - Browser operations
- `SharedTools::Tools::Database::BaseDriver` - Database operations

### Step 2: Inherit from Base Driver

```ruby
class MyCustomDriver < SharedTools::Tools::Disk::BaseDriver
  # Implement required methods
end
```

### Step 3: Implement Required Methods

Check the base driver class for required methods and implement them.

## Custom Driver Examples

### Example 1: S3 Disk Driver

Store files in Amazon S3 instead of local file system:

```ruby
require 'aws-sdk-s3'

class S3Driver < SharedTools::Tools::Disk::BaseDriver
  def initialize(bucket_name:, region: 'us-east-1', prefix: '')
    @s3 = Aws::S3::Resource.new(region: region)
    @bucket = @s3.bucket(bucket_name)
    @prefix = prefix
    @root = Pathname.new(prefix)
  end

  def file_create(path:)
    s3_key = resolve_key(path)
    @bucket.object(s3_key).put(body: '') unless object_exists?(s3_key)
  end

  def file_read(path:)
    s3_key = resolve_key(path)
    @bucket.object(s3_key).get.body.read
  end

  def file_write(path:, text:)
    s3_key = resolve_key(path)
    @bucket.object(s3_key).put(body: text)
  end

  def file_delete(path:)
    s3_key = resolve_key(path)
    @bucket.object(s3_key).delete
  end

  def directory_list(path: '.')
    s3_prefix = resolve_key(path) + '/'

    objects = @bucket.objects(prefix: s3_prefix)
    objects.map { |obj| obj.key.sub(s3_prefix, '') }.join("\n")
  end

  # ... implement other required methods

private

  def resolve_key(path)
    full_path = @root.join(path)

    # Security check
    relative = full_path.ascend.any? { |ancestor| ancestor == @root }
    raise SecurityError, "Invalid path: #{path}" unless relative

    full_path.to_s
  end

  def object_exists?(key)
    @bucket.object(key).exists?
  end
end

# Usage
driver = S3Driver.new(
  bucket_name: 'my-app-storage',
  region: 'us-west-2',
  prefix: 'app-data'
)

disk = SharedTools::Tools::DiskTool.new(driver: driver)

# Now operates on S3
disk.execute(action: "file_write", path: "./data.txt", text: "Hello S3!")
```

### Example 2: FTP Disk Driver

Access files via FTP:

```ruby
require 'net/ftp'

class FtpDriver < SharedTools::Tools::Disk::BaseDriver
  def initialize(host:, user:, password:, root: '/')
    @host = host
    @user = user
    @password = password
    @root = Pathname.new(root)
  end

  def file_read(path:)
    with_ftp do |ftp|
      ftp_path = resolve_path(path)
      ftp.getbinaryfile(ftp_path, nil)
    end
  end

  def file_write(path:, text:)
    with_ftp do |ftp|
      ftp_path = resolve_path(path)

      # Write to temp file first
      require 'tempfile'
      Tempfile.create do |tmpfile|
        tmpfile.write(text)
        tmpfile.rewind
        ftp.putbinaryfile(tmpfile.path, ftp_path)
      end
    end
  end

  def directory_list(path: '.')
    with_ftp do |ftp|
      ftp_path = resolve_path(path)
      ftp.chdir(ftp_path)
      ftp.list.join("\n")
    end
  end

  # ... implement other methods

private

  def with_ftp
    ftp = Net::FTP.new(@host)
    ftp.login(@user, @password)
    ftp.passive = true

    yield ftp
  ensure
    ftp.close if ftp
  end

  def resolve_path(path)
    full_path = @root.join(path)

    # Security check
    relative = full_path.ascend.any? { |ancestor| ancestor == @root }
    raise SecurityError, "Invalid path: #{path}" unless relative

    full_path.to_s
  end
end

# Usage
driver = FtpDriver.new(
  host: 'ftp.example.com',
  user: 'username',
  password: 'password',
  root: '/home/user/app'
)

disk = SharedTools::Tools::DiskTool.new(driver: driver)
```

### Example 3: Logging Disk Driver (Decorator Pattern)

Wrap another driver to add logging:

```ruby
require 'logger'

class LoggingDiskDriver < SharedTools::Tools::Disk::BaseDriver
  def initialize(driver:, logger: Logger.new(STDOUT))
    @driver = driver
    @logger = logger
  end

  def file_read(path:)
    @logger.info("Reading file: #{path}")
    start_time = Time.now

    result = @driver.file_read(path: path)

    duration = Time.now - start_time
    @logger.info("Read completed in #{duration}s")

    result
  rescue StandardError => e
    @logger.error("Read failed: #{e.message}")
    raise
  end

  def file_write(path:, text:)
    @logger.info("Writing file: #{path} (#{text.bytesize} bytes)")
    start_time = Time.now

    result = @driver.file_write(path: path, text: text)

    duration = Time.now - start_time
    @logger.info("Write completed in #{duration}s")

    result
  rescue StandardError => e
    @logger.error("Write failed: #{e.message}")
    raise
  end

  # Delegate all other methods
  def method_missing(method, **args)
    @driver.send(method, **args)
  end

  def respond_to_missing?(method, include_private = false)
    @driver.respond_to?(method, include_private) || super
  end
end

# Usage
base_driver = SharedTools::Tools::Disk::LocalDriver.new(root: '/tmp')
logging_driver = LoggingDiskDriver.new(driver: base_driver)
disk = SharedTools::Tools::DiskTool.new(driver: logging_driver)

# Operations are logged
disk.execute(action: "file_write", path: "./test.txt", text: "data")
# Output: Writing file: ./test.txt (4 bytes)
#         Write completed in 0.001s
```

### Example 4: Memory Disk Driver (Testing)

In-memory file system for testing:

```ruby
class MemoryDiskDriver < SharedTools::Tools::Disk::BaseDriver
  def initialize
    @files = {}
    @directories = Set.new(['.'])
    @root = Pathname.new('.')
  end

  def file_create(path:)
    @files[path] = '' unless @files.key?(path)
  end

  def file_read(path:)
    raise Errno::ENOENT, "File not found: #{path}" unless @files.key?(path)
    @files[path]
  end

  def file_write(path:, text:)
    @files[path] = text
  end

  def file_delete(path:)
    @files.delete(path)
  end

  def directory_create(path:)
    @directories.add(path)
  end

  def directory_list(path: '.')
    prefix = path == '.' ? '' : "#{path}/"

    files = @files.keys.select { |f| f.start_with?(prefix) }
    dirs = @directories.select { |d| d.start_with?(prefix) && d != path }

    (files + dirs.to_a).sort.join("\n")
  end

  def directory_delete(path:)
    @directories.delete(path)
  end

  # ... implement other methods
end

# Usage in tests
require 'minitest/autorun'

class MyTest < Minitest::Test
  def setup
    driver = MemoryDiskDriver.new
    @disk = SharedTools::Tools::DiskTool.new(driver: driver)
  end

  def test_file_operations
    @disk.execute(action: "file_create", path: "./test.txt")
    @disk.execute(action: "file_write", path: "./test.txt", text: "test")

    content = @disk.execute(action: "file_read", path: "./test.txt")
    assert_equal "test", content
  end
end
```

### Example 5: Headless Browser Driver

Custom browser driver with different defaults:

```ruby
class HeadlessBrowserDriver < SharedTools::Tools::Browser::BaseDriver
  def initialize
    require 'watir'
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--disable-gpu')
    options.add_argument('--no-sandbox')

    @browser = Watir::Browser.new(:chrome, options: options)
  end

  def close
    @browser.close
  end

  def url
    @browser.url
  end

  def title
    @browser.title
  end

  def html
    @browser.html
  end

  def goto(url:)
    @browser.goto(url)
    { success: true, url: url }
  end

  def click(selector:)
    element = @browser.element(css: selector)
    element.click
    { success: true, selector: selector }
  end

  def fill_in(selector:, text:)
    element = @browser.element(css: selector)
    element.set(text)
    { success: true, selector: selector }
  end

  def screenshot
    require 'tempfile'

    Tempfile.create(['screenshot', '.png']) do |file|
      @browser.screenshot.save(file.path)
      yield file
    end
  end
end

# Usage
driver = HeadlessBrowserDriver.new
browser = SharedTools::Tools::BrowserTool.new(driver: driver)

# Runs in headless mode
browser.execute(action: "visit", url: "https://example.com")
```

## Driver Testing

### Testing Custom Drivers

```ruby
require 'minitest/autorun'

class S3DriverTest < Minitest::Test
  def setup
    # Use mock S3 or LocalStack for testing
    @driver = S3Driver.new(
      bucket_name: 'test-bucket',
      region: 'us-east-1'
    )
  end

  def test_file_write_and_read
    @driver.file_write(path: './test.txt', text: 'hello')
    content = @driver.file_read(path: './test.txt')
    assert_equal 'hello', content
  end

  def test_path_traversal_protection
    assert_raises(SecurityError) do
      @driver.file_read(path: '../../etc/passwd')
    end
  end

  def teardown
    # Clean up test data
  end
end
```

### Integration Testing

```ruby
class DriverIntegrationTest < Minitest::Test
  def test_with_tool
    driver = MemoryDiskDriver.new
    disk = SharedTools::Tools::DiskTool.new(driver: driver)

    # Test through tool interface
    disk.execute(action: "file_create", path: "./test.txt")
    disk.execute(action: "file_write", path: "./test.txt", text: "data")

    content = disk.execute(action: "file_read", path: "./test.txt")
    assert_equal "data", content
  end
end
```

## Best Practices

### 1. Implement Complete Interface

Implement all methods required by the base driver:

```ruby
class MyDriver < SharedTools::Tools::Disk::BaseDriver
  # Implement ALL methods from BaseDriver
  def file_create(path:); end
  def file_read(path:); end
  def file_write(path:, text:); end
  # ... etc
end
```

### 2. Provide Security Checks

Always validate paths and inputs:

```ruby
def file_read(path:)
  validate_path!(path)
  # ... perform operation
end

private

def validate_path!(path)
  # Check for path traversal
  raise SecurityError if path.include?('..')

  # Check against whitelist
  raise SecurityError unless path.start_with?(@allowed_prefix)
end
```

### 3. Handle Errors Gracefully

Return meaningful error messages:

```ruby
def file_read(path:)
  # ... perform operation
rescue Errno::ENOENT
  raise Errno::ENOENT, "File not found: #{path}"
rescue Errno::EACCES
  raise Errno::EACCES, "Permission denied: #{path}"
end
```

### 4. Support Configuration

Allow driver configuration:

```ruby
class MyDriver < SharedTools::Tools::Disk::BaseDriver
  def initialize(options = {})
    @timeout = options[:timeout] || 30
    @retry_count = options[:retry_count] || 3
    @logger = options[:logger] || Logger.new(STDOUT)
  end
end
```

### 5. Document Driver Behavior

```ruby
# Custom driver for Google Cloud Storage
#
# @example
#   driver = GcsDriver.new(
#     project_id: 'my-project',
#     bucket_name: 'my-bucket',
#     credentials_path: './credentials.json'
#   )
#
# @param project_id [String] GCP project ID
# @param bucket_name [String] GCS bucket name
# @param credentials_path [String] Path to service account credentials
#
class GcsDriver < SharedTools::Tools::Disk::BaseDriver
  # ...
end
```

## Troubleshooting

### Driver Method Not Implemented

```
NotImplementedError: MyDriver#file_read undefined
```

**Solution:** Implement all required methods from base driver.

### Type Errors

```
TypeError: wrong number of arguments
```

**Solution:** Match method signatures from base driver exactly:

```ruby
# Base driver signature
def file_write(path:, text:)

# Custom driver must match
def file_write(path:, text:)  # Use keyword arguments
  # ...
end
```

### Connection Errors

For network-based drivers, handle connection failures:

```ruby
def file_read(path:)
  retries = 0
  max_retries = 3

  begin
    # ... perform operation
  rescue ConnectionError => e
    retries += 1
    retry if retries < max_retries
    raise
  end
end
```

## See Also

- [Basic Usage](../getting-started/basic-usage.md) - Using drivers with tools
- [DiskTool](../tools/disk.md) - Disk driver examples
- [BrowserTool](../tools/browser.md) - Browser driver examples
- [DatabaseTool](../tools/database.md) - Database driver examples
- [Examples](https://github.com/madbomber/shared_tools/tree/main/examples)
