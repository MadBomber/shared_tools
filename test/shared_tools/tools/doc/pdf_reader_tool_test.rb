# frozen_string_literal: true

require "test_helper"

class PdfReaderToolTest < Minitest::Test
  def setup
    skip "pdf-reader gem not installed" unless defined?(PDF::Reader)

    @tool = SharedTools::Tools::Doc::PdfReaderTool.new
    @test_pdf = File.expand_path("../../../fixtures/test.pdf", __dir__)
    @nonexistent_pdf = File.expand_path("../../../fixtures/nonexistent.pdf", __dir__)
  end

  def test_tool_name
    assert_equal 'doc_pdf_read', SharedTools::Tools::Doc::PdfReaderTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_reads_single_page_successfully
    skip "Test PDF file not available" unless File.exist?(@test_pdf)

    result = @tool.execute(doc_path: @test_pdf, page_numbers: "1")

    assert_kind_of Hash, result
    assert result.key?(:total_pages)
    assert result.key?(:requested_pages)
    assert result.key?(:invalid_pages)
    assert result.key?(:pages)
    assert_equal [1], result[:requested_pages]
    assert_equal [], result[:invalid_pages]
    assert_equal 1, result[:pages].size
    assert_equal 1, result[:pages].first[:page]
    assert result[:pages].first.key?(:text)
  end

  def test_reads_multiple_pages
    skip "Test PDF file not available" unless File.exist?(@test_pdf)

    result = @tool.execute(doc_path: @test_pdf, page_numbers: "1, 2")

    assert_kind_of Hash, result
    assert_equal [1, 2], result[:requested_pages]
    assert_equal 2, result[:pages].size
  end

  def test_handles_page_ranges
    skip "Test PDF file not available" unless File.exist?(@test_pdf)

    # Note: The current implementation doesn't support ranges,
    # but this test documents the expected format
    result = @tool.execute(doc_path: @test_pdf, page_numbers: "1, 2, 3")

    assert_kind_of Hash, result
    assert_equal [1, 2, 3], result[:requested_pages]
  end

  def test_handles_invalid_page_numbers
    skip "Test PDF file not available" unless File.exist?(@test_pdf)

    result = @tool.execute(doc_path: @test_pdf, page_numbers: "999")

    assert_kind_of Hash, result
    assert_equal [999], result[:requested_pages]
    assert_equal [999], result[:invalid_pages]
    assert_equal 0, result[:pages].size
  end

  def test_filters_out_invalid_pages
    skip "Test PDF file not available" unless File.exist?(@test_pdf)

    result = @tool.execute(doc_path: @test_pdf, page_numbers: "1, 999")

    assert_kind_of Hash, result
    assert_equal [1, 999], result[:requested_pages]
    assert_equal [999], result[:invalid_pages]
    assert_equal 1, result[:pages].size
    assert_equal 1, result[:pages].first[:page]
  end

  def test_handles_nonexistent_file
    result = @tool.execute(doc_path: @nonexistent_pdf, page_numbers: "1")

    assert_kind_of Hash, result
    assert result.key?(:error)
    # PDF-Reader gives different error messages for nonexistent files
    assert result[:error].is_a?(String)
  end

  def test_handles_invalid_pdf
    # Create a temporary non-PDF file
    invalid_file = File.join(Dir.tmpdir, "invalid.pdf")
    File.write(invalid_file, "This is not a PDF")

    result = @tool.execute(doc_path: invalid_file, page_numbers: "1")

    assert_kind_of Hash, result
    assert result.key?(:error)

    File.delete(invalid_file) if File.exist?(invalid_file)
  end

  def test_page_numbers_with_whitespace
    skip "Test PDF file not available" unless File.exist?(@test_pdf)

    result = @tool.execute(doc_path: @test_pdf, page_numbers: " 1 ,  2  ")

    assert_kind_of Hash, result
    assert_equal [1, 2], result[:requested_pages]
  end

  def test_returns_text_content
    skip "Test PDF file not available" unless File.exist?(@test_pdf)

    result = @tool.execute(doc_path: @test_pdf, page_numbers: "1")

    assert_kind_of Hash, result
    assert result[:pages].first[:text].is_a?(String)
  end
end
