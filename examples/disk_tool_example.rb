#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using DiskTool for file and directory operations
#
# This example demonstrates how to use the DiskTool facade to perform
# file system operations like creating, reading, writing, moving, and deleting
# files and directories.

require 'bundler/setup'
require 'shared_tools'
require 'fileutils'
require 'tmpdir'

puts "=" * 80
puts "DiskTool Example - File System Operations"
puts "=" * 80
puts

# Create a temporary directory for our examples
temp_dir = Dir.mktmpdir('disk_tool_demo')
puts "Working in temporary directory: #{temp_dir}"
puts

# Initialize the disk tool with a local driver
# The LocalDriver is sandboxed to the specified root directory for security
disk = SharedTools::Tools::DiskTool.new(
  driver: SharedTools::Tools::Disk::LocalDriver.new(root: temp_dir)
)

begin
  # Example 1: Create a directory
  puts "1. Creating a directory"
  puts "-" * 40
  result = disk.execute(
    action: SharedTools::Tools::DiskTool::Action::DIRECTORY_CREATE,
    path: "./projects"
  )
  puts "Created directory: projects"
  puts

  # Example 2: Create nested directories
  puts "2. Creating nested directories"
  puts "-" * 40
  result = disk.execute(
    action: SharedTools::Tools::DiskTool::Action::DIRECTORY_CREATE,
    path: "./projects/ruby/shared_tools"
  )
  puts "Created nested path: projects/ruby/shared_tools"
  puts

  # Example 3: Create a file
  puts "3. Creating a file"
  puts "-" * 40
  result = disk.execute(
    action: SharedTools::Tools::DiskTool::Action::FILE_CREATE,
    path: "./README.md"
  )
  puts "Created file: README.md"
  puts

  # Example 4: Write content to a file
  puts "4. Writing content to a file"
  puts "-" * 40
  content = <<~TEXT
    # SharedTools Demo

    This is a demo file created by DiskTool.

    ## Features
    - File operations
    - Directory management
    - Path security
  TEXT
  result = disk.execute(
    action: SharedTools::Tools::DiskTool::Action::FILE_WRITE,
    path: "./README.md",
    text: content
  )
  puts "Wrote content to README.md"
  puts

  # Example 5: Read a file
  puts "5. Reading a file"
  puts "-" * 40
  result = disk.execute(
    action: SharedTools::Tools::DiskTool::Action::FILE_READ,
    path: "./README.md"
  )
  puts "File contents:"
  puts result
  puts

  # Example 6: Replace text in a file
  puts "6. Replacing text in a file"
  puts "-" * 40
  result = disk.execute(
    action: SharedTools::Tools::DiskTool::Action::FILE_REPLACE,
    path: "./README.md",
    old_text: "demo file",
    new_text: "example file"
  )
  puts "Replaced 'demo file' with 'example file'"

  # Read it back to verify
  result = disk.execute(
    action: SharedTools::Tools::DiskTool::Action::FILE_READ,
    path: "./README.md"
  )
  puts "Updated contents:"
  puts result
  puts

  # Example 7: List directory contents
  puts "7. Listing directory contents"
  puts "-" * 40

  # Create some more files for demonstration
  disk.execute(
    action: SharedTools::Tools::DiskTool::Action::FILE_CREATE,
    path: "./projects/ruby/app.rb"
  )
  disk.execute(
    action: SharedTools::Tools::DiskTool::Action::FILE_CREATE,
    path: "./projects/ruby/Gemfile"
  )

  result = disk.execute(
    action: SharedTools::Tools::DiskTool::Action::DIRECTORY_LIST,
    path: "."
  )
  puts "Directory listing:"
  puts result
  puts

  # Example 8: Move a file
  puts "8. Moving a file"
  puts "-" * 40
  result = disk.execute(
    action: SharedTools::Tools::DiskTool::Action::FILE_MOVE,
    path: "./README.md",
    destination: "./projects/README.md"
  )
  puts "Moved README.md to projects/"
  puts

  # Example 9: Move a directory
  puts "9. Moving a directory"
  puts "-" * 40
  disk.execute(
    action: SharedTools::Tools::DiskTool::Action::DIRECTORY_CREATE,
    path: "./backup"
  )
  result = disk.execute(
    action: SharedTools::Tools::DiskTool::Action::DIRECTORY_MOVE,
    path: "./projects/ruby",
    destination: "./backup/ruby_project"
  )
  puts "Moved projects/ruby to backup/ruby_project"
  puts

  # Example 10: Delete a file
  puts "10. Deleting a file"
  puts "-" * 40
  result = disk.execute(
    action: SharedTools::Tools::DiskTool::Action::FILE_DELETE,
    path: "./projects/README.md"
  )
  puts "Deleted projects/README.md"
  puts

  # Example 11: Delete an empty directory
  puts "11. Deleting an empty directory"
  puts "-" * 40
  result = disk.execute(
    action: SharedTools::Tools::DiskTool::Action::DIRECTORY_DELETE,
    path: "./projects"
  )
  puts "Deleted empty directory: projects"
  puts

  # Example 12: Demonstrate security - path traversal protection
  puts "12. Security: Path traversal protection"
  puts "-" * 40
  puts "Attempting to access parent directory (should fail)..."
  begin
    disk.execute(
      action: SharedTools::Tools::DiskTool::Action::FILE_CREATE,
      path: "../../../etc/evil.txt"
    )
  rescue SecurityError => e
    puts "✓ Security check passed! Prevented path traversal attack."
    puts "  Error: #{e.message}"
  end
  puts

  # Example 13: Complete workflow - Project setup
  puts "13. Complete Workflow - Project Setup"
  puts "-" * 40
  puts "Creating a new Ruby project structure..."

  # Create directories
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
    puts "  ✓ Created #{dir}"
  end

  # Create files
  files = {
    "./my_app/Gemfile" => "source 'https://rubygems.org'\n\ngem 'shared_tools'\n",
    "./my_app/lib/my_app.rb" => "# frozen_string_literal: true\n\nmodule MyApp\n  VERSION = '0.1.0'\nend\n",
    "./my_app/spec/spec_helper.rb" => "require 'bundler/setup'\nrequire 'my_app'\n",
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
    puts "  ✓ Created #{path}"
  end

  puts "\nProject structure:"
  result = disk.execute(
    action: SharedTools::Tools::DiskTool::Action::DIRECTORY_LIST,
    path: "./my_app"
  )
  puts result
  puts

ensure
  # Cleanup: Remove temporary directory
  puts "Cleaning up temporary directory..."
  FileUtils.rm_rf(temp_dir)
  puts "Temporary directory removed: #{temp_dir}"
end

puts
puts "=" * 80
puts "Example completed successfully!"
puts "=" * 80
