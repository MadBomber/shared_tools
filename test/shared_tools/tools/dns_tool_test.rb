# frozen_string_literal: true

require "test_helper"

class DnsToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::DnsTool.new
  end

  def test_tool_name
    assert_equal 'dns', SharedTools::Tools::DnsTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_can_instantiate_without_arguments
    tool = SharedTools::Tools::DnsTool.new
    assert_instance_of SharedTools::Tools::DnsTool, tool
  end

  # Lookup action tests

  def test_lookup_returns_addresses
    result = @tool.execute(action: 'lookup', hostname: 'google.com')

    assert result[:success]
    assert_equal 'google.com', result[:hostname]
    assert_equal 'A', result[:record_type]
    assert result[:addresses].is_a?(Array)
    assert result[:addresses].length > 0
  end

  def test_lookup_a_record
    result = @tool.execute(action: 'lookup', hostname: 'google.com', record_type: 'A')

    assert result[:success]
    assert result[:addresses].all? { |a| a[:type] == 'A' }
    assert result[:addresses].all? { |a| a[:address] =~ /\d+\.\d+\.\d+\.\d+/ }
  end

  def test_lookup_aaaa_record
    result = @tool.execute(action: 'lookup', hostname: 'google.com', record_type: 'AAAA')

    assert result[:success]
    # May or may not have AAAA records
    if result[:addresses].length > 0
      assert result[:addresses].all? { |a| a[:type] == 'AAAA' }
    end
  end

  def test_lookup_any_record
    result = @tool.execute(action: 'lookup', hostname: 'google.com', record_type: 'ANY')

    assert result[:success]
    assert result[:addresses].is_a?(Array)
  end

  def test_lookup_without_hostname_returns_error
    result = @tool.execute(action: 'lookup', hostname: nil)

    refute result[:success]
    assert_includes result[:error], "Hostname is required"
  end

  def test_lookup_invalid_record_type_returns_error
    result = @tool.execute(action: 'lookup', hostname: 'google.com', record_type: 'INVALID')

    refute result[:success]
    assert_includes result[:error], "Unknown record type"
  end

  # Reverse lookup tests

  def test_reverse_lookup_valid_ip
    result = @tool.execute(action: 'reverse', ip: '8.8.8.8')

    assert result[:success]
    assert_equal '8.8.8.8', result[:ip]
    assert result[:hostnames].is_a?(Array)
    # Google's DNS usually has reverse DNS
  end

  def test_reverse_lookup_without_ip_returns_error
    result = @tool.execute(action: 'reverse', ip: nil)

    refute result[:success]
    assert_includes result[:error], "IP address is required"
  end

  def test_reverse_lookup_invalid_ip_returns_error
    result = @tool.execute(action: 'reverse', ip: 'not.an.ip')

    refute result[:success]
    assert_includes result[:error], "Invalid IP address"
  end

  # MX lookup tests

  def test_mx_lookup_returns_records
    result = @tool.execute(action: 'mx', hostname: 'gmail.com')

    assert result[:success]
    assert_equal 'gmail.com', result[:hostname]
    assert result[:mx_records].is_a?(Array)
    assert result[:mx_records].length > 0

    # Check structure of MX record
    mx = result[:mx_records].first
    assert mx[:priority]
    assert mx[:exchange]
  end

  def test_mx_records_sorted_by_priority
    result = @tool.execute(action: 'mx', hostname: 'gmail.com')

    assert result[:success]
    priorities = result[:mx_records].map { |r| r[:priority] }
    assert_equal priorities, priorities.sort
  end

  def test_mx_lookup_without_hostname_returns_error
    result = @tool.execute(action: 'mx', hostname: nil)

    refute result[:success]
    assert_includes result[:error], "Hostname is required"
  end

  # TXT lookup tests

  def test_txt_lookup_returns_records
    result = @tool.execute(action: 'txt', hostname: 'google.com')

    assert result[:success]
    assert_equal 'google.com', result[:hostname]
    assert result[:txt_records].is_a?(Array)
    assert result[:count] >= 0
  end

  def test_txt_lookup_without_hostname_returns_error
    result = @tool.execute(action: 'txt', hostname: nil)

    refute result[:success]
    assert_includes result[:error], "Hostname is required"
  end

  # NS lookup tests

  def test_ns_lookup_returns_nameservers
    result = @tool.execute(action: 'ns', hostname: 'google.com')

    assert result[:success]
    assert_equal 'google.com', result[:hostname]
    assert result[:nameservers].is_a?(Array)
    assert result[:nameservers].length > 0
  end

  def test_ns_lookup_without_hostname_returns_error
    result = @tool.execute(action: 'ns', hostname: nil)

    refute result[:success]
    assert_includes result[:error], "Hostname is required"
  end

  # All records tests

  def test_all_returns_multiple_record_types
    result = @tool.execute(action: 'all', hostname: 'google.com')

    assert result[:success]
    assert_equal 'google.com', result[:hostname]
    assert result[:records].is_a?(Hash)

    # Google should have at least A records
    assert result[:records][:A]
  end

  def test_all_without_hostname_returns_error
    result = @tool.execute(action: 'all', hostname: nil)

    refute result[:success]
    assert_includes result[:error], "Hostname is required"
  end

  # Unknown action test

  def test_unknown_action_returns_error
    result = @tool.execute(action: 'unknown')

    refute result[:success]
    assert_includes result[:error], "Unknown action"
    assert_includes result[:error], "Valid actions"
  end

  # Case insensitivity tests

  def test_action_is_case_insensitive
    result_lower = @tool.execute(action: 'lookup', hostname: 'google.com')
    result_upper = @tool.execute(action: 'LOOKUP', hostname: 'google.com')
    result_mixed = @tool.execute(action: 'Lookup', hostname: 'google.com')

    assert result_lower[:success]
    assert result_upper[:success]
    assert result_mixed[:success]
  end

  def test_record_type_is_case_insensitive
    result_lower = @tool.execute(action: 'lookup', hostname: 'google.com', record_type: 'a')
    result_upper = @tool.execute(action: 'lookup', hostname: 'google.com', record_type: 'A')

    assert result_lower[:success]
    assert result_upper[:success]
  end

  # IP validation tests

  def test_valid_ipv4_format
    result = @tool.execute(action: 'reverse', ip: '192.168.1.1')

    assert result[:success]
  end

  def test_invalid_ipv4_out_of_range
    result = @tool.execute(action: 'reverse', ip: '256.0.0.1')

    refute result[:success]
    assert_includes result[:error], "Invalid IP address"
  end
end
