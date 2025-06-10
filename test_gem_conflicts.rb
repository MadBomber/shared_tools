#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script to verify gem conflict detection

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))

puts "Testing SharedTools gem conflict detection"
puts "=" * 50

# Test 1: Load SharedTools alone (no conflicts expected)
puts "\n1. Loading SharedTools alone:"
require 'shared_tools'
detected_gems = SharedTools.check_gem_conflicts
puts "   Detected gems: #{detected_gems.inspect}"
puts "   Expected: Single gem or empty array"

# Test 2: Load ruby_llm gem
puts "\n2. Loading ruby_llm gem:"
begin
  require 'ruby_llm'
  detected_gems = SharedTools.check_gem_conflicts
  puts "   Detected gems: #{detected_gems.inspect}"
  puts "   Expected: ['ruby_llm']"
rescue LoadError
  puts "   ruby_llm gem not available"
end

# Test 3: Load llm.rb gem (this will trigger conflict warning if ruby_llm already loaded)
puts "\n3. Loading llm.rb gem:"
begin
  require 'llm'
  detected_gems = SharedTools.check_gem_conflicts
  puts "   Detected gems: #{detected_gems.inspect}"
  puts "   Expected: ['ruby_llm', 'llm.rb'] with warning, or just ['llm.rb'] if ruby_llm not loaded"
rescue LoadError
  puts "   llm.rb gem not available"
end

# Test 4: Try to load omniai gem if available
puts "\n4. Checking for omniai gem:"
begin
  require 'omniai'
  detected_gems = SharedTools.check_gem_conflicts
  puts "   Detected gems: #{detected_gems.inspect}"
  puts "   Expected: Multiple gems with conflict warning"
rescue LoadError
  puts "   omniai gem not available (expected)"
end

puts "\nTest completed!"