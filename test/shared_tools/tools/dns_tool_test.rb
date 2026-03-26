# frozen_string_literal: true

require "test_helper"

class DnsToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::DnsTool.new
  end

  def test_tool_name
    assert_equal 'dns_tool', SharedTools::Tools::DnsTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  # A record lookup — use localhost which always resolves
  def test_a_record_lookup_localhost
    result = @tool.execute(action: 'a', host: 'localhost')
    assert result[:success]
    assert result[:records]
    assert_kind_of Array, result[:records]
    # localhost always resolves to 127.0.0.1
    assert result[:records].include?('127.0.0.1')
  end

  def test_a_record_returns_host_and_type
    result = @tool.execute(action: 'a', host: 'localhost')
    assert result[:success]
    assert_equal 'localhost', result[:host]
    assert_equal 'A', result[:type]
  end

  # Reverse lookup — 127.0.0.1 may not have a PTR record in all environments
  def test_reverse_lookup_loopback
    result = @tool.execute(action: 'reverse', host: '127.0.0.1')
    # Result is always a Hash with a :success key, whether PTR exists or not
    assert result.key?(:success)
    assert_equal 'PTR', result[:type]
    if result[:success]
      assert result[:hostname]
    else
      assert result[:error]
    end
  end

  # external_ip action
  def test_external_ip_returns_success_or_graceful_error
    result = @tool.execute(action: 'external_ip')
    # May fail if no internet — just check it returns a well-formed response
    assert result.key?(:success)
    if result[:success]
      assert result[:ip]
      assert_match(/\A\d+\.\d+\.\d+\.\d+\z/, result[:ip])
    else
      assert result[:error]
    end
  end

  # ip_location action
  def test_ip_location_returns_success_or_graceful_error
    result = @tool.execute(action: 'ip_location', host: '8.8.8.8')
    assert result.key?(:success)
    if result[:success]
      assert result[:ip]
      assert result[:country]
    else
      assert result[:error]
    end
  end

  # Missing host returns error for host-required actions
  def test_a_record_missing_host_returns_error
    result = @tool.execute(action: 'a', host: nil)
    refute result[:success]
    assert result[:error]
  end

  def test_mx_missing_host_returns_error
    result = @tool.execute(action: 'mx', host: nil)
    refute result[:success]
    assert result[:error]
  end

  # Unknown action
  def test_unknown_action_returns_error
    result = @tool.execute(action: 'bogus', host: 'localhost')
    refute result[:success]
    assert result[:error]
  end

  # Response shape
  def test_result_always_has_success_key
    result = @tool.execute(action: 'a', host: 'localhost')
    assert result.key?(:success)
  end
end
