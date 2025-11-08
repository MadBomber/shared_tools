# DiskTool

Secure file system operations with path traversal protection for managing files and directories.

## Installation

DiskTool is included with SharedTools and requires no additional dependencies:

```ruby
gem 'shared_tools'
```

## Basic Usage

```ruby
require 'shared_tools'

# Initialize with default local driver
disk = SharedTools::Tools::DiskTool.new

# Create and write a file
disk.execute(action: "file_create", path: "./example.txt")
disk.execute(action: "file_write", path: "./example.txt", text: "Hello, World!")

# Read the file
content = disk.execute(action: "file_read", path: "./example.txt")
puts content  # => "Hello, World!"
```

## Security Features

DiskTool includes built-in path traversal protection:

```ruby
require 'tmpdir'

# Create sandboxed disk tool
Dir.mktmpdir do |tmpdir|
  disk = SharedTools::Tools::DiskTool.new(
    driver: SharedTools::Tools::Disk::LocalDriver.new(root: tmpdir)
  )

  # This works (within tmpdir)
  disk.execute(action: "file_create", path: "./safe.txt")

  # This raises SecurityError (path traversal attempt)
  begin
    disk.execute(action: "file_read", path: "../../etc/passwd")
  rescue SecurityError => e
    puts "Blocked: #{e.message}"
  end
end
```

## Actions

### Directory Operations

#### directory_create

Create a directory (including parent directories).

**Parameters:**

- `action`: "directory_create"
- `path`: Directory path to create

**Examples:**

```ruby
# Create single directory
disk.execute(action: "directory_create", path: "./data")

# Create nested directories
disk.execute(action: "directory_create", path: "./data/logs/2025")
```

---

#### directory_delete

Delete an empty directory.

**Parameters:**

- `action`: "directory_delete"
- `path`: Directory path to delete

**Example:**

```ruby
disk.execute(action: "directory_delete", path: "./empty_dir")
```

!!!warning "Directory must be empty"
    This action only deletes empty directories. Use file_delete to remove files first.

---

#### directory_list

List contents of a directory.

**Parameters:**

- `action`: "directory_list"
- `path`: Directory path to list (use "." for current directory)

**Examples:**

```ruby
# List current directory
listing = disk.execute(action: "directory_list", path: ".")
puts listing

# List specific directory
listing = disk.execute(action: "directory_list", path: "./data")
```

---

#### directory_move

Move or rename a directory.

**Parameters:**

- `action`: "directory_move"
- `path`: Source directory path
- `destination`: Destination directory path

**Example:**

```ruby
disk.execute(
  action: "directory_move",
  path: "./old_name",
  destination: "./new_name"
)
```

---

### File Operations

#### file_create

Create an empty file (if it doesn't exist).

**Parameters:**

- `action`: "file_create"
- `path`: File path to create

**Example:**

```ruby
disk.execute(action: "file_create", path: "./notes.txt")
```

---

#### file_delete

Delete a file.

**Parameters:**

- `action`: "file_delete"
- `path`: File path to delete

**Example:**

```ruby
disk.execute(action: "file_delete", path: "./temp.txt")
```

---

#### file_move

Move or rename a file.

**Parameters:**

- `action`: "file_move"
- `path`: Source file path
- `destination`: Destination file path

**Examples:**

```ruby
# Rename file
disk.execute(
  action: "file_move",
  path: "./draft.txt",
  destination: "./final.txt"
)

# Move to different directory
disk.execute(
  action: "file_move",
  path: "./document.txt",
  destination: "./archive/document.txt"
)
```

---

#### file_read

Read the contents of a file.

**Parameters:**

- `action`: "file_read"
- `path`: File path to read

**Example:**

```ruby
content = disk.execute(action: "file_read", path: "./config.txt")
puts content
```

---

#### file_write

Write or overwrite file contents.

**Parameters:**

- `action`: "file_write"
- `path`: File path to write
- `text`: Content to write

**Example:**

```ruby
disk.execute(
  action: "file_write",
  path: "./output.txt",
  text: "Line 1\nLine 2\nLine 3"
)
```

---

#### file_replace

Find and replace text in a file.

**Parameters:**

- `action`: "file_replace"
- `path`: File path
- `old_text`: Text to find
- `new_text`: Replacement text

**Example:**

```ruby
# Replace all occurrences
disk.execute(
  action: "file_replace",
  path: "./config.txt",
  old_text: "localhost",
  new_text: "production.example.com"
)
```

## Complete Examples

### Example 1: Project Setup

```ruby
require 'shared_tools'

disk = SharedTools::Tools::DiskTool.new

# Create project structure
[
  "./myapp",
  "./myapp/lib",
  "./myapp/spec",
  "./myapp/bin"
].each do |dir|
  disk.execute(action: "directory_create", path: dir)
  puts "Created #{dir}"
end

# Create files with content
files = {
  "./myapp/Gemfile" => "source 'https://rubygems.org'\n\ngem 'shared_tools'\n",
  "./myapp/README.md" => "# My App\n\nA Ruby application.\n",
  "./myapp/lib/myapp.rb" => "module MyApp\n  VERSION = '0.1.0'\nend\n"
}

files.each do |path, content|
  disk.execute(action: "file_create", path: path)
  disk.execute(action: "file_write", path: path, text: content)
  puts "Created #{path}"
end

# List project structure
listing = disk.execute(action: "directory_list", path: "./myapp")
puts "\nProject structure:"
puts listing
```

### Example 2: Log File Processor

```ruby
require 'shared_tools'

disk = SharedTools::Tools::DiskTool.new

# Create logs directory
disk.execute(action: "directory_create", path: "./logs")

# Generate log file
log_content = <<~LOG
  [2025-10-25 10:00:00] INFO: Application started
  [2025-10-25 10:00:01] DEBUG: Configuration loaded
  [2025-10-25 10:00:02] ERROR: Connection failed
  [2025-10-25 10:00:03] INFO: Retrying connection
LOG

disk.execute(action: "file_create", path: "./logs/app.log")
disk.execute(action: "file_write", path: "./logs/app.log", text: log_content)

# Read and filter errors
content = disk.execute(action: "file_read", path: "./logs/app.log")
errors = content.lines.select { |line| line.include?("ERROR") }

# Save filtered errors
disk.execute(action: "file_create", path: "./logs/errors.log")
disk.execute(action: "file_write", path: "./logs/errors.log", text: errors.join)

puts "Extracted #{errors.size} errors to errors.log"
```

### Example 3: Configuration File Update

```ruby
require 'shared_tools'

disk = SharedTools::Tools::DiskTool.new

# Create config file
config = <<~CONFIG
  database_host=localhost
  database_port=5432
  api_url=http://localhost:3000
  debug_mode=true
CONFIG

disk.execute(action: "file_create", path: "./config.env")
disk.execute(action: "file_write", path: "./config.env", text: config)

# Update for production
disk.execute(
  action: "file_replace",
  path: "./config.env",
  old_text: "localhost",
  new_text: "production.example.com"
)

disk.execute(
  action: "file_replace",
  path: "./config.env",
  old_text: "debug_mode=true",
  new_text: "debug_mode=false"
)

# Verify changes
updated = disk.execute(action: "file_read", path: "./config.env")
puts "Updated configuration:"
puts updated
```

## Custom Driver

Implement a custom driver for different storage backends:

```ruby
class S3Driver < SharedTools::Tools::Disk::BaseDriver
  def initialize(bucket:, root:)
    @bucket = bucket
    @root = Pathname.new(root)
  end

  def file_read(path:)
    # Read from S3
    s3_key = resolve!(path: path).to_s
    @bucket.object(s3_key).get.body.read
  end

  def file_write(path:, text:)
    # Write to S3
    s3_key = resolve!(path: path).to_s
    @bucket.object(s3_key).put(body: text)
  end

  # Implement other methods...
end

# Use custom driver
s3_bucket = Aws::S3::Bucket.new('my-bucket')
disk = SharedTools::Tools::DiskTool.new(
  driver: S3Driver.new(bucket: s3_bucket, root: '/app-data')
)
```

## Error Handling

```ruby
disk = SharedTools::Tools::DiskTool.new

# Handle file not found
begin
  disk.execute(action: "file_read", path: "./missing.txt")
rescue Errno::ENOENT => e
  puts "File not found: #{e.message}"
end

# Handle permission denied
begin
  disk.execute(action: "file_write", path: "/etc/readonly.txt", text: "data")
rescue Errno::EACCES => e
  puts "Permission denied: #{e.message}"
end

# Handle security violations
begin
  disk.execute(action: "file_read", path: "../../../etc/passwd")
rescue SecurityError => e
  puts "Security violation: #{e.message}"
end
```

## Best Practices

### 1. Use Sandboxed Directories

```ruby
require 'tmpdir'

# All operations restricted to tmpdir
Dir.mktmpdir('myapp') do |tmpdir|
  disk = SharedTools::Tools::DiskTool.new(
    driver: SharedTools::Tools::Disk::LocalDriver.new(root: tmpdir)
  )

  # Safe operations here
  disk.execute(action: "file_create", path: "./safe.txt")
end  # tmpdir automatically cleaned up
```

### 2. Check Before Operating

```ruby
# Check if file exists
if File.exist?("./data.txt")
  content = disk.execute(action: "file_read", path: "./data.txt")
else
  puts "File not found"
end

# Check if directory is empty before deleting
if Dir.empty?("./old_dir")
  disk.execute(action: "directory_delete", path: "./old_dir")
end
```

### 3. Use Relative Paths

```ruby
# Good: Relative path
disk.execute(action: "file_read", path: "./config.txt")

# Avoid: Absolute paths (unless using custom root)
# disk.execute(action: "file_read", path: "/tmp/data.txt")
```

### 4. Handle Large Files Carefully

```ruby
# For large files, consider streaming
path = "./large_file.txt"
File.open(path, 'r') do |file|
  file.each_line do |line|
    # Process line by line
  end
end
```

## Troubleshooting

### Permission Denied

```
Error: Permission denied
```

**Solution:** Check file/directory permissions:

```bash
ls -la ./file.txt
chmod 644 ./file.txt  # Read/write for owner
```

### Directory Not Empty

```
Error: Directory not empty
```

**Solution:** Delete files first:

```ruby
# Delete files in directory
Dir.glob("./mydir/*").each do |file|
  disk.execute(action: "file_delete", path: file)
end

# Then delete directory
disk.execute(action: "directory_delete", path: "./mydir")
```

### Path Traversal Blocked

```
SecurityError: unknown path
```

**Solution:** Use paths relative to the driver's root:

```ruby
# This works
disk.execute(action: "file_read", path: "./data.txt")

# This raises SecurityError
disk.execute(action: "file_read", path: "../../etc/passwd")
```

## See Also

- [Basic Usage](../getting-started/basic-usage.md) - Common patterns
- [Working with Drivers](../guides/drivers.md) - Custom driver implementation
- [Examples](https://github.com/madbomber/shared_tools/tree/main/examples/disk_tool_example.rb)
