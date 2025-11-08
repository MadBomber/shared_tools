# frozen_string_literal: true

require "test_helper"

class FileDeleteToolTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @tool = SharedTools::Tools::Disk::FileDeleteTool.new(driver: SharedTools::Tools::Disk::LocalDriver.new(root: @temp_dir))
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_tool_name
    assert_equal 'disk_file_delete', SharedTools::Tools::Disk::FileDeleteTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_deletes_file_successfully
    test_file = File.join(@temp_dir, "test.txt")
    File.write(test_file, "Content")
    @tool.execute(path: "./test.txt")
    refute File.exist?(test_file)
  end

  def test_raises_error_for_nonexistent_file
    assert_raises(Errno::ENOENT) do
      @tool.execute(path: "./nonexistent.txt")
    end
  end

  def test_deletes_file_in_subdirectory
    subdir = File.join(@temp_dir, "subdir")
    FileUtils.mkdir_p(subdir)
    test_file = File.join(subdir, "nested.txt")
    File.write(test_file, "Content")
    @tool.execute(path: "./subdir/nested.txt")
    refute File.exist?(test_file)
  end

  def test_raises_security_error_for_path_traversal
    assert_raises(SecurityError) do
      @tool.execute(path: "../outside.txt")
    end
  end
end
