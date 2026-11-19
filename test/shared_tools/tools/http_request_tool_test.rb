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
    assert_equal "http_request", SharedTools::Tools::HttpRequestTool.tool_name
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

  # A host whose first vetted address is unreachable (an IPv6 address on a
  # machine with no IPv6 route) is reached through the next one.
  def test_tries_the_next_vetted_address_when_one_is_unreachable
    pins = []
    with_vetted_addresses("2001:db8::1", "2001:db8::2", "93.184.215.14") do |perform|
      perform.call do |pin|
        pins << pin
        raise Errno::EHOSTUNREACH, "connect(2) for #{pin}" if pin.include?(":")
        [Net::HTTPOK.new("1.1", "200", "OK"), "hello"]
      end
      response = @tool.guarded_request("GET", "https://example.com/")

      assert_equal 200, response.status
      assert_equal "hello", response.body
    end
    assert_equal ["2001:db8::1", "2001:db8::2", "93.184.215.14"], pins
  end

  def test_reports_the_last_error_when_no_vetted_address_is_reachable
    with_vetted_addresses("2001:db8::1", "93.184.215.14") do |perform|
      perform.call { |pin| raise Errno::ECONNREFUSED, pin }
      error = assert_raises(SharedTools::Tools::HttpHelpers::FetchError) { @tool.guarded_request("GET", "https://example.com/") }

      assert_includes error.message, "93.184.215.14"
    end
  end

  def test_does_not_resend_a_request_after_the_connection_was_made
    pins = []
    with_vetted_addresses("93.184.215.14", "93.184.215.15") do |perform|
      perform.call { |pin| pins << pin; raise Net::ReadTimeout }
      assert_raises(SharedTools::Tools::HttpHelpers::FetchError) { @tool.guarded_request("POST", "https://example.com/") }
    end
    assert_equal ["93.184.215.14"], pins
  end

  private

  # Stubs the guard to vet +addresses+ for every URL and yields a setter for
  # the per-pin behaviour of the private #perform.
  def with_vetted_addresses(*addresses)
    guard = Object.new
    guard.define_singleton_method(:resolve!) do |url|
      SharedTools::UrlGuard::Resolution.new(uri: URI(url), address: addresses.first, addresses: addresses)
    end
    behaviour = nil
    perform   = ->(_uri, _method, _headers, _body, pin) { behaviour.call(pin) }

    @tool.stub(:url_guard, guard) do
      @tool.stub(:perform, perform) do
        yield ->(&block) { behaviour = block }
      end
    end
  end
end
