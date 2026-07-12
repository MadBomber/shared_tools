# frozen_string_literal: true

require "test_helper"

class JsonQueryToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::JsonQueryTool.new
    @json = '{"users":[{"name":"Alice","age":30},{"name":"Bob","age":25}],"count":2}'
  end

  def test_tool_name
    assert_equal "json_query", SharedTools::Tools::JsonQueryTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_pretty_prints_when_no_query
    result = @tool.execute(json: @json)

    assert_includes result, '"count": 2'
  end

  def test_extracts_value_with_query
    result = @tool.execute(json: @json, query: "count")

    assert_equal "2", result
  end

  def test_extracts_array_index
    result = @tool.execute(json: @json, query: "users[0].name")

    assert_equal '"Alice"', result
  end

  def test_maps_field_across_array
    result = @tool.execute(json: @json, query: "users[].name")

    assert_equal JSON.parse(result), %w[Alice Bob]
  end

  def test_reads_from_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, "data.json")
      File.write(path, @json)

      result = @tool.execute(path: path, query: "count")

      assert_equal "2", result
    end
  end

  def test_missing_file_returns_error
    result = @tool.execute(path: "/nonexistent/data.json")

    assert result.is_a?(Hash)
    assert_includes result[:error], "not found"
  end

  def test_no_input_returns_error
    result = @tool.execute

    assert result.is_a?(Hash)
    assert_includes result[:error], "provide either"
  end

  def test_invalid_json_returns_error
    result = @tool.execute(json: "{not valid")

    assert result.is_a?(Hash)
    assert_includes result[:error], "invalid JSON"
  end

  def test_bad_query_returns_error
    result = @tool.execute(json: @json, query: "users.name")

    assert result.is_a?(Hash)
    assert result.key?(:error)
  end
end
