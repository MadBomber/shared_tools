# frozen_string_literal: true

require "test_helper"

class RunTestsToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::RunTestsTool.new(root: ".")
    SharedTools.auto_execute(true)
  end

  def teardown
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "run_tests", SharedTools::Tools::RunTestsTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_detects_minitest_and_runs_scoped_file
    result = @tool.execute(path: "test/shared_tools/tools/todo_write_tool_test.rb")

    assert_includes result, "TESTS PASSED"
  end

  def test_unknown_framework_returns_error
    result = @tool.execute(framework: "bogus")

    assert result.is_a?(Hash)
    assert_includes result[:error], "unknown framework"
  end

  def test_no_framework_detected_returns_error
    Dir.mktmpdir do |dir|
      tool = SharedTools::Tools::RunTestsTool.new(root: dir)
      result = tool.execute

      assert result.is_a?(Hash)
      assert_includes result[:error], "could not detect"
    end
  end

  def test_path_traversal_rejected
    result = @tool.execute(path: "../../etc/passwd")

    assert result.is_a?(Hash)
    assert_includes result[:error], "escapes"
  end

  def test_respects_auto_execute_false
    SharedTools.auto_execute(false)

    with_stdin_input("n") do
      result = @tool.execute(path: "test/shared_tools/tools/todo_write_tool_test.rb")
      assert result.is_a?(Hash)
      assert_includes result[:error], "declined"
    end
  end
end
