# frozen_string_literal: true

require "test_helper"
require "shared_tools/ruby_llm/edit_file"

class EditFileTest < Minitest::Test
  def setup
    @tool = SharedTools::EditFile.new
  end

  def test_tool_is_instantiable
    refute_nil @tool
  end
end
