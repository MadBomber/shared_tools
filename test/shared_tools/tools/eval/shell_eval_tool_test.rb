# frozen_string_literal: true

require "test_helper"

class ShellEvalToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::Eval::ShellEvalTool.new
    # Enable auto-execution to bypass user confirmation prompts in tests
    SharedTools.auto_execute(true)
  end

  def teardown
    # Restore default authorization behavior
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal 'eval_shell', SharedTools::Tools::Eval::ShellEvalTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_executes_simple_command
    result = @tool.execute(command: "echo 'Hello World'")

    assert_kind_of Hash, result
    assert_includes result[:stdout], "Hello World"
    assert_equal 0, result[:exit_status]
  end

  def test_captures_stdout
    result = @tool.execute(command: "echo 'test output'")

    assert_includes result[:stdout], "test output"
  end

  def test_handles_command_with_exit_code_zero
    result = @tool.execute(command: "true")

    assert_equal 0, result[:exit_status]
    refute result.key?(:error)
  end

  def test_handles_command_with_nonzero_exit_code
    result = @tool.execute(command: "false")

    assert result.key?(:error)
    assert_equal 1, result[:exit_status]
    assert result.key?(:stderr)
  end

  def test_captures_stderr
    result = @tool.execute(command: "ls nonexistent_file_xyz 2>&1")

    # Command should fail and have stderr or error
    assert(result.key?(:stderr) || result.key?(:error))
  end

  def test_handles_invalid_command
    result = @tool.execute(command: "nonexistent_command_xyz")

    assert result.key?(:error)
    refute_equal 0, result[:exit_status]
  end

  def test_handles_empty_command
    result = @tool.execute(command: "")

    assert result.key?(:error)
    assert_includes result[:error], "cannot be empty"
  end

  def test_handles_whitespace_only_command
    result = @tool.execute(command: "   ")

    assert result.key?(:error)
    assert_includes result[:error], "cannot be empty"
  end

  def test_handles_multiline_command
    command = <<~SHELL
      echo "Line 1"
      echo "Line 2"
    SHELL

    result = @tool.execute(command: command)

    assert_equal 0, result[:exit_status]
    assert_includes result[:stdout], "Line 1"
    assert_includes result[:stdout], "Line 2"
  end

  def test_handles_piped_commands
    result = @tool.execute(command: "echo 'hello world' | grep 'world'")

    assert_equal 0, result[:exit_status]
    assert_includes result[:stdout], "world"
  end

  def test_handles_command_with_environment_variables
    result = @tool.execute(command: "TEST_VAR=test_value && echo $TEST_VAR")

    assert_equal 0, result[:exit_status]
    assert_includes result[:stdout], "test_value"
  end

  def test_respects_auto_execute_false
    SharedTools.auto_execute(false)

    # Mock STDIN.getch to simulate user pressing 'n' (decline)
    STDIN.stub :getch, 'n' do
      result = @tool.execute(command: "echo 'test'")

      assert result.key?(:error)
      assert_includes result[:error], "declined"
    end
  end

  def test_handles_command_with_special_characters
    result = @tool.execute(command: "echo 'Hello! @#$%'")

    assert_equal 0, result[:exit_status]
    assert_includes result[:stdout], "Hello! @#$%"
  end
end
