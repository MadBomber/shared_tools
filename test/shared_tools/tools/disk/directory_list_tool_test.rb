# frozen_string_literal: true

require "test_helper"

class DirectoryListToolTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @tool = SharedTools::Tools::Disk::DirectoryListTool.new(driver: SharedTools::Tools::Disk::LocalDriver.new(root: @temp_dir))
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_tool_name
    assert_equal 'disk_directory_list', SharedTools::Tools::Disk::DirectoryListTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_lists_empty_directory
    result = @tool.execute(path: ".")
    assert_equal "", result
  end

  def test_lists_directory_with_files
    File.write(File.join(@temp_dir, "file1.txt"), "Content")
    File.write(File.join(@temp_dir, "file2.txt"), "Content")

    result = @tool.execute(path: ".")
    assert_includes result, "file1.txt"
    assert_includes result, "file2.txt"
  end

  def test_lists_directory_with_subdirectories
    subdir = File.join(@temp_dir, "subdir")
    FileUtils.mkdir_p(subdir)
    File.write(File.join(subdir, "nested.txt"), "Content")

    result = @tool.execute(path: ".")
    assert_includes result, "subdir"
  end

  def test_lists_specific_subdirectory
    subdir = File.join(@temp_dir, "subdir")
    FileUtils.mkdir_p(subdir)
    File.write(File.join(subdir, "nested.txt"), "Content")

    result = @tool.execute(path: "./subdir")
    assert_includes result, "nested.txt"
  end

  def test_raises_security_error_for_path_traversal
    assert_raises(SecurityError) do
      @tool.execute(path: "../outside")
    end
  end
end
