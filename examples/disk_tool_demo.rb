#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: DiskTool
#
# Shows how an LLM performs file system operations — create, read, write,
# move, and delete files and directories — through natural language.
# All operations are sandboxed to a temporary directory for safety.
#
# Run:
#   bundle exec ruby -I examples examples/disk_tool_demo.rb

require_relative 'common'
require 'shared_tools/disk_tool'


require 'tmpdir'
require 'fileutils'

title "DiskTool Demo — LLM-Powered File Operations"

temp_dir = Dir.mktmpdir('disk_tool_demo')
puts "Working directory: #{temp_dir}"
puts

disk_driver = SharedTools::Tools::Disk::LocalDriver.new(root: temp_dir)

@chat = @chat.with_tools(
  SharedTools::Tools::Disk::FileCreateTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::FileReadTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::FileWriteTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::FileReplaceTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::FileMoveTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::FileDeleteTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::DirectoryCreateTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::DirectoryListTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::DirectoryMoveTool.new(driver: disk_driver),
  SharedTools::Tools::Disk::DirectoryDeleteTool.new(driver: disk_driver)
)

begin
  title "Example 1: Create Project Structure", char: '-'
  ask <<~PROMPT
    Create a Ruby project structure:
    - A directory called 'my_app' with lib, spec, and bin subdirectories
    - A README.md with "# My App" as content
    - A Gemfile with just "source 'https://rubygems.org'"
  PROMPT

  title "Example 2: Create and Write Content", char: '-'
  ask "Create a file called 'notes.txt' and write 'Meeting at 3pm tomorrow' in it."

  title "Example 3: Read File Contents", char: '-'
  ask "What's in the notes.txt file?"

  title "Example 4: Update File Content", char: '-'
  ask "In notes.txt, change '3pm' to '4pm'."

  title "Example 5: List Directory", char: '-'
  ask "Show me what files and directories are in the my_app folder."

  title "Example 6: Organize Files", char: '-'
  ask "Move notes.txt into the my_app directory."

  title "Example 7: Multi-Step Workflow", char: '-'
  ask <<~PROMPT
    1. Create a directory called 'docs'
    2. Create a file called 'setup.md' inside it
    3. Write installation instructions in that file
  PROMPT

  title "Example 8: Conversational File Management", char: '-'
  ask "Create a file called 'todo.txt' with the text 'Buy groceries'"
  ask "Add 'Call dentist' to that file."
  ask "Show me what's in the file now."

ensure
  FileUtils.rm_rf(temp_dir)
  puts "Temporary directory removed."
end

title "Done", char: '-'
puts "DiskTool let the LLM manage files and directories through natural language."
