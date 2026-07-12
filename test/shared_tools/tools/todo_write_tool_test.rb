# frozen_string_literal: true

require "test_helper"

class TodoWriteToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::TodoWriteTool.new
  end

  def test_tool_name
    assert_equal "todo_write", SharedTools::Tools::TodoWriteTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_empty_list
    result = @tool.execute(todos: [])

    assert_equal "Task list is empty.", result
  end

  def test_renders_tasks_with_marks
    result = @tool.execute(todos: [
      { content: "write tests", status: "completed" },
      { content: "ship it", status: "in_progress" },
      { content: "celebrate", status: "pending" }
    ])

    assert_includes result, "[x] write tests"
    assert_includes result, "[~] ship it"
    assert_includes result, "[ ] celebrate"
    assert_includes result, "1/3 complete"
  end

  def test_each_call_replaces_the_previous_list
    @tool.execute(todos: [{ content: "old task", status: "pending" }])
    result = @tool.execute(todos: [{ content: "new task", status: "pending" }])

    refute_includes result, "old task"
    assert_includes result, "new task"
  end

  def test_non_array_todos_returns_error
    result = @tool.execute(todos: "not an array")

    assert result.is_a?(Hash)
    assert_includes result[:error], "must be an array"
  end

  def test_invalid_status_returns_error
    result = @tool.execute(todos: [{ content: "x", status: "bogus" }])

    assert result.is_a?(Hash)
    assert_includes result[:error], "invalid status"
  end

  def test_missing_status_defaults_to_pending
    result = @tool.execute(todos: [{ content: "x" }])

    assert_includes result, "[ ] x"
  end
end
