# frozen_string_literal: true

require "test_helper"

class DiskToolTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @tool = SharedTools::Tools::DiskTool.new(
      driver: SharedTools::Tools::Disk::LocalDriver.new(root: @temp_dir)
    )
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_tool_name
    assert_equal 'disk_tool', SharedTools::Tools::DiskTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_has_all_action_constants
    assert_equal "directory_create", SharedTools::Tools::DiskTool::Action::DIRECTORY_CREATE
    assert_equal "directory_delete", SharedTools::Tools::DiskTool::Action::DIRECTORY_DELETE
    assert_equal "directory_move", SharedTools::Tools::DiskTool::Action::DIRECTORY_MOVE
    assert_equal "directory_list", SharedTools::Tools::DiskTool::Action::DIRECTORY_LIST
    assert_equal "file_create", SharedTools::Tools::DiskTool::Action::FILE_CREATE
    assert_equal "file_delete", SharedTools::Tools::DiskTool::Action::FILE_DELETE
    assert_equal "file_move", SharedTools::Tools::DiskTool::Action::FILE_MOVE
    assert_equal "file_read", SharedTools::Tools::DiskTool::Action::FILE_READ
    assert_equal "file_write", SharedTools::Tools::DiskTool::Action::FILE_WRITE
    assert_equal "file_replace", SharedTools::Tools::DiskTool::Action::FILE_REPLACE
  end

  def test_file_create_action
    @tool.execute(action: SharedTools::Tools::DiskTool::Action::FILE_CREATE, path: "./test.txt")
    assert File.exist?(File.join(@temp_dir, "test.txt"))
  end

  def test_file_write_action
    @tool.execute(action: SharedTools::Tools::DiskTool::Action::FILE_WRITE, path: "./test.txt", text: "Hello")
    assert_equal "Hello", File.read(File.join(@temp_dir, "test.txt"))
  end

  def test_file_read_action
    File.write(File.join(@temp_dir, "test.txt"), "Content")
    result = @tool.execute(action: SharedTools::Tools::DiskTool::Action::FILE_READ, path: "./test.txt")
    assert_equal "Content", result
  end

  def test_file_delete_action
    test_file = File.join(@temp_dir, "test.txt")
    File.write(test_file, "Content")
    @tool.execute(action: SharedTools::Tools::DiskTool::Action::FILE_DELETE, path: "./test.txt")
    refute File.exist?(test_file)
  end

  def test_file_move_action
    File.write(File.join(@temp_dir, "source.txt"), "Content")
    @tool.execute(
      action: SharedTools::Tools::DiskTool::Action::FILE_MOVE,
      path: "./source.txt",
      destination: "./dest.txt"
    )
    refute File.exist?(File.join(@temp_dir, "source.txt"))
    assert File.exist?(File.join(@temp_dir, "dest.txt"))
  end

  def test_file_replace_action
    File.write(File.join(@temp_dir, "test.txt"), "Hello World")
    @tool.execute(
      action: SharedTools::Tools::DiskTool::Action::FILE_REPLACE,
      path: "./test.txt",
      old_text: "World",
      new_text: "Universe"
    )
    assert_equal "Hello Universe", File.read(File.join(@temp_dir, "test.txt"))
  end

  def test_directory_create_action
    @tool.execute(action: SharedTools::Tools::DiskTool::Action::DIRECTORY_CREATE, path: "./newdir")
    assert File.directory?(File.join(@temp_dir, "newdir"))
  end

  def test_directory_delete_action
    dir_path = File.join(@temp_dir, "testdir")
    FileUtils.mkdir_p(dir_path)
    @tool.execute(action: SharedTools::Tools::DiskTool::Action::DIRECTORY_DELETE, path: "./testdir")
    refute File.exist?(dir_path)
  end

  def test_directory_move_action
    source_dir = File.join(@temp_dir, "source")
    FileUtils.mkdir_p(source_dir)
    @tool.execute(
      action: SharedTools::Tools::DiskTool::Action::DIRECTORY_MOVE,
      path: "./source",
      destination: "./dest"
    )
    refute File.exist?(source_dir)
    assert File.directory?(File.join(@temp_dir, "dest"))
  end

  def test_directory_list_action
    File.write(File.join(@temp_dir, "file1.txt"), "Content")
    result = @tool.execute(action: SharedTools::Tools::DiskTool::Action::DIRECTORY_LIST, path: ".")
    assert_kind_of String, result
    assert_includes result, "file1.txt"
  end
end
