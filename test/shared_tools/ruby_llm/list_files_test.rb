# frozen_string_literal: true

require "test_helper"
require "shared_tools/ruby_llm/list_files"
require "tempfile"
require "tmpdir"
require "fileutils"

class ListFilesTest < Minitest::Test
  def setup
    @tool = SharedTools::ListFiles.new
  end

  # Logger integration tests
  def test_logger_methods_are_available
    assert_respond_to RubyLLM, :logger
  end

  def test_logger_is_functional
    assert_respond_to RubyLLM.logger, :info
    assert_respond_to RubyLLM.logger, :debug
    assert_respond_to RubyLLM.logger, :error
  end

  # Execute tests - valid directory
  def test_lists_all_files_and_directories_including_hidden
    temp_dir = Dir.mktmpdir

    # Create test files and directories
    File.write(File.join(temp_dir, "test_file.txt"), "content")
    File.write(File.join(temp_dir, "another_file.rb"), "puts 'hello'")
    Dir.mkdir(File.join(temp_dir, "subdirectory"))
    File.write(File.join(temp_dir, ".hidden_file"), "hidden content")

    result = @tool.execute(path: temp_dir)

    assert_instance_of Array, result
    assert_equal 4, result.size # 2 files + 1 directory + 1 hidden file

    # Check that directories are marked with trailing slash
    directory_entry = result.find { |f| f.include?("subdirectory") }
    assert directory_entry.end_with?("/")

    # Check that files are included
    assert result.any? { |f| f.include?("test_file.txt") }
    assert result.any? { |f| f.include?("another_file.rb") }
    assert result.any? { |f| f.include?(".hidden_file") }

    FileUtils.remove_entry(temp_dir)
  end

  def test_returns_sorted_results
    temp_dir = Dir.mktmpdir
    File.write(File.join(temp_dir, "test_file.txt"), "content")
    File.write(File.join(temp_dir, "another_file.rb"), "puts 'hello'")

    result = @tool.execute(path: temp_dir)

    assert_equal result.sort, result

    FileUtils.remove_entry(temp_dir)
  end

  # Execute tests - current directory default
  def test_lists_files_in_current_directory_by_default
    result = @tool.execute

    assert_instance_of Array, result
    refute_empty result
  end

  # Execute tests - non-existent path
  def test_returns_error_for_non_existent_path
    result = @tool.execute(path: "/non/existent/directory")

    assert_instance_of Hash, result
    assert_includes result.keys, :error
    assert_includes result[:error], "Path does not exist or is not a directory"
  end

  # Execute tests - file path instead of directory
  def test_returns_error_for_file_path
    temp_file = Tempfile.new(["test", ".txt"])
    temp_file.write("content")
    temp_file.flush

    result = @tool.execute(path: temp_file.path)

    assert_instance_of Hash, result
    assert_includes result.keys, :error
    assert_includes result[:error], "Path does not exist or is not a directory"

    temp_file.close
    temp_file.unlink
  end

  # Execute tests - permission errors
  def test_handles_permission_denied_gracefully
    result = @tool.execute(path: "/private/var/root")

    # Either works or returns an error (depending on system permissions)
    assert((result.is_a?(Array) || result.is_a?(Hash)))
    if result.is_a?(Hash)
      assert_includes result.keys, :error
    end
  end

  # Execute tests - unexpected exceptions
  def test_handles_exceptions_during_directory_operations_gracefully
    temp_dir = Dir.mktmpdir

    # Mock Dir.glob to raise an exception
    Dir.stub :glob, ->(_) { raise StandardError.new("I/O error") } do
      result = @tool.execute(path: temp_dir)

      assert_instance_of Hash, result
      assert_includes result.keys, :error
      assert_equal "I/O error", result[:error]
    end

    FileUtils.remove_entry(temp_dir)
  end
end
