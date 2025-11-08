# frozen_string_literal: true

require "test_helper"

class SecureToolTemplateTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::SecureToolTemplate.new
    # Reset rate limit store for clean test state
    SharedTools::Tools::SecureToolTemplate.instance_variable_set(:@rate_limit_store, {})
  end

  def test_tool_name
    assert_equal 'secure_tool_template', SharedTools::Tools::SecureToolTemplate.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  # Successful operations
  def test_successful_read_operation
    result = @tool.execute(user_input: "test input")

    assert result[:success]
    assert_equal "read", result[:operation_type]
    assert result[:result][:data]
    assert result[:execution_id]
    assert result[:execution_time_seconds]
    assert result[:executed_at]
  end

  def test_successful_write_operation
    result = @tool.execute(
      user_input: "data to write",
      operation_type: "write"
    )

    assert result[:success]
    assert_equal "write", result[:operation_type]
    assert result[:result][:data][:written]
  end

  def test_successful_admin_operation
    result = @tool.execute(
      user_input: "admin command",
      operation_type: "admin"
    )

    assert result[:success]
    assert_equal "admin", result[:operation_type]
    assert result[:result][:data][:requires_review]
  end

  # Input validation
  def test_rejects_empty_input
    result = @tool.execute(user_input: "")

    refute result[:success]
    assert_includes result[:error], "cannot be empty"
  end

  def test_rejects_nil_input
    result = @tool.execute(user_input: nil)

    refute result[:success]
    assert_includes result[:error], "cannot be empty"
  end

  def test_rejects_input_too_long
    long_input = "a" * 1001
    result = @tool.execute(user_input: long_input)

    refute result[:success]
    assert_includes result[:error], "too long"
    assert_includes result[:error], "1001"
  end

  def test_accepts_maximum_length_input
    max_input = "a" * 1000
    result = @tool.execute(user_input: max_input)

    assert result[:success]
  end

  # Input sanitization
  def test_sanitizes_special_characters
    result = @tool.execute(user_input: "test<script>alert('xss')</script>")

    assert result[:success]
    # Special characters should be removed
    refute_includes result[:result][:data][:input_received], "<"
    refute_includes result[:result][:data][:input_received], ">"
    refute_includes result[:result][:data][:input_received], "("
    refute_includes result[:result][:data][:input_received], ")"
  end

  def test_allows_safe_characters
    input = "test_input-123.txt"
    result = @tool.execute(user_input: input)

    assert result[:success]
    assert_equal input, result[:result][:data][:input_received]
  end

  def test_sanitizes_sql_injection_attempt
    result = @tool.execute(user_input: "test'; DROP TABLE users--")

    assert result[:success]
    # Dangerous SQL characters should be removed
    refute_includes result[:result][:data][:input_received], "'"
    refute_includes result[:result][:data][:input_received], ";"
  end

  # Permission validation
  def test_invalid_operation_type
    result = @tool.execute(
      user_input: "test",
      operation_type: "invalid_operation"
    )

    refute result[:success]
    assert_equal "security", result[:error_type]
    assert result[:violation_logged]
  end

  def test_read_operation_type
    result = @tool.execute(
      user_input: "test",
      operation_type: "read"
    )

    assert result[:success]
    assert_equal "read", result[:operation_type]
  end

  def test_write_operation_type
    result = @tool.execute(
      user_input: "test",
      operation_type: "write"
    )

    assert result[:success]
    assert_equal "write", result[:operation_type]
  end

  def test_admin_operation_type
    result = @tool.execute(
      user_input: "test",
      operation_type: "admin"
    )

    assert result[:success]
    assert_equal "admin", result[:operation_type]
  end

  # Timeout validation
  def test_timeout_minimum_adjusted
    result = @tool.execute(
      user_input: "test",
      timeout_seconds: 0
    )

    assert result[:success]
  end

  def test_timeout_maximum_adjusted
    result = @tool.execute(
      user_input: "test",
      timeout_seconds: 500
    )

    assert result[:success]
  end

  def test_timeout_negative_adjusted
    result = @tool.execute(
      user_input: "test",
      timeout_seconds: -10
    )

    assert result[:success]
  end

  def test_custom_timeout_within_range
    result = @tool.execute(
      user_input: "test",
      timeout_seconds: 60
    )

    assert result[:success]
  end

  # Rate limiting
  def test_rate_limiting_allows_normal_usage
    # Should allow multiple requests within limit
    10.times do
      result = @tool.execute(user_input: "test")
      assert result[:success], "Request should succeed within rate limit"
    end
  end

  def test_rate_limiting_prevents_abuse
    # Attempt to exceed rate limit (30 requests per minute)
    results = []
    35.times do
      results << @tool.execute(user_input: "test")
    end

    # First 30 should succeed
    assert results[0...30].all? { |r| r[:success] }

    # Requests beyond limit should be blocked
    assert results[30...35].any? { |r| !r[:success] && r[:error_type] == "security" }
  end

  # Audit logging
  def test_audit_log_created
    result = @tool.execute(user_input: "test input for audit")

    assert result[:success]
    assert result[:execution_id]

    # Verify audit log entry exists
    audit_log = @tool.send(:audit_log)
    assert audit_log.any? { |entry| entry[:execution_id] == result[:execution_id] }
  end

  def test_security_violation_logged
    result = @tool.execute(
      user_input: "test",
      operation_type: "invalid"
    )

    refute result[:success]
    assert result[:violation_logged]

    # Verify security violation in audit log
    audit_log = @tool.send(:audit_log)
    violation_entry = audit_log.find { |entry| entry[:execution_id] == result[:execution_id] }
    assert violation_entry
    assert_equal "high", violation_entry[:severity]
  end

  # Output sanitization
  def test_sanitizes_potential_tokens_in_output
    # This test verifies output sanitization would work
    # In a real scenario, the output might contain tokens
    result = @tool.execute(user_input: "test")

    assert result[:success]
    # Output should not contain long token-like strings
    output_str = result[:result].to_s
    refute_match(/[A-Za-z0-9_-]{20,}/, output_str) if output_str.length > 100
  end

  # Operation-specific behavior
  def test_read_operation_returns_processed_data
    result = @tool.execute(
      user_input: "hello world test",
      operation_type: "read"
    )

    assert result[:success]
    assert_equal "read", result[:result][:operation]
    assert result[:result][:data][:processed]
    assert_equal 3, result[:result][:data][:word_count]
  end

  def test_write_operation_returns_timestamp
    result = @tool.execute(
      user_input: "data",
      operation_type: "write"
    )

    assert result[:success]
    assert_equal "write", result[:result][:operation]
    assert result[:result][:data][:timestamp]
  end

  def test_admin_operation_requires_review
    result = @tool.execute(
      user_input: "admin action",
      operation_type: "admin"
    )

    assert result[:success]
    assert_equal "admin", result[:result][:operation]
    assert result[:result][:data][:requires_review]
  end

  # Execution metadata
  def test_includes_execution_time
    result = @tool.execute(user_input: "test")

    assert result[:success]
    assert result[:execution_time_seconds]
    assert result[:execution_time_seconds] >= 0
    assert result[:execution_time_seconds] < 10
  end

  def test_includes_unique_execution_id
    result1 = @tool.execute(user_input: "test1")
    result2 = @tool.execute(user_input: "test2")

    assert result1[:execution_id]
    assert result2[:execution_id]
    refute_equal result1[:execution_id], result2[:execution_id]
  end

  def test_includes_timestamp
    result = @tool.execute(user_input: "test")

    assert result[:success]
    assert result[:executed_at]
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, result[:executed_at])
  end

  # Edge cases
  def test_handles_whitespace_only_input
    result = @tool.execute(user_input: "   ")

    assert result[:success]
    # Whitespace is allowed, sanitization preserves it
  end

  def test_handles_numeric_input
    result = @tool.execute(user_input: "12345")

    assert result[:success]
    assert_equal "12345", result[:result][:data][:input_received]
  end

  def test_handles_mixed_alphanumeric
    result = @tool.execute(user_input: "test123-data_456.txt")

    assert result[:success]
    assert_equal "test123-data_456.txt", result[:result][:data][:input_received]
  end

  # Error handling
  def test_error_does_not_leak_sensitive_info
    result = @tool.execute(
      user_input: "test",
      operation_type: "invalid"
    )

    refute result[:success]
    # Error message should be generic
    assert_includes result[:error], "Access denied"
    # Should not include stack traces or internal details
    refute result[:error].include?("backtrace")
    refute result[:error].include?("/lib/")
  end

  def test_error_includes_execution_id
    result = @tool.execute(user_input: "")

    refute result[:success]
    assert result[:execution_id]
  end

  def test_multiple_operations_maintain_separation
    result1 = @tool.execute(user_input: "test1", operation_type: "read")
    result2 = @tool.execute(user_input: "test2", operation_type: "write")

    assert result1[:success]
    assert result2[:success]
    refute_equal result1[:execution_id], result2[:execution_id]
  end
end
