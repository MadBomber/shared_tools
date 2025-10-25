# frozen_string_literal: true

require "test_helper"

class FileWriteToolTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @tool = SharedTools::Tools::Disk::FileWriteTool.new(driver: SharedTools::Tools::Disk::LocalDriver.new(root: @temp_dir))
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_tool_name
    assert_equal 'disk_file_write', SharedTools::Tools::Disk::FileWriteTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_writes_file_successfully
    @tool.execute(path: "./test.txt", text: "Hello World")
    content = File.read(File.join(@temp_dir, "test.txt"))
    assert_equal "Hello World", content
  end

  def test_overwrites_existing_file
    File.write(File.join(@temp_dir, "test.txt"), "Old content")
    @tool.execute(path: "./test.txt", text: "New content")
    content = File.read(File.join(@temp_dir, "test.txt"))
    assert_equal "New content", content
  end

  def test_writes_to_subdirectory
    subdir = File.join(@temp_dir, "subdir")
    FileUtils.mkdir_p(subdir)
    @tool.execute(path: "./subdir/nested.txt", text: "Nested content")
    content = File.read(File.join(subdir, "nested.txt"))
    assert_equal "Nested content", content
  end

  def test_raises_security_error_for_path_traversal
    assert_raises(SecurityError) do
      @tool.execute(path: "../outside.txt", text: "Bad")
    end
  end
end
