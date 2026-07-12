# frozen_string_literal: true

require "test_helper"

class GemToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::GemTool.new
  end

  def test_tool_name
    assert_equal "gem", SharedTools::Tools::GemTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_info_action
    result = @tool.execute(name: "ruby_llm")

    assert_kind_of String, result
    assert_includes result, "ruby_llm"
  end

  def test_version_action
    result = @tool.execute(name: "ruby_llm", action: "version")

    assert_kind_of String, result
    assert_match(/ruby_llm \d+\.\d+/, result)
  end

  def test_dependencies_action
    result = @tool.execute(name: "ruby_llm", action: "dependencies")

    assert_kind_of String, result
  end

  def test_search_action
    result = @tool.execute(name: "sqlite3", action: "search")

    assert_kind_of String, result
    assert_includes result, "result"
  end

  def test_unknown_action_returns_error
    result = @tool.execute(name: "ruby_llm", action: "bogus")

    assert result.is_a?(Hash)
    assert_includes result[:error], "unknown action"
  end

  def test_invalid_gem_name_returns_error
    result = @tool.execute(name: "not a valid gem name!")

    assert result.is_a?(Hash)
    assert_includes result[:error], "invalid gem name"
  end

  def test_gem_not_found_returns_error
    result = @tool.execute(name: "this-gem-definitely-does-not-exist-xyz-12345")

    assert result.is_a?(Hash)
    assert_includes result[:error], "not found"
  end
end
