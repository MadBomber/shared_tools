# frozen_string_literal: true

require "test_helper"
require "shared_tools/ruby_llm/python_eval"

class PythonEvalTest < Minitest::Test
  def setup
    @tool = SharedTools::PythonEval.new
  end

  def test_tool_is_instantiable
    refute_nil @tool
  end
end
