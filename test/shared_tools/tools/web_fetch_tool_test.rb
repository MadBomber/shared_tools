# frozen_string_literal: true

require "test_helper"

class WebFetchToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::WebFetchTool.new
  end

  def test_tool_name
    assert_equal "web_fetch", SharedTools::Tools::WebFetchTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_fetches_a_public_page
    result = @tool.execute(url: "https://example.com")

    assert_kind_of String, result
    assert_includes result, "Example Domain"
  end

  def test_strips_html_to_text
    result = @tool.execute(url: "https://example.com")

    refute_includes result, "<html"
    refute_includes result, "<body"
  end

  def test_blocks_loopback_address
    result = @tool.execute(url: "http://127.0.0.1:1/")

    assert result.is_a?(Hash)
    assert result.key?(:error)
  end

  def test_blocks_cloud_metadata_address
    result = @tool.execute(url: "http://169.254.169.254/latest/meta-data/")

    assert result.is_a?(Hash)
    assert result.key?(:error)
  end

  def test_invalid_url_returns_error
    result = @tool.execute(url: "not a url")

    assert result.is_a?(Hash)
    assert result.key?(:error)
  end
end
