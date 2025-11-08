#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using DiskTool with LLM Integration
#
# This example demonstrates how an LLM can perform file system operations
# through natural language prompts using the DiskTool.

require_relative 'ruby_llm_config'
require 'tmpdir'
require 'fileutils'

title "DiskTool Example - LLM-Powered File Operations"

# Create a temporary directory for our examples
temp_dir = Dir.mktmpdir('disk_tool_demo')
puts "Working in temporary directory: #{temp_dir}"
puts

# Initialize the disk tool with a local driver
# The LocalDriver is sandboxed to the specified root directory for security
disk_driver = SharedTools::Tools::Disk::LocalDriver.new(root: temp_dir)

# Register the DiskTools with RubyLLM
tools = [
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
]

# Create a chat instance using ollama_chat helper
@chat = ollama_chat()

# Add tools to the chat
tools.each { |tool| @chat = @chat.with_tool(tool) }

begin
  # Example 1: Create a project structure
  title "Example 1: Create Project Structure", bc: '-'
  prompt = <<~PROMPT
    Create a new Ruby project structure with the following:
    - A directory called 'my_app'
    - Inside it: lib, spec, and bin directories
    - A README.md file with "# My App" as content
    - A Gemfile with just "source 'https://rubygems.org'"
  PROMPT
  test_with_prompt prompt

  # Example 2: Create and write a file
  title "Example 2: Create and Write Content", bc: '-'
  prompt = "Create a file called 'notes.txt' and write 'Meeting at 3pm tomorrow' in it."
  test_with_prompt prompt

  # Example 3: Read file contents
  title "Example 3: Read File Contents", bc: '-'
  prompt = "What's in the notes.txt file?"
  test_with_prompt prompt

  # Example 4: Update file content
  title "Example 4: Update File Content", bc: '-'
  prompt = "In the notes.txt file, change '3pm' to '4pm'."
  test_with_prompt prompt

  # Example 5: List directory contents
  title "Example 5: List Directory", bc: '-'
  prompt = "Show me what files and directories are in the my_app folder."
  test_with_prompt prompt

  # Example 6: Organize files
  title "Example 6: Organize Files", bc: '-'
  prompt = "Move the notes.txt file into the my_app directory."
  test_with_prompt prompt

  # Example 7: Multi-step workflow
  title "Example 7: Multi-Step Workflow", bc: '-'
  prompt = <<~PROMPT
    I need to:
    1. Create a new directory called 'docs'
    2. Create a file in it called 'setup.md'
    3. Write installation instructions in that file
    Can you do that for me?
  PROMPT
  test_with_prompt prompt

  # Example 8: Conversational context
  title "Example 8: Conversational File Management", bc: '-'

  prompt = "Create a file called 'todo.txt' with the text 'Buy groceries'"
  test_with_prompt prompt

  prompt = "Now add 'Call dentist' to that file."
  test_with_prompt prompt

  prompt = "Show me what's in the file now."
  test_with_prompt prompt

  # Example 9: List all created files
  title "Example 9: Review All Files", bc: '-'
  prompt = "Can you list all the files and directories we've created in this session?"
  test_with_prompt prompt

ensure
  # Cleanup: Remove temporary directory
  title "Cleaning up temporary directory...", bc: '-'
  FileUtils.rm_rf(temp_dir)
  puts "Temporary directory removed: #{temp_dir}"
end

title "Example completed!"

puts <<~TAKEAWAYS

  Key Takeaways:
  - The LLM can perform complex file operations through natural language
  - Security is built-in with sandboxed directory access
  - Multi-step workflows are handled intelligently
  - The LLM maintains context about files and operations
  - File management becomes conversational and intuitive

TAKEAWAYS
