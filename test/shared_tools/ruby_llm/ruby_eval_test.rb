# frozen_string_literal: true

require "test_helper"
require "shared_tools/ruby_llm/ruby_eval"

class RubyEvalTest < Minitest::Test
  def setup
    @tool = SharedTools::RubyEval.new
  end

  def test_tool_is_instantiable
    refute_nil @tool
  end
end
