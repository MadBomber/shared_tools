#!/usr/bin/env ruby
# frozen_string_literal: true

# Simple script to test SharedTools::RunShellCommand version detection

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))

# Helper method to detect which version of RunShellCommand is loaded
def detect_run_shell_command_version
  return :not_defined unless SharedTools.const_defined?(:RunShellCommand, false)
  
  run_shell_command = SharedTools::RunShellCommand
  
  if run_shell_command.is_a?(Class) && defined?(::RubyLLM::Tool) && run_shell_command < ::RubyLLM::Tool
    :ruby_llm
  elsif run_shell_command.respond_to?(:call) && run_shell_command.instance_variables.include?(:@description)
    :llm_rb
  else
    :unknown
  end
end

def clear_run_shell_command
  SharedTools.send(:remove_const, :RunShellCommand) if SharedTools.const_defined?(:RunShellCommand, false)
end

puts "Testing SharedTools::RunShellCommand version detection"
puts "=" * 60

# First, load the llm gem to make it available
begin
  require 'llm'
  puts "llm.rb gem loaded: #{defined?(::LLM)}"
rescue LoadError
  puts "llm.rb gem not available"
end

# Load SharedTools first
require 'shared_tools'
puts "SharedTools loaded. Available constants: #{SharedTools.constants.sort}"

# Test 1: No RunShellCommand defined initially
puts "\n1. Initial state:"
puts "   RunShellCommand defined: #{SharedTools.const_defined?(:RunShellCommand, false)}"
puts "   Version detected: #{detect_run_shell_command_version}"

# Test 2: Load ruby_llm and test that version
begin
  require 'ruby_llm'
  puts "\n2. Loading ruby_llm version:"
  SharedTools.load_ruby_llm_tools
  puts "   RunShellCommand defined: #{SharedTools.const_defined?(:RunShellCommand, false)}"
  puts "   Version detected: #{detect_run_shell_command_version}"
  puts "   Class: #{SharedTools::RunShellCommand.class}" if SharedTools.const_defined?(:RunShellCommand, false)
  puts "   Inherits from RubyLLM::Tool: #{SharedTools::RunShellCommand < ::RubyLLM::Tool}" if SharedTools.const_defined?(:RunShellCommand, false)
  
  # Store reference for comparison
  ruby_llm_version = SharedTools::RunShellCommand
  clear_run_shell_command
rescue LoadError
  puts "\n2. ruby_llm gem not available"
end

# Test 3: Load llm.rb and test that version  
begin
  require 'llm'
  puts "\n3. Loading llm.rb version:"
  puts "   LLM constant available: #{defined?(::LLM)}"
  SharedTools::LLM # Trigger autoloading
  puts "   RunShellCommand defined: #{SharedTools.const_defined?(:RunShellCommand, false)}"
  puts "   Version detected: #{detect_run_shell_command_version}"
  if SharedTools.const_defined?(:RunShellCommand, false)
    puts "   Class: #{SharedTools::RunShellCommand.class}"
    puts "   Responds to call: #{SharedTools::RunShellCommand.respond_to?(:call)}"
    # Store reference for comparison
    llm_rb_version = SharedTools::RunShellCommand
  else
    puts "   Note: RunShellCommand not defined - the llm.rb version only loads if the LLM gem is available"
  end
rescue LoadError
  puts "\n3. llm.rb gem not available"
end

# Test 4: Compare the two versions if both are available
if defined?(ruby_llm_version) && defined?(llm_rb_version)
  puts "\n4. Comparison:"
  puts "   ruby_llm version class: #{ruby_llm_version.class}"
  puts "   llm.rb version class: #{llm_rb_version.class}"
  puts "   Same object: #{ruby_llm_version == llm_rb_version}"
  puts "   Same class: #{ruby_llm_version.class == llm_rb_version.class}"
end

puts "\nTest completed successfully!"