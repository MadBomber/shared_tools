# frozen_string_literal: true

require "test_helper"

class ProcessKillToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::ProcessKillTool.new
    SharedTools.auto_execute(true)
  end

  def teardown
    SharedTools::ProcessRegistry.reset!
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "process_kill", SharedTools::Tools::ProcessKillTool.name
  end

  def test_kills_a_running_process
    start = SharedTools::Tools::ProcessStartTool.new(allowed_commands: ["sleep"])
    id = start.execute(command: "sleep", args: ["30"])[/proc_\d+/]

    result = @tool.execute(id: id)

    assert_includes result, "terminated"
    refute SharedTools::ProcessRegistry.get(id)
  end

  def test_no_such_process_returns_error
    result = @tool.execute(id: "proc_999")

    assert result.is_a?(Hash)
    assert_includes result[:error], "no such process"
  end

  def test_requires_no_authorization
    SharedTools.auto_execute(false)
    start = SharedTools::Tools::ProcessStartTool.new(allowed_commands: ["sleep"])
    SharedTools.auto_execute(true)
    id = start.execute(command: "sleep", args: ["30"])[/proc_\d+/]

    SharedTools.auto_execute(false)
    result = @tool.execute(id: id)

    assert_includes result, "terminated"
  end
end
