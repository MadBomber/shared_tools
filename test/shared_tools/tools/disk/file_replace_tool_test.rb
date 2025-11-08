# frozen_string_literal: true

require "test_helper"

class FileReplaceToolTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @tool = SharedTools::Tools::Disk::FileReplaceTool.new(driver: SharedTools::Tools::Disk::LocalDriver.new(root: @temp_dir))
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_tool_name
    assert_equal 'disk_file_replace', SharedTools::Tools::Disk::FileReplaceTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_replaces_text_successfully
    File.write(File.join(@temp_dir, "test.txt"), "Hello World")
    @tool.execute(path: "./test.txt", old_text: "World", new_text: "Universe")
    content = File.read(File.join(@temp_dir, "test.txt"))
    assert_equal "Hello Universe", content
  end

  def test_replaces_multiple_occurrences
    File.write(File.join(@temp_dir, "test.txt"), "foo bar foo")
    @tool.execute(path: "./test.txt", old_text: "foo", new_text: "baz")
    content = File.read(File.join(@temp_dir, "test.txt"))
    assert_equal "baz bar baz", content
  end

  def test_does_nothing_if_old_text_not_found
    original = "Hello World"
    File.write(File.join(@temp_dir, "test.txt"), original)
    @tool.execute(path: "./test.txt", old_text: "NotFound", new_text: "Replacement")
    content = File.read(File.join(@temp_dir, "test.txt"))
    assert_equal original, content
  end

  def test_raises_error_for_nonexistent_file
    assert_raises(Errno::ENOENT) do
      @tool.execute(path: "./nonexistent.txt", old_text: "old", new_text: "new")
    end
  end

  def test_raises_security_error_for_path_traversal
    assert_raises(SecurityError) do
      @tool.execute(path: "../outside.txt", old_text: "old", new_text: "new")
    end
  end
end
