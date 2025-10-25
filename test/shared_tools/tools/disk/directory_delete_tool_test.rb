# frozen_string_literal: true

require "test_helper"

class DirectoryDeleteToolTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @tool = SharedTools::Tools::Disk::DirectoryDeleteTool.new(driver: SharedTools::Tools::Disk::LocalDriver.new(root: @temp_dir))
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_tool_name
    assert_equal 'disk_directory_delete', SharedTools::Tools::Disk::DirectoryDeleteTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_deletes_empty_directory_successfully
    test_dir = File.join(@temp_dir, "testdir")
    Dir.mkdir(test_dir)

    @tool.execute(path: "./testdir")

    refute File.exist?(test_dir), "Directory should be deleted"
  end

  def test_raises_error_for_nonexistent_directory
    assert_raises(Errno::ENOENT) do
      @tool.execute(path: "./nonexistent")
    end
  end

  def test_raises_error_for_non_empty_directory
    test_dir = File.join(@temp_dir, "nonempty")
    Dir.mkdir(test_dir)
    File.write(File.join(test_dir, "file.txt"), "content")

    assert_raises(Errno::ENOTEMPTY) do
      @tool.execute(path: "./nonempty")
    end
  end

  def test_raises_security_error_for_path_traversal
    assert_raises(SecurityError) do
      @tool.execute(path: "../outside")
    end
  end
end
