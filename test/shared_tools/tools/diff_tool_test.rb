# frozen_string_literal: true

require "test_helper"

class DiffToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::DiffTool.new
  end

  def test_tool_name
    assert_equal "diff", SharedTools::Tools::DiffTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_no_differences
    result = @tool.execute(old: "a\nb\n", new: "a\nb\n")

    assert_equal "(no differences)", result
  end

  def test_shows_added_and_removed_lines
    result = @tool.execute(old: "a\nb\nc\n", new: "a\nX\nc\n")

    assert_includes result, "- b"
    assert_includes result, "+ X"
  end

  def test_default_labels
    result = @tool.execute(old: "a\n", new: "b\n")

    assert_includes result, "--- old"
    assert_includes result, "+++ new"
  end

  def test_custom_labels
    result = @tool.execute(old: "a\n", new: "b\n", old_label: "before", new_label: "after")

    assert_includes result, "--- before"
    assert_includes result, "+++ after"
  end
end
