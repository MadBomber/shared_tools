# frozen_string_literal: true

require "test_helper"

class FileMoveToolTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @tool = SharedTools::Tools::Disk::FileMoveTool.new(driver: SharedTools::Tools::Disk::LocalDriver.new(root: @temp_dir))
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_tool_name
    assert_equal 'disk_file_move', SharedTools::Tools::Disk::FileMoveTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_moves_file_successfully
    source_file = File.join(@temp_dir, "source.txt")
    File.write(source_file, "Content")
    @tool.execute(path: "./source.txt", destination: "./dest.txt")

    refute File.exist?(source_file)
    assert File.exist?(File.join(@temp_dir, "dest.txt"))
    assert_equal "Content", File.read(File.join(@temp_dir, "dest.txt"))
  end

  def test_raises_error_for_nonexistent_file
    assert_raises(Errno::ENOENT) do
      @tool.execute(path: "./nonexistent.txt", destination: "./dest.txt")
    end
  end

  def test_moves_file_to_subdirectory
    File.write(File.join(@temp_dir, "source.txt"), "Content")
    subdir = File.join(@temp_dir, "subdir")
    FileUtils.mkdir_p(subdir)

    @tool.execute(path: "./source.txt", destination: "./subdir/dest.txt")

    refute File.exist?(File.join(@temp_dir, "source.txt"))
    assert File.exist?(File.join(subdir, "dest.txt"))
  end

  def test_raises_security_error_for_path_traversal
    File.write(File.join(@temp_dir, "source.txt"), "Content")

    assert_raises(SecurityError) do
      @tool.execute(path: "./source.txt", destination: "../outside.txt")
    end
  end
end
