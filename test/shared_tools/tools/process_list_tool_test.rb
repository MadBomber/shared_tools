# frozen_string_literal: true

require "test_helper"

class ProcessListToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::ProcessListTool.new
    SharedTools.auto_execute(true)
  end

  def teardown
    SharedTools::ProcessRegistry.reset!
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "process_list", SharedTools::Tools::ProcessListTool.name
  end

  def test_reports_no_processes_when_empty
    assert_equal "no background processes", @tool.execute
  end

  def test_lists_running_processes
    start = SharedTools::Tools::ProcessStartTool.new(allowed_commands: ["sleep"])
    start.execute(command: "sleep", args: ["1"], name: "napper")

    result = @tool.execute

    assert_includes result, "1 process"
    assert_includes result, "napper"
    assert_includes result, "running"
  end
end
