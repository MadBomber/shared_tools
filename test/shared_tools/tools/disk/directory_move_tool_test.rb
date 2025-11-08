# frozen_string_literal: true

require "test_helper"

class DirectoryMoveToolTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @tool = SharedTools::Tools::Disk::DirectoryMoveTool.new(driver: SharedTools::Tools::Disk::LocalDriver.new(root: @temp_dir))
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_tool_name
    assert_equal 'disk_directory_move', SharedTools::Tools::Disk::DirectoryMoveTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_moves_directory_successfully
    source_dir = File.join(@temp_dir, "source")
    FileUtils.mkdir_p(source_dir)
    File.write(File.join(source_dir, "file.txt"), "Content")

    @tool.execute(path: "./source", destination: "./dest")

    refute File.exist?(source_dir)
    assert File.directory?(File.join(@temp_dir, "dest"))
    assert File.exist?(File.join(@temp_dir, "dest", "file.txt"))
  end

  def test_raises_error_for_nonexistent_directory
    assert_raises(Errno::ENOENT) do
      @tool.execute(path: "./nonexistent", destination: "./dest")
    end
  end

  def test_moves_directory_to_subdirectory
    source_dir = File.join(@temp_dir, "source")
    parent_dir = File.join(@temp_dir, "parent")
    FileUtils.mkdir_p(source_dir)
    FileUtils.mkdir_p(parent_dir)
    File.write(File.join(source_dir, "file.txt"), "Content")

    @tool.execute(path: "./source", destination: "./parent/moved")

    refute File.exist?(source_dir)
    assert File.directory?(File.join(parent_dir, "moved"))
    assert File.exist?(File.join(parent_dir, "moved", "file.txt"))
  end

  def test_raises_security_error_for_path_traversal
    source_dir = File.join(@temp_dir, "source")
    FileUtils.mkdir_p(source_dir)

    assert_raises(SecurityError) do
      @tool.execute(path: "./source", destination: "../outside")
    end
  end
end
