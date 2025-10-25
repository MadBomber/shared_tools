# frozen_string_literal: true

require "test_helper"

class FileCreateToolTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @tool = SharedTools::Tools::Disk::FileCreateTool.new(driver: SharedTools::Tools::Disk::LocalDriver.new(root: @temp_dir))
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_tool_name
    assert_equal 'disk_file_create', SharedTools::Tools::Disk::FileCreateTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_creates_file_successfully
    @tool.execute(path: "./test.txt")
    assert File.exist?(File.join(@temp_dir, "test.txt"))
  end

  def test_does_not_overwrite_existing_file
    test_file = File.join(@temp_dir, "test.txt")
    File.write(test_file, "Existing content")
    @tool.execute(path: "./test.txt")
    content = File.read(test_file)
    assert_equal "Existing content", content
  end

  def test_creates_file_in_subdirectory
    subdir = File.join(@temp_dir, "subdir")
    FileUtils.mkdir_p(subdir)
    @tool.execute(path: "./subdir/nested.txt")
    assert File.exist?(File.join(subdir, "nested.txt"))
  end

  def test_raises_security_error_for_path_traversal
    assert_raises(SecurityError) do
      @tool.execute(path: "../outside.txt")
    end
  end
end
