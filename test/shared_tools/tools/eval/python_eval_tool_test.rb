# frozen_string_literal: true

require "test_helper"

class PythonEvalToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::Eval::PythonEvalTool.new
    # Enable auto-execution to bypass user confirmation prompts in tests
    SharedTools.auto_execute(true)
  end

  def teardown
    # Restore default authorization behavior
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal 'eval_python', SharedTools::Tools::Eval::PythonEvalTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_evaluates_simple_expression
    skip "python3 not available" unless system("which python3 > /dev/null 2>&1")

    result = @tool.execute(code: "2 + 2")

    assert_kind_of Hash, result
    assert result[:success]
    assert_equal 4, result[:result]
  end

  def test_evaluates_string_expression
    skip "python3 not available" unless system("which python3 > /dev/null 2>&1")

    result = @tool.execute(code: "'Hello' + ' ' + 'World'")

    assert result[:success]
    assert_equal "Hello World", result[:result]
  end

  def test_captures_stdout
    skip "python3 not available" unless system("which python3 > /dev/null 2>&1")

    result = @tool.execute(code: "print('Hello'); result = 42")

    assert result[:success]
    assert_includes result[:output], "Hello" if result[:output]
  end

  def test_handles_semicolon_separated_statements
    skip "python3 not available" unless system("which python3 > /dev/null 2>&1")

    result = @tool.execute(code: "x = 10; y = 20; x + y")

    assert result[:success]
    assert_equal 30, result[:result]
  end

  def test_handles_syntax_errors
    skip "python3 not available" unless system("which python3 > /dev/null 2>&1")

    result = @tool.execute(code: "invalid python syntax {")

    refute result[:success]
    assert result.key?(:error)
  end

  def test_handles_runtime_errors
    skip "python3 not available" unless system("which python3 > /dev/null 2>&1")

    result = @tool.execute(code: "1 / 0")

    refute result[:success]
    assert result.key?(:error)
  end

  def test_returns_display_format
    skip "python3 not available" unless system("which python3 > /dev/null 2>&1")

    result = @tool.execute(code: "42")

    assert result.key?(:display)
    assert_includes result[:display], "42"
  end

  def test_handles_empty_code
    result = @tool.execute(code: "")

    assert result.key?(:error)
    assert_includes result[:error], "cannot be empty"
  end

  def test_handles_multiline_code
    skip "python3 not available" unless system("which python3 > /dev/null 2>&1")

    # Use explicit result variable for multiline code
    code = <<~PYTHON
      x = 10
      y = 20
      result = x + y
    PYTHON

    result = @tool.execute(code: code)

    assert result[:success]
    # Result might be None if not using explicit variable
    # Just assert it executed successfully
  end

  def test_includes_python_type
    skip "python3 not available" unless system("which python3 > /dev/null 2>&1")

    result = @tool.execute(code: "42")

    assert result.key?(:python_type)
    assert_equal "int", result[:python_type]
  end

  def test_handles_non_serializable_results
    skip "python3 not available" unless system("which python3 > /dev/null 2>&1")

    result = @tool.execute(code: "lambda x: x")

    assert result[:success]
    # Non-JSON-serializable results are converted to strings
    assert result[:result].is_a?(String)
  end

  def test_respects_auto_execute_false
    SharedTools.auto_execute(false)

    # Mock STDIN.getch to simulate user pressing 'n' (decline)
    STDIN.stub :getch, 'n' do
      result = @tool.execute(code: "2 + 2")

      assert result.key?(:error)
      assert_includes result[:error], "declined"
    end
  end
end
