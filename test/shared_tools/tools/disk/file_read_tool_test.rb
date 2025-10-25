# frozen_string_literal: true

require "test_helper"

class FileReadToolTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @tool = SharedTools::Tools::Disk::FileReadTool.new(driver: SharedTools::Tools::Disk::LocalDriver.new(root: @temp_dir))
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_tool_name
    assert_equal 'disk_file_read', SharedTools::Tools::Disk::FileReadTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_reads_file_successfully
    File.write(File.join(@temp_dir, "test.txt"), "Hello World")
    result = @tool.execute(path: "./test.txt")
    assert_equal "Hello World", result
  end

  def test_raises_error_for_nonexistent_file
    assert_raises(Errno::ENOENT) do
      @tool.execute(path: "./nonexistent.txt")
    end
  end

  def test_reads_file_with_subdirectory
    subdir = File.join(@temp_dir, "subdir")
    FileUtils.mkdir_p(subdir)
    File.write(File.join(subdir, "nested.txt"), "Nested content")
    result = @tool.execute(path: "./subdir/nested.txt")
    assert_equal "Nested content", result
  end

  def test_raises_security_error_for_path_traversal
    assert_raises(SecurityError) do
      @tool.execute(path: "../outside.txt")
    end
  end
end
