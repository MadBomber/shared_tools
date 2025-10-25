# frozen_string_literal: true

require "test_helper"
require "shared_tools/ruby_llm/read_file"
require "tempfile"

class ReadFileTest < Minitest::Test
  def setup
    @tool = SharedTools::ReadFile.new
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

  # Execute tests - existing file
  def test_reads_existing_file_content
    temp_file = Tempfile.new(["test", ".txt"])
    content = "This is test content"
    temp_file.write(content)
    temp_file.flush

    result = @tool.execute(path: temp_file.path)
    assert_equal content, result

    temp_file.close
    temp_file.unlink
  end

  # Execute tests - non-existent file
  def test_returns_error_for_non_existent_file
    result = @tool.execute(path: "/non/existent/file.txt")
    assert_instance_of Hash, result
    assert_includes result.keys, :error
    assert_includes result[:error], "File does not exist"
  end

  # Execute tests - directory path
  def test_returns_error_for_directory_path
    result = @tool.execute(path: Dir.pwd)
    assert_instance_of Hash, result
    assert_includes result.keys, :error
    assert_includes result[:error], "Path is a directory"
  end

  # Execute tests - unexpected exceptions
  def test_handles_exceptions_during_file_read_gracefully
    temp_file = Tempfile.new(["test", ".txt"])
    temp_file.write("test content")
    temp_file.flush

    # Mock File.read to raise an exception
    File.stub :read, ->(_) { raise StandardError.new("File corrupted") } do
      result = @tool.execute(path: temp_file.path)

      assert_instance_of Hash, result
      assert_includes result.keys, :error
      assert_equal "File corrupted", result[:error]
    end

    temp_file.close
    temp_file.unlink
  end
end
