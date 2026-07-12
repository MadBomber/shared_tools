# frozen_string_literal: true

require "test_helper"

class ProcessOutputToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::ProcessOutputTool.new
    SharedTools.auto_execute(true)
  end

  def teardown
    SharedTools::ProcessRegistry.reset!
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "process_output", SharedTools::Tools::ProcessOutputTool.name
  end

  def test_reads_stdout_from_a_running_process
    start = SharedTools::Tools::ProcessStartTool.new(allowed_commands: ["echo"])
    id = start.execute(command: "echo", args: ["hello output"])[/proc_\d+/]

    sleep 0.3
    result = @tool.execute(id: id)

    assert_includes result, "hello output"
  end

  def test_no_such_process_returns_error
    result = @tool.execute(id: "proc_999")

    assert result.is_a?(Hash)
    assert_includes result[:error], "no such process"
  end
end
