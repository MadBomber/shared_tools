# frozen_string_literal: true

require "test_helper"

class CsvWriteToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::CsvWriteTool.new
    @dir = Dir.mktmpdir
    SharedTools.auto_execute(true)
  end

  def teardown
    FileUtils.rm_rf(@dir) if @dir && File.exist?(@dir)
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "csv_write", SharedTools::Tools::CsvWriteTool.name
  end

  def test_writes_rows_with_headers
    path = File.join(@dir, "out.csv")

    result = @tool.execute(path: path, headers: %w[name age], rows: [%w[Alice 30], %w[Bob 25]])

    assert_equal "Wrote 2 rows to #{path}", result
    assert_equal "name,age\nAlice,30\nBob,25\n", File.read(path)
  end

  def test_writes_rows_without_headers
    path = File.join(@dir, "out.csv")

    @tool.execute(path: path, rows: [%w[Alice 30]])

    assert_equal "Alice,30\n", File.read(path)
  end

  def test_creates_missing_parent_directories
    path = File.join(@dir, "nested", "deep", "out.csv")

    @tool.execute(path: path, rows: [%w[Alice 30]])

    assert File.exist?(path)
  end

  def test_rows_must_be_an_array
    result = @tool.execute(path: File.join(@dir, "out.csv"), rows: "not an array")

    assert result.is_a?(Hash)
    assert_includes result[:error], "must be an array"
  end

  def test_path_is_a_directory_returns_error
    result = @tool.execute(path: @dir, rows: [%w[Alice 30]])

    assert result.is_a?(Hash)
    assert_includes result[:error], "directory"
  end

  def test_respects_auto_execute_false
    SharedTools.auto_execute(false)
    path = File.join(@dir, "out.csv")

    with_stdin_input("n") do
      result = @tool.execute(path: path, rows: [%w[Alice 30]])
      assert result.is_a?(Hash)
      assert_includes result[:error], "declined"
    end
  end
end
