# frozen_string_literal: true

require "test_helper"

class HttpRequestToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::HttpRequestTool.new
    SharedTools.auto_execute(true)
  end

  def teardown
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "http_request", SharedTools::Tools::HttpRequestTool.name
  end

  def test_get_request
    result = @tool.execute(url: "https://example.com")

    assert_includes result, "-> 200"
    assert_includes result, "content-type"
  end

  def test_defaults_to_get
    result = @tool.execute(url: "https://example.com", method: "")

    assert_includes result, "GET https://example.com"
  end

  def test_unsupported_method_returns_error
    result = @tool.execute(url: "https://example.com", method: "TRACE")

    assert result.is_a?(Hash)
    assert_includes result[:error], "unsupported method"
  end

  def test_mutating_method_requires_authorization
    SharedTools.auto_execute(false)

    with_stdin_input("n") do
      result = @tool.execute(url: "https://example.com", method: "POST")
      assert result.is_a?(Hash)
      assert_includes result[:error], "declined"
    end
  end

  def test_get_does_not_require_authorization
    SharedTools.auto_execute(false)

    result = @tool.execute(url: "https://example.com")

    refute result.is_a?(Hash) && result.key?(:error) && result[:error].include?("declined")
  end

  def test_blocks_ssrf_target
    result = @tool.execute(url: "http://127.0.0.1:1/")

    assert result.is_a?(Hash)
    assert result.key?(:error)
  end
end
