# frozen_string_literal: true

require "test_helper"

class DocToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::DocTool.new
    @test_pdf = File.expand_path("../../fixtures/test.pdf", __dir__)
  end

  def test_tool_name
    assert_equal 'doc_tool', SharedTools::Tools::DocTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_has_all_action_constants
    assert_equal "pdf_read", SharedTools::Tools::DocTool::Action::PDF_READ
  end

  def test_pdf_read_action
    skip "pdf-reader gem not installed" unless defined?(PDF::Reader)
    skip "Test PDF file not available" unless File.exist?(@test_pdf)

    result = @tool.execute(
      action: SharedTools::Tools::DocTool::Action::PDF_READ,
      doc_path: @test_pdf,
      page_numbers: "1"
    )

    assert_kind_of Hash, result
    assert result.key?(:pages)
    assert_equal 1, result[:pages].size
  end

  def test_pdf_read_with_multiple_pages
    skip "pdf-reader gem not installed" unless defined?(PDF::Reader)
    skip "Test PDF file not available" unless File.exist?(@test_pdf)

    result = @tool.execute(
      action: SharedTools::Tools::DocTool::Action::PDF_READ,
      doc_path: @test_pdf,
      page_numbers: "1, 2"
    )

    assert_kind_of Hash, result
    assert result.key?(:pages)
  end

  def test_unsupported_action
    result = @tool.execute(
      action: "invalid_action",
      doc_path: @test_pdf,
      page_numbers: "1"
    )

    assert result.key?(:error)
    assert_includes result[:error], "Unsupported action"
  end

  def test_requires_doc_path_for_pdf_read
    result = @tool.execute(
      action: SharedTools::Tools::DocTool::Action::PDF_READ,
      page_numbers: "1"
    )

    assert result.key?(:error)
    assert_includes result[:error], "doc_path"
  end

  def test_requires_page_numbers_for_pdf_read
    result = @tool.execute(
      action: SharedTools::Tools::DocTool::Action::PDF_READ,
      doc_path: @test_pdf
    )

    assert result.key?(:error)
    assert_includes result[:error], "page_numbers"
  end
end
