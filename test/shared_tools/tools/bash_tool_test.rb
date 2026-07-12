# frozen_string_literal: true

require "test_helper"

class BashToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::BashTool.new(allowed_commands: ["echo", "false"])
    SharedTools.auto_execute(true)
  end

  def teardown
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "bash", SharedTools::Tools::BashTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_runs_an_allowed_command
    result = @tool.execute(command: "echo", args: ["hello"])

    assert_includes result, "exit: 0"
    assert_includes result, "hello"
  end

  def test_reports_nonzero_exit_status
    result = @tool.execute(command: "false")

    assert_includes result, "exit: 1"
  end

  def test_rejects_command_not_on_allowlist
    result = @tool.execute(command: "rm", args: ["-rf", "/"])

    assert result.is_a?(Hash)
    assert_includes result[:error], "not allowed"
  end

  def test_rejects_path_in_command
    result = @tool.execute(command: "/bin/echo")

    assert result.is_a?(Hash)
    assert_includes result[:error], "path"
  end

  def test_rejects_shell_metacharacters
    result = @tool.execute(command: "echo; rm -rf /")

    assert result.is_a?(Hash)
    assert result.key?(:error)
  end

  def test_arguments_are_not_shell_interpreted
    result = @tool.execute(command: "echo", args: ["$(whoami)"])

    assert_includes result, "$(whoami)"
  end

  def test_respects_auto_execute_false
    SharedTools.auto_execute(false)

    with_stdin_input("n") do
      result = @tool.execute(command: "echo", args: ["hi"])
      assert result.is_a?(Hash)
      assert_includes result[:error], "declined"
    end
  end
end
