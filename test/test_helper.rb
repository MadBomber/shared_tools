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
require "ruby_llm"
require "shared_tools"
