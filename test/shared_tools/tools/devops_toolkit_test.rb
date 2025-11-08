# frozen_string_literal: true

require "test_helper"

class DevopsToolkitTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::DevopsToolkit.new
  end

  def test_tool_name
    assert_equal 'devops_toolkit', SharedTools::Tools::DevopsToolkit.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  # Deploy operation tests
  def test_deploy_to_development
    result = @tool.execute(
      operation: "deploy",
      environment: "development",
      version: "1.0.0"
    )

    assert result[:success]
    assert_equal "deploy", result[:operation]
    assert_equal "development", result[:environment]
    assert result[:deployment_id]
    assert result[:deployed_at]
    assert result[:deployment_steps]
    assert result[:rollback_available]
  end

  def test_deploy_to_staging
    result = @tool.execute(
      operation: "deploy",
      environment: "staging",
      version: "2.0.0", branch: "main"
    )

    assert result[:success]
    assert_equal "staging", result[:environment]
    assert_equal "2.0.0", result[:version]
    assert_equal "main", result[:branch]
  end

  def test_deploy_to_production_requires_confirmation
    result = @tool.execute(
      operation: "deploy",
      environment: "production",
      version: "1.0.0"
    )

    refute result[:success]
    assert_includes result[:error], "explicit confirmation"
    assert_equal "production_confirmed: true", result[:required_option]
  end

  def test_deploy_to_production_with_confirmation
    result = @tool.execute(
      operation: "deploy",
      environment: "production",
      version: "1.0.0", production_confirmed: true
    )

    assert result[:success]
    assert_equal "production", result[:environment]
  end

  def test_deploy_includes_deployment_steps
    result = @tool.execute(
      operation: "deploy",
      environment: "development"
    )

    assert result[:deployment_steps]
    assert result[:deployment_steps].is_a?(Array)
    assert result[:deployment_steps].length > 0

    step = result[:deployment_steps].first
    assert step[:step]
    assert step[:status]
    assert step[:duration]
  end

  def test_deploy_default_version_is_latest
    result = @tool.execute(
      operation: "deploy",
      environment: "development"
    )

    assert result[:success]
    assert_equal "latest", result[:version]
  end

  # Rollback operation tests
  def test_rollback_to_development
    result = @tool.execute(
      operation: "rollback",
      environment: "development",
      target_version: "1.0.0"
    )

    assert result[:success]
    assert_equal "rollback", result[:operation]
    assert_equal "development", result[:environment]
    assert result[:rollback_id]
    assert result[:rolled_back_at]
    assert result[:rollback_steps]
  end

  def test_rollback_to_staging
    result = @tool.execute(
      operation: "rollback",
      environment: "staging"
    )

    assert result[:success]
    assert_equal "staging", result[:environment]
    assert_equal "previous", result[:target_version]
  end

  def test_rollback_to_production_requires_confirmation
    result = @tool.execute(
      operation: "rollback",
      environment: "production",
      production_confirmed: true
    )

    refute result[:success]
    assert_includes result[:error], "rollback requires"
    assert_equal "rollback_confirmed: true", result[:required_option]
  end

  def test_rollback_to_production_with_both_confirmations
    result = @tool.execute(
      operation: "rollback",
      environment: "production",
      production_confirmed: true, rollback_confirmed: true
    )

    assert result[:success]
    assert_equal "production", result[:environment]
  end

  # Health check operation tests
  def test_health_check_development
    result = @tool.execute(
      operation: "health_check",
      environment: "development"
    )

    assert result[:success]
    assert_equal "health_check", result[:operation]
    assert result[:overall_status]
    assert result[:services_checked]
    assert result[:healthy_services]
    assert result[:health_results]
    assert result[:checked_at]
  end

  def test_health_check_with_custom_services
    result = @tool.execute(
      operation: "health_check",
      environment: "staging",
      services_to_check: ["web", "database"]
    )

    assert result[:success]
    assert_equal 2, result[:services_checked]
    assert_equal 2, result[:health_results].length
  end

  def test_health_check_default_services
    result = @tool.execute(
      operation: "health_check",
      environment: "development"
    )

    assert result[:success]
    assert_equal 4, result[:services_checked]  # web, api, database, cache
  end

  def test_health_check_includes_service_details
    result = @tool.execute(
      operation: "health_check",
      environment: "development"
    )

    assert result[:success]
    service = result[:health_results].first

    assert service[:service]
    assert service[:status]
    assert service[:response_time_ms]
    assert service[:last_check]
  end

  # Log analysis operation tests
  def test_log_analysis_development
    result = @tool.execute(
      operation: "log_analysis",
      environment: "development"
    )

    assert result[:success]
    assert_equal "log_analysis", result[:operation]
    assert result[:entries_analyzed]
    assert result[:errors_found]
    assert result[:warnings_found]
    assert result[:findings]
    assert result[:analyzed_at]
    assert result[:recommendations]
  end

  def test_log_analysis_with_custom_options
    result = @tool.execute(
      operation: "log_analysis",
      environment: "staging",
      time_range: "last_24_hours",
        log_level: "warning",
        search_patterns: ["error", "exception"]
    )

    assert result[:success]
    assert_equal "last_24_hours", result[:time_range]
    assert_equal "warning", result[:log_level]
  end

  def test_log_analysis_includes_recommendations
    result = @tool.execute(
      operation: "log_analysis",
      environment: "development"
    )

    assert result[:success]
    assert result[:recommendations]
    assert result[:recommendations].is_a?(Array)
    assert result[:recommendations].length > 0
  end

  # Metric collection operation tests
  def test_metric_collection_development
    result = @tool.execute(
      operation: "metric_collection",
      environment: "development"
    )

    assert result[:success]
    assert_equal "metric_collection", result[:operation]
    assert result[:metrics_collected]
    assert result[:metrics]
    assert result[:collected_at]
  end

  def test_metric_collection_with_custom_metrics
    result = @tool.execute(
      operation: "metric_collection",
      environment: "staging",
      metric_types: ["cpu", "memory"]
    )

    assert result[:success]
    assert_equal 2, result[:metrics_collected]
    assert_equal 2, result[:metrics].length
  end

  def test_metric_collection_default_metrics
    result = @tool.execute(
      operation: "metric_collection",
      environment: "development"
    )

    assert result[:success]
    assert_equal 4, result[:metrics_collected]  # cpu, memory, disk, network
  end

  def test_metric_collection_includes_metric_details
    result = @tool.execute(
      operation: "metric_collection",
      environment: "development"
    )

    assert result[:success]
    cpu_metric = result[:metrics].find { |m| m[:type] == "cpu" }

    assert cpu_metric
    assert cpu_metric[:current_usage_percent]
    assert cpu_metric[:average_usage_percent]
    assert cpu_metric[:unit]
  end

  # Environment validation tests
  def test_invalid_environment
    result = @tool.execute(
      operation: "deploy",
      environment: "invalid_env"
    )

    refute result[:success]
    assert_includes result[:error], "Invalid environment"
    assert result[:valid_environments]
  end

  def test_valid_environments
    ["development", "staging", "production"].each do |env|
      params = {
        operation: "health_check",
        environment: env
      }
      params[:production_confirmed] = true if env == "production"

      result = @tool.execute(**params)

      assert result[:success], "#{env} should be valid"
    end
  end

  # Operation validation tests
  def test_invalid_operation
    result = @tool.execute(
      operation: "invalid_operation",
      environment: "development"
    )

    refute result[:success]
    assert_includes result[:error], "Unknown operation"
    assert result[:valid_operations]
  end

  def test_all_valid_operations
    operations = ["deploy", "rollback", "health_check", "log_analysis", "metric_collection"]

    operations.each do |op|
      result = @tool.execute(
        operation: op,
        environment: "development"
      )

      assert result[:success], "#{op} should be a valid operation"
    end
  end

  # Operation logging tests
  def test_operation_is_logged
    result = @tool.execute(
      operation: "health_check",
      environment: "development"
    )

    assert result[:success]
    assert result[:operation_id]

    # Verify operation appears in log
    operation_log = @tool.send(:operation_log)
    log_entry = operation_log.find { |entry| entry[:operation_id] == result[:operation_id] }

    assert log_entry
    assert_equal "health_check", log_entry[:operation]
    assert_equal "development", log_entry[:environment]
  end

  def test_each_operation_has_unique_id
    result1 = @tool.execute(operation: "health_check", environment: "development")
    result2 = @tool.execute(operation: "health_check", environment: "development")

    assert result1[:operation_id]
    assert result2[:operation_id]
    refute_equal result1[:operation_id], result2[:operation_id]
  end

  # Default values tests
  def test_default_environment_is_staging
    result = @tool.execute(operation: "health_check")

    assert result[:success]
    assert_equal "staging", result[:environment]
  end

  def test_operations_accept_empty_options
    result = @tool.execute(
      operation: "health_check",
      environment: "development",
      options: {}
    )

    assert result[:success]
  end

  # Duration and timing tests
  def test_deployment_includes_total_duration
    result = @tool.execute(
      operation: "deploy",
      environment: "development"
    )

    assert result[:success]
    assert result[:total_duration_seconds]
    assert result[:total_duration_seconds] > 0
  end

  def test_rollback_includes_total_duration
    result = @tool.execute(
      operation: "rollback",
      environment: "development"
    )

    assert result[:success]
    assert result[:total_duration_seconds]
    assert result[:total_duration_seconds] > 0
  end

  # Timestamp tests
  def test_operations_include_timestamps
    result = @tool.execute(
      operation: "health_check",
      environment: "development"
    )

    assert result[:success]
    assert result[:checked_at]
    assert_match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/, result[:checked_at])
  end

  # Production safety tests
  def test_production_operations_blocked_without_confirmation
    operations = ["deploy", "health_check", "log_analysis", "metric_collection"]

    operations.each do |op|
      result = @tool.execute(
        operation: op,
        environment: "production"
      )

      refute result[:success], "#{op} should require confirmation in production"
      assert_includes result[:error], "confirmation"
    end
  end

  def test_production_operations_succeed_with_confirmation
    operations = ["deploy", "health_check", "log_analysis", "metric_collection"]

    operations.each do |op|
      result = @tool.execute(
        operation: op,
        environment: "production",
        production_confirmed: true
      )

      # Rollback needs additional confirmation
      if op == "rollback"
        refute result[:success]
      else
        assert result[:success], "#{op} should succeed with confirmation"
      end
    end
  end

  # Error handling tests
  def test_handles_errors_gracefully
    # This would test error handling, but since our tool doesn't raise errors
    # in normal operation, we verify it returns success/failure properly
    result = @tool.execute(
      operation: "invalid",
      environment: "development"
    )

    refute result[:success]
    assert result[:error]
  end
end
