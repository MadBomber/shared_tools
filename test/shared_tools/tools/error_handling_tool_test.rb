# frozen_string_literal: true

require "test_helper"

class ErrorHandlingToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::ErrorHandlingTool.new
  end

  def test_tool_name
    assert_equal 'error_handling_tool', SharedTools::Tools::ErrorHandlingTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  # Successful operations
  def test_validate_operation_success
    result = @tool.execute(
      operation: "validate",
      name: "test", value: 42
    )

    assert result[:success]
    assert result[:result][:validated]
    assert_equal "test", result[:result][:data][:name]
    assert_equal 42, result[:result][:data][:value]
    assert result[:metadata]
  end

  def test_process_operation_success
    result = @tool.execute(
      operation: "process",
      name: "test", value: 10
    )

    assert result[:success]
    assert result[:result][:processed]
    assert_equal 10, result[:result][:original_value]
    assert_equal 15.0, result[:result][:processed_value]
    assert result[:result][:processed_at]
  end

  def test_authorize_operation_success
    result = @tool.execute(
      operation: "authorize",
      data: {}
    )

    assert result[:success]
    assert result[:result][:authorized]
    assert_equal "authorize", result[:result][:operation]
  end

  # Validation errors
  def test_invalid_operation
    result = @tool.execute(
      operation: "invalid",
      data: {}
    )

    refute result[:success]
    assert_equal "validation", result[:error_type]
    assert_includes result[:error], "Invalid operation"
    assert result[:suggestions]
    assert result[:suggestions].any?
  end

  def test_validate_missing_required_fields
    result = @tool.execute(
      operation: "validate",
      data: {}
    )

    refute result[:success]
    assert_equal "validation", result[:error_type]
    assert_includes result[:error], "name is required"
    assert_includes result[:error], "value is required"
  end

  def test_validate_invalid_value_type
    result = @tool.execute(
      operation: "validate",
      name: "test", value: "not_a_number"
    )

    refute result[:success]
    assert_equal "validation", result[:error_type]
    assert_includes result[:error], "value must be a number"
  end

  def test_process_requires_data
    result = @tool.execute(
      operation: "process"
    )

    refute result[:success]
    assert_equal "validation", result[:error_type]
    assert_includes result[:error], "Data is required"
  end

  def test_max_retries_validation
    result = @tool.execute(
      operation: "validate",
      name: "test", value: 1,
      max_retries: 15
    )

    refute result[:success]
    assert_equal "validation", result[:error_type]
    assert_includes result[:error], "must be between 0 and 10"
  end

  def test_negative_max_retries
    result = @tool.execute(
      operation: "validate",
      name: "test", value: 1,
      max_retries: -1
    )

    refute result[:success]
    assert_equal "validation", result[:error_type]
  end

  # Simulated errors
  def test_simulated_validation_error
    result = @tool.execute(
      operation: "validate",
      name: "test", value: 1,
      simulate_error: "validation"
    )

    refute result[:success]
    assert_equal "validation", result[:error_type]
    assert_includes result[:error], "Simulated validation error"
    assert result[:suggestions]
  end

  def test_simulated_network_error
    result = @tool.execute(
      operation: "process",
      name: "test", value: 1,
      simulate_error: "network"
    )

    refute result[:success]
    assert_equal "network", result[:error_type]
    assert result[:retry_suggested]
    assert_equal 30, result[:retry_after]
  end

  def test_simulated_authorization_error
    result = @tool.execute(
      operation: "authorize",
      data: {},
      simulate_error: "authorization"
    )

    refute result[:success]
    assert_equal "authorization", result[:error_type]
    assert_includes result[:error], "Access denied"
    assert result[:documentation_url]
  end

  def test_simulated_resource_not_found_error
    result = @tool.execute(
      operation: "validate",
      name: "test", value: 1,
      simulate_error: "resource_not_found"
    )

    refute result[:success]
    assert_equal "resource_not_found", result[:error_type]
    assert_includes result[:error], "Resource not found"
  end

  # Retry logic
  def test_retryable_error_with_success_after_retries
    result = @tool.execute(
      operation: "process",
      name: "test", value: 1,
      simulate_error: "retryable",
      max_retries: 3
    )

    # Should succeed after retries (simulation succeeds on 3rd attempt)
    assert result[:success]
    assert result[:result][:processed]
  end

  def test_retryable_error_max_retries_exceeded
    result = @tool.execute(
      operation: "process",
      name: "test", value: 1,
      simulate_error: "retryable",
      max_retries: 1
    )

    # Should fail because max_retries=1 but need 2 retries to succeed
    refute result[:success]
    assert_equal "network", result[:error_type]
    assert_includes result[:error], "failed after 1 retries"
  end

  def test_zero_retries_disabled
    result = @tool.execute(
      operation: "process",
      name: "test", value: 1,
      simulate_error: "retryable",
      max_retries: 0
    )

    refute result[:success]
    assert_equal "network", result[:error_type]
  end

  # Metadata
  def test_metadata_included_in_success
    result = @tool.execute(
      operation: "validate",
      name: "test", value: 1
    )

    assert result[:success]
    assert result[:metadata]
    assert result[:metadata][:execution_time_seconds]
    assert result[:metadata][:resources_allocated]
    assert result[:metadata][:timestamp]
    assert result[:metadata][:tool_version]
  end

  def test_execution_time_tracked
    result = @tool.execute(
      operation: "process",
      name: "test", value: 1
    )

    assert result[:success]
    assert result[:metadata][:execution_time_seconds] > 0
  end

  def test_resources_allocated_tracked
    result = @tool.execute(
      operation: "validate",
      name: "test", value: 1
    )

    assert result[:success]
    assert result[:metadata][:resources_allocated] > 0
  end

  # Support references
  def test_support_reference_in_validation_error
    result = @tool.execute(
      operation: "invalid",
      data: {}
    )

    refute result[:success]
    assert result[:support_reference]
    assert result[:support_reference].length == 36  # UUID length
  end

  def test_support_reference_in_network_error
    result = @tool.execute(
      operation: "process",
      name: "test", value: 1,
      simulate_error: "network"
    )

    refute result[:success]
    assert result[:support_reference]
  end

  def test_support_reference_in_authorization_error
    result = @tool.execute(
      operation: "authorize",
      data: {},
      simulate_error: "authorization"
    )

    refute result[:success]
    assert result[:support_reference]
  end

  # Data validation warnings
  def test_validate_with_warnings
    result = @tool.execute(
      operation: "validate",
      name: "x", value: -5
    )

    assert result[:success]
    assert result[:result][:warnings]
    assert_includes result[:result][:warnings], "name is very short"
    assert_includes result[:result][:warnings], "value is negative"
  end

  def test_validate_minimal_valid_data
    result = @tool.execute(
      operation: "validate",
      name: "ab", value: 0
    )

    assert result[:success]
    assert result[:result][:validated]
  end

  # Edge cases
  def test_empty_simulate_error_works_normally
    result = @tool.execute(
      operation: "validate",
      name: "test", value: 1,
      simulate_error: ""
    )

    assert result[:success]
  end

  def test_nil_simulate_error_works_normally
    result = @tool.execute(
      operation: "validate",
      name: "test", value: 1,
      simulate_error: nil
    )

    assert result[:success]
  end

  def test_process_with_decimal_value
    result = @tool.execute(
      operation: "process",
      name: "test", value: 10.5
    )

    assert result[:success]
    assert_equal 10.5, result[:result][:original_value]
    assert_equal 15.75, result[:result][:processed_value]
  end

  def test_operation_included_in_error_response
    result = @tool.execute(
      operation: "invalid",
      data: {}
    )

    refute result[:success]
    assert_equal "invalid", result[:operation]
  end

  # Custom error classes
  def test_validation_error_class_exists
    assert defined?(SharedTools::Tools::ValidationError)
    assert SharedTools::Tools::ValidationError < StandardError
  end

  def test_network_error_class_exists
    assert defined?(SharedTools::Tools::NetworkError)
    assert SharedTools::Tools::NetworkError < StandardError
  end

  def test_authorization_error_class_exists
    assert defined?(SharedTools::Tools::AuthorizationError)
    assert SharedTools::Tools::AuthorizationError < StandardError
  end

  def test_retryable_error_class_exists
    assert defined?(SharedTools::Tools::RetryableError)
    assert SharedTools::Tools::RetryableError < StandardError
  end

  def test_resource_not_found_error_class_exists
    assert defined?(SharedTools::Tools::ResourceNotFoundError)
    assert SharedTools::Tools::ResourceNotFoundError < StandardError
  end

  def test_validation_error_has_suggestions
    error = SharedTools::Tools::ValidationError.new("Test", suggestions: ["Fix this"])
    assert_equal ["Fix this"], error.suggestions
  end
end
