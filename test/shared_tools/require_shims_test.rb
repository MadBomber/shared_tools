# frozen_string_literal: true

require 'test_helper'
require 'open3'
require 'rbconfig'

# Every lib/shared_tools/tools/*_tool.rb gets a lib/shared_tools/*_tool.rb
# shim so `require "shared_tools/<name>_tool"` works for each tool.
class RequireShimsTest < Minitest::Test
  LIB_DIR = File.expand_path('../../lib', __dir__)
  TOOL_NAMES = Dir[File.join(LIB_DIR, 'shared_tools/tools/*_tool.rb')].map do |path|
    File.basename(path, '.rb')
  end.sort

  def test_every_tool_has_a_shim
    refute_empty TOOL_NAMES
    missing = TOOL_NAMES.reject { |name| File.exist?(File.join(LIB_DIR, "shared_tools/#{name}.rb")) }
    assert_empty missing, 'tools without a lib/shared_tools/<name>.rb require shim'
  end


  # Loaded in a child process: requiring tool files directly in the test
  # process interferes with Zeitwerk autoloading for later tests.
  def test_every_shim_loads
    script = TOOL_NAMES.map { |name| "require 'shared_tools/#{name}'" }.join(';')
    _out, err, status = Open3.capture3(RbConfig.ruby, '-I', LIB_DIR, '-e', script)
    assert status.success?, err
  end

  # Each lib/shared_tools/tools/*.rb must load on its own, as the docs show
  # (`require 'shared_tools/tools/weather_tool'`), without the caller having
  # required ruby_llm or shared_tools first. The child process forks once per
  # file (in parallel), so every file is required into a process that has
  # loaded nothing from this gem.
  STANDALONE_SCRIPT = <<~'RUBY'
    pids = ARGV.map do |path|
      fork do
        require path
        exit!(0)
      rescue Exception => e
        $stderr.write("#{path}: #{e.class}: #{e.message}\n")
        exit!(1)
      end
    end
    ok = pids.map { |pid| Process.wait2(pid).last.success? }.all?
    exit(ok ? 0 : 1)
  RUBY

  def test_every_tool_file_loads_standalone
    skip 'needs Process.fork' unless Process.respond_to?(:fork)

    files = Dir[File.join(LIB_DIR, 'shared_tools/tools/*.rb')].sort.map do |path|
      path.delete_prefix("#{LIB_DIR}/").delete_suffix('.rb')
    end
    refute_empty files

    _out, err, status = Open3.capture3(RbConfig.ruby, '-I', LIB_DIR, '-e', STANDALONE_SCRIPT, *files)
    assert status.success?, "tool files that fail to load on their own:\n#{err}"
  end
end
