#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Run every *_demo.rb file in the examples directory sequentially.
#
# Usage:
#   bundle exec ruby examples/all.rb
#   ruby examples/all.rb          # from project root

demos = Dir[File.join(__dir__, '*_demo.rb')].sort

puts "Found #{demos.size} demo(s) to run."
puts

demos.each do |demo|
  name = File.basename(demo)
  puts "#{'=' * 60}"
  puts "Running: #{name}"
  puts "#{'=' * 60}"

  system(RbConfig.ruby, demo)

  puts
end

puts "#{'=' * 60}"
puts "All #{demos.size} demo(s) finished."
puts "#{'=' * 60}"
