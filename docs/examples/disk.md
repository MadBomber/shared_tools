# Disk Tool Example

The DiskTool provides a secure, sandboxed interface for file system operations. It handles file and directory creation, reading, writing, moving, and deletion with built-in path traversal protection.

## Overview

This example demonstrates how to use the DiskTool facade to perform file system operations safely. The tool uses a LocalDriver that is sandboxed to a specific root directory for security.

## Example Code

View the complete example: [disk_tool_example.rb](https://github.com/madbomber/shared_tools/blob/main/examples/disk_tool_example.rb)

## Key Features

### 1. Directory Operations

Create directories:

```ruby
disk = SharedTools::Tools::DiskTool.new(
  driver: SharedTools::Tools::Disk::LocalDriver.new(root: temp_dir)
)

# Create a single directory
disk.execute(
  action: SharedTools::Tools::DiskTool::Action::DIRECTORY_CREATE,
  path: "./projects"
)

# Create nested directories
disk.execute(
  action: SharedTools::Tools::DiskTool::Action::DIRECTORY_CREATE,
  path: "./projects/ruby/shared_tools"
)
```

List directory contents:

```ruby
result = disk.execute(
  action: SharedTools::Tools::DiskTool::Action::DIRECTORY_LIST,
  path: "."
)
```

Move and delete directories:

```ruby
# Move
disk.execute(
  action: SharedTools::Tools::DiskTool::Action::DIRECTORY_MOVE,
  path: "./projects/ruby",
  destination: "./backup/ruby_project"
)

# Delete
disk.execute(
  action: SharedTools::Tools::DiskTool::Action::DIRECTORY_DELETE,
  path: "./projects"
)
```

### 2. File Operations

Create and write files:

```ruby
# Create a file
disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_CREATE,
  path: "./README.md"
)

# Write content
content = <<~TEXT
  # SharedTools Demo

  This is a demo file created by DiskTool.
TEXT

disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_WRITE,
  path: "./README.md",
  text: content
)
```

Read files:

```ruby
result = disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_READ,
  path: "./README.md"
)
puts result
```

### 3. Text Replacement

Replace text in files:

```ruby
disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_REPLACE,
  path: "./README.md",
  old_text: "demo file",
  new_text: "example file"
)
```

### 4. Moving and Deleting Files

```ruby
# Move
disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_MOVE,
  path: "./README.md",
  destination: "./projects/README.md"
)

# Delete
disk.execute(
  action: SharedTools::Tools::DiskTool::Action::FILE_DELETE,
  path: "./projects/README.md"
)
```

## Security Features

The DiskTool includes built-in path traversal protection:

```ruby
# This will raise a SecurityError
begin
  disk.execute(
    action: SharedTools::Tools::DiskTool::Action::FILE_CREATE,
    path: "../../../etc/evil.txt"
  )
rescue SecurityError => e
  puts "Security check passed! Prevented path traversal attack."
end
```

## Complete Workflow Example

The example includes a complete project setup workflow:

```ruby
# Create project structure
%w[
  ./my_app
  ./my_app/lib
  ./my_app/spec
  ./my_app/bin
].each do |dir|
  disk.execute(
    action: SharedTools::Tools::DiskTool::Action::DIRECTORY_CREATE,
    path: dir
  )
end

# Create files with content
files = {
  "./my_app/Gemfile" => "source 'https://rubygems.org'\n\ngem 'shared_tools'\n",
  "./my_app/lib/my_app.rb" => "# frozen_string_literal: true\n\nmodule MyApp\n  VERSION = '0.1.0'\nend\n",
  "./my_app/README.md" => "# My App\n\nA new Ruby application.\n"
}

files.each do |path, content|
  disk.execute(
    action: SharedTools::Tools::DiskTool::Action::FILE_CREATE,
    path: path
  )
  disk.execute(
    action: SharedTools::Tools::DiskTool::Action::FILE_WRITE,
    path: path,
    text: content
  )
end
```

## Available Actions

### Directory Actions
- `DIRECTORY_CREATE` - Create directories
- `DIRECTORY_LIST` - List directory contents
- `DIRECTORY_MOVE` - Move directories
- `DIRECTORY_DELETE` - Delete empty directories

### File Actions
- `FILE_CREATE` - Create files
- `FILE_READ` - Read file contents
- `FILE_WRITE` - Write content to files
- `FILE_REPLACE` - Replace text in files
- `FILE_MOVE` - Move files
- `FILE_DELETE` - Delete files

## Run the Example

```bash
cd examples
bundle exec ruby disk_tool_example.rb
```

The example creates a temporary directory, performs various file operations, and cleans up afterward.

## Related Documentation

- [DiskTool Documentation](../tools/disk.md)
- [Facade Pattern](../api/facade-pattern.md)
- [Driver Interface](../api/driver-interface.md)
- [Authorization System](../guides/authorization.md)

## Notes

- All operations are sandboxed to the root directory specified in the driver
- Path traversal attacks are automatically prevented
- Supports both relative and absolute paths (within the sandbox)
- The LocalDriver normalizes and validates all paths
- Directories must be empty before deletion
