# frozen_string_literal: true

require "test_helper"

class YamlQueryToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::YamlQueryTool.new
    @yaml = <<~YAML
      services:
        - image: nginx
        - image: redis
      count: 2
    YAML
  end

  def test_tool_name
    assert_equal "yaml_query", SharedTools::Tools::YamlQueryTool.name
  end

  def test_pretty_prints_when_no_query
    result = @tool.execute(yaml: @yaml)

    assert_includes result, '"count": 2'
  end

  def test_extracts_value_with_query
    result = @tool.execute(yaml: @yaml, query: "count")

    assert_equal "2", result
  end

  def test_maps_field_across_array
    result = @tool.execute(yaml: @yaml, query: "services[].image")

    assert_equal JSON.parse(result), %w[nginx redis]
  end

  def test_reads_from_file
    Dir.mktmpdir do |dir|
      path = File.join(dir, "data.yml")
      File.write(path, @yaml)

      result = @tool.execute(path: path, query: "count")

      assert_equal "2", result
    end
  end

  def test_no_input_returns_error
    result = @tool.execute

    assert result.is_a?(Hash)
    assert_includes result[:error], "provide either"
  end

  def test_invalid_yaml_returns_error
    result = @tool.execute(yaml: "key: [unterminated")

    assert result.is_a?(Hash)
    assert result.key?(:error)
  end

  def test_disallowed_ruby_object_rejected
    result = @tool.execute(yaml: "--- !ruby/object:SomeClass {}\n")

    assert result.is_a?(Hash)
    assert_includes result[:error], "disallowed"
  end
end
