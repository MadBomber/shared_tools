# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  add_filter "/vendor/"

  add_group "Core", "lib/shared_tools.rb"
  add_group "RubyLLM Tools", "lib/shared_tools/ruby_llm"

  minimum_coverage 20
end

require "minitest/autorun"
require "minitest/pride"
require "stringio"
require "ruby_llm"
require "shared_tools"

# Load optional dependencies for tests
begin
  require "nokogiri"
rescue LoadError
  # Nokogiri not available - some tests will be skipped
end

begin
  require "pdf-reader"
rescue LoadError
  # pdf-reader not available - some tests will be skipped
end
