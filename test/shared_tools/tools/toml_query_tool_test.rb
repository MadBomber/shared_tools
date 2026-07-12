# frozen_string_literal: true

require "test_helper"

class TomlQueryToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::TomlQueryTool.new
    @toml = <<~TOML
      count = 2

      [dependencies.serde]
      version = "1.0"

      [[products]]
      name = "widget"

      [[products]]
      name = "gadget"
    TOML
  end

  def test_tool_name
    assert_equal "toml_query", SharedTools::Tools::TomlQueryTool.name
  end

  def test_pretty_prints_when_no_query
    result = @tool.execute(toml: @toml)

    assert_includes result, '"count": 2'
  end

  def test_extracts_nested_value
    result = @tool.execute(toml: @toml, query: "dependencies.serde.version")

    assert_equal '"1.0"', result
  end

  def test_maps_field_across_array_of_tables
    result = @tool.execute(toml: @toml, query: "products[].name")

    assert_equal JSON.parse(result), %w[widget gadget]
  end

  def test_reads_from_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, "data.toml")
      File.write(path, @toml)

      result = @tool.execute(path: path, query: "count")

      assert_equal "2", result
    end
  end

  def test_no_input_returns_error
    result = @tool.execute

    assert result.is_a?(Hash)
    assert_includes result[:error], "provide either"
  end

  def test_invalid_toml_returns_error
    result = @tool.execute(toml: "key = ")

    assert result.is_a?(Hash)
    assert_includes result[:error], "invalid TOML"
  end
end
