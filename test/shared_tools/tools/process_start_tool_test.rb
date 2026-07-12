# frozen_string_literal: true

require "test_helper"

class ProcessStartToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::ProcessStartTool.new(allowed_commands: ["sleep", "echo"])
    SharedTools.auto_execute(true)
  end

  def teardown
    SharedTools::ProcessRegistry.reset!
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "process_start", SharedTools::Tools::ProcessStartTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_starts_a_background_process
    result = @tool.execute(command: "sleep", args: ["1"], name: "napper")

    assert_match(/\AStarted proc_\d+/, result)
    proc = SharedTools::ProcessRegistry.get(result[/proc_\d+/])
    assert proc.running?
    assert_equal "napper", proc.name
  end

  def test_rejects_command_not_on_allowlist
    result = @tool.execute(command: "rm", args: ["-rf", "/"])

    assert result.is_a?(Hash)
    assert_includes result[:error], "not allowed"
  end

  def test_rejects_shell_metacharacters
    result = @tool.execute(command: "sleep; rm -rf /")

    assert result.is_a?(Hash)
    assert result.key?(:error)
  end

  def test_respects_process_limit
    tool = SharedTools::Tools::ProcessStartTool.new(allowed_commands: ["sleep"], max_processes: 1)
    tool.execute(command: "sleep", args: ["1"])

    result = tool.execute(command: "sleep", args: ["1"])

    assert result.is_a?(Hash)
    assert_includes result[:error], "too many background processes"
  end

  def test_respects_auto_execute_false
    SharedTools.auto_execute(false)

    with_stdin_input("n") do
      result = @tool.execute(command: "sleep", args: ["1"])
      assert result.is_a?(Hash)
      assert_includes result[:error], "declined"
    end
  end
end
