# frozen_string_literal: true

require "test_helper"

class RubyEvalToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::Eval::RubyEvalTool.new
    # Enable auto-execution to bypass user confirmation prompts in tests
    SharedTools.auto_execute(true)
  end

  def teardown
    # Restore default authorization behavior
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal 'eval_ruby', SharedTools::Tools::Eval::RubyEvalTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_evaluates_simple_expression
    result = @tool.execute(code: "2 + 2")

    assert_kind_of Hash, result
    assert result[:success]
    assert_equal 4, result[:result]
  end

  def test_evaluates_string_expression
    result = @tool.execute(code: "'Hello' + ' ' + 'World'")

    assert result[:success]
    assert_equal "Hello World", result[:result]
  end

  def test_captures_stdout
    result = @tool.execute(code: "puts 'Hello'; 42")

    assert result[:success]
    assert_equal 42, result[:result]
    assert_includes result[:output], "Hello"
  end

  def test_handles_syntax_errors
    result = @tool.execute(code: "invalid ruby syntax {")

    refute result[:success]
    assert result.key?(:error)
    assert result.key?(:backtrace)
  end

  def test_handles_runtime_errors
    result = @tool.execute(code: "1 / 0")

    refute result[:success]
    assert result.key?(:error)
  end

  def test_returns_display_format
    result = @tool.execute(code: "42")

    assert result.key?(:display)
    assert_includes result[:display], "42"
  end

  def test_display_includes_output_and_result
    result = @tool.execute(code: "puts 'Output'; 'Result'")

    assert result[:success]
    assert_includes result[:display], "Output"
    assert_includes result[:display], "Result"
  end

  def test_handles_empty_code
    result = @tool.execute(code: "")

    assert result.key?(:error)
    assert_includes result[:error], "cannot be empty"
  end

  def test_handles_multiline_code
    code = <<~RUBY
      x = 10
      y = 20
      x + y
    RUBY

    result = @tool.execute(code: code)

    assert result[:success]
    assert_equal 30, result[:result]
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
