# frozen_string_literal: true

require "test_helper"
require "shared_tools/ruby_llm/run_shell_command"

class RunShellCommandTest < Minitest::Test
  def setup
    @tool = SharedTools::RunShellCommand.new
  end

  def test_tool_is_instantiable
    refute_nil @tool
  end
end
