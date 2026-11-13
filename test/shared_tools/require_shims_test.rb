# frozen_string_literal: true

require 'test_helper'

# Every lib/shared_tools/tools/*_tool.rb gets a lib/shared_tools/*_tool.rb
# shim so `require "shared_tools/<name>_tool"` works for each tool.
class RequireShimsTest < Minitest::Test
  LIB_DIR = File.expand_path('../../lib/shared_tools', __dir__)
  TOOL_NAMES = Dir[File.join(LIB_DIR, 'tools', '*_tool.rb')].map { |path| File.basename(path, '.rb') }.sort

  def test_tools_directory_has_tools
    refute_empty TOOL_NAMES
  end

  TOOL_NAMES.each do |name|
    define_method("test_require_shim_for_#{name}") do
      assert File.exist?(File.join(LIB_DIR, "#{name}.rb")), "missing shim lib/shared_tools/#{name}.rb"
      require "shared_tools/#{name}"
    end
  end
end
