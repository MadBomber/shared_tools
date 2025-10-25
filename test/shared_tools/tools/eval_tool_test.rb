# frozen_string_literal: true

require "test_helper"

class EvalToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::EvalTool.new
    # Enable auto-execution to bypass user confirmation prompts in tests
    SharedTools.auto_execute(true)
  end

  def teardown
    # Restore default authorization behavior
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal 'eval_tool', SharedTools::Tools::EvalTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_has_all_action_constants
    assert_equal "ruby", SharedTools::Tools::EvalTool::Action::RUBY
    assert_equal "python", SharedTools::Tools::EvalTool::Action::PYTHON
    assert_equal "shell", SharedTools::Tools::EvalTool::Action::SHELL
  end

  def test_ruby_eval_action
    result = @tool.execute(
      action: SharedTools::Tools::EvalTool::Action::RUBY,
      code: "2 + 2"
    )

    assert_kind_of Hash, result
    assert result[:success]
    assert_equal 4, result[:result]
  end

  def test_python_eval_action
    skip "python3 not available" unless system("which python3 > /dev/null 2>&1")

    result = @tool.execute(
      action: SharedTools::Tools::EvalTool::Action::PYTHON,
      code: "2 + 2"
    )

    assert_kind_of Hash, result
    assert result[:success]
    assert_equal 4, result[:result]
  end

  def test_shell_eval_action
    result = @tool.execute(
      action: SharedTools::Tools::EvalTool::Action::SHELL,
      command: "echo 'Hello World'"
    )

    assert_kind_of Hash, result
    assert_includes result[:stdout], "Hello World"
    assert_equal 0, result[:exit_status]
  end

  def test_unsupported_action
    result = @tool.execute(
      action: "invalid_action",
      code: "test"
    )

    assert result.key?(:error)
    assert_includes result[:error], "Unsupported action"
  end

  def test_requires_code_for_ruby
    result = @tool.execute(action: SharedTools::Tools::EvalTool::Action::RUBY)

    assert result.key?(:error)
    assert_includes result[:error], "code"
  end

  def test_requires_command_for_shell
    result = @tool.execute(action: SharedTools::Tools::EvalTool::Action::SHELL)

    assert result.key?(:error)
    assert_includes result[:error], "command"
  end
end
