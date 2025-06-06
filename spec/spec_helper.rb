# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/vendor/"
  
  add_group "Core", "lib/shared_tools.rb"
  add_group "Logging", "lib/shared_tools/core.rb"
  add_group "RubyLLM Tools", "lib/shared_tools/ruby_llm"
  
  minimum_coverage 80
end

require "ruby_llm"
require "shared_tools"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
