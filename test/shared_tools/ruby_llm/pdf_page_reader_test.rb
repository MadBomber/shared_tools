# frozen_string_literal: true

require "test_helper"
require "shared_tools/ruby_llm/pdf_page_reader"

class PdfPageReaderTest < Minitest::Test
  def setup
    @tool = SharedTools::PdfPageReader.new
  end

  def test_tool_is_instantiable
    refute_nil @tool
  end
end
