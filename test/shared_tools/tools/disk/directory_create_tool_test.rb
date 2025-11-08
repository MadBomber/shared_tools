# frozen_string_literal: true

require "test_helper"

class DirectoryCreateToolTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @tool = SharedTools::Tools::Disk::DirectoryCreateTool.new(driver: SharedTools::Tools::Disk::LocalDriver.new(root: @temp_dir))
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_tool_name
    assert_equal 'disk_directory_create', SharedTools::Tools::Disk::DirectoryCreateTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_creates_directory_successfully
    @tool.execute(path: "./newdir")
    assert File.directory?(File.join(@temp_dir, "newdir"))
  end

  def test_creates_nested_directories
    @tool.execute(path: "./parent/child/grandchild")
    assert File.directory?(File.join(@temp_dir, "parent"))
    assert File.directory?(File.join(@temp_dir, "parent", "child"))
    assert File.directory?(File.join(@temp_dir, "parent", "child", "grandchild"))
  end

  def test_does_not_fail_if_directory_exists
    dir_path = File.join(@temp_dir, "existing")
    FileUtils.mkdir_p(dir_path)

    # Should not raise an error
    @tool.execute(path: "./existing")
    assert File.directory?(dir_path)
  end

  def test_raises_security_error_for_path_traversal
    assert_raises(SecurityError) do
      @tool.execute(path: "../outside")
    end
  end
end
