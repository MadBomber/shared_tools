# frozen_string_literal: true

require "test_helper"

class CsvReadToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::CsvReadTool.new
    @dir = Dir.mktmpdir
    @path = File.join(@dir, "data.csv")
    File.write(@path, "name,age\nAlice,30\nBob,25\n")
  end

  def teardown
    FileUtils.rm_rf(@dir) if @dir && File.exist?(@dir)
  end

  def test_tool_name
    assert_equal "csv_read", SharedTools::Tools::CsvReadTool.name
  end

  def test_reads_rows_with_headers
    result = @tool.execute(path: @path)

    assert_includes result, "columns: name | age"
    assert_includes result, "name=Alice, age=30"
    assert_includes result, "name=Bob, age=25"
  end

  def test_reads_rows_without_headers
    result = @tool.execute(path: @path, headers: false)

    refute_includes result, "columns:"
    assert_includes result, "name | age"
  end

  def test_respects_limit
    result = @tool.execute(path: @path, limit: 1)

    assert_includes result, "(showing 1)"
    assert_includes result, "Alice"
    refute_includes result, "Bob"
  end

  def test_missing_file_returns_error
    result = @tool.execute(path: "/nonexistent/data.csv")

    assert result.is_a?(Hash)
    assert_includes result[:error], "not found"
  end

  def test_empty_csv
    empty_path = File.join(@dir, "empty.csv")
    File.write(empty_path, "")

    result = @tool.execute(path: empty_path)

    assert_equal "empty CSV", result
  end

  def test_malformed_csv_returns_error
    bad_path = File.join(@dir, "bad.csv")
    File.write(bad_path, "a,\"b\n")

    result = @tool.execute(path: bad_path)

    assert result.is_a?(Hash)
    assert_includes result[:error], "malformed CSV"
  end
end
