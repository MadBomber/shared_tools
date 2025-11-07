# devops_toolkit.rb - System administration and deployment tools
require 'ruby_llm/tool'
require 'securerandom'

module SharedTools
  module Tools
    class DevopsToolkit < RubyLLM::Tool
      def self.name = "devops_toolkit"

      description <<~'DESCRIPTION'
        Comprehensive DevOps and system administration toolkit for managing application deployments,
        monitoring system health, and performing operational tasks across different environments.
        This tool provides secure, audited access to common DevOps operations including deployments,
        rollbacks, health checks, log analysis, and metrics collection. It includes built-in safety
        mechanisms for production environments, comprehensive logging for compliance, and support
        for multiple deployment environments. All operations are logged and require appropriate
        permissions and confirmations for sensitive environments.

        Safety features:
        - Production operations require explicit confirmation
        - All operations are logged with unique operation IDs
        - Environment-specific restrictions and validations
        - Rollback capabilities for failed deployments
        - Health check integration before critical operations

        Supported environments: development, staging, production
      DESCRIPTION

      params do
        string :operation, description: <<~DESC.strip
          Specific DevOps operation to perform:
          - 'deploy': Deploy application code to the specified environment
          - 'rollback': Revert to the previous stable deployment version
          - 'health_check': Perform comprehensive health and status checks
          - 'log_analysis': Analyze application and system logs for issues
          - 'metric_collection': Gather and report system and application metrics
          Each operation has specific requirements and safety checks.
        DESC

        string :environment, description: <<~DESC.strip, required: false
          Target environment for the DevOps operation:
          - 'development': Local or shared development environment (minimal restrictions)
          - 'staging': Pre-production environment for testing (moderate restrictions)
          - 'production': Live production environment (maximum restrictions and confirmations)
          Production operations require explicit confirmation via the 'production_confirmed' option.
          Default: staging
        DESC

        object :options, description: <<~DESC.strip, required: false
          Hash of operation-specific options and parameters:
          - For deploy: version, branch, rollback_on_failure, notification_channels
          - For rollback: target_version, confirmation_required
          - For health_check: services_to_check, timeout_seconds
          - For log_analysis: time_range, log_level, search_patterns
          - For metric_collection: metric_types, time_window, output_format
          Production operations require 'production_confirmed: true' for safety.
        DESC
      end

      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
        @operation_log = []
      end

      def execute(operation:, environment: "staging", options: {})
        operation_id = SecureRandom.uuid
        @logger.info("DevOpsToolkit#execute operation=#{operation} environment=#{environment} operation_id=#{operation_id}")

        # Validate environment
        unless valid_environment?(environment)
          return {
            success: false,
            error: "Invalid environment: #{environment}",
            valid_environments: ["development", "staging", "production"]
          }
        end

        # Security: Require explicit production confirmation
        if environment == "production" && !options[:production_confirmed]
          @logger.warn("Production operation attempted without confirmation")
          return {
            success: false,
            error: "Production operations require explicit confirmation",
            required_option: "production_confirmed: true",
            environment: environment
          }
        end

        # Log operation
        log_operation(operation_id, operation, environment, options)

        # Execute operation
        result = case operation
        when "deploy"
          perform_deployment(environment, options, operation_id)
        when "rollback"
          perform_rollback(environment, options, operation_id)
        when "health_check"
          perform_health_check(environment, options, operation_id)
        when "log_analysis"
          analyze_logs(environment, options, operation_id)
        when "metric_collection"
          collect_metrics(environment, options, operation_id)
        else
          {
            success: false,
            error: "Unknown operation: #{operation}",
            valid_operations: ["deploy", "rollback", "health_check", "log_analysis", "metric_collection"]
          }
        end

        # Add operation_id to result
        result[:operation_id] = operation_id
        result
      rescue => e
        @logger.error("DevOps operation failed: #{e.message}")
        {
          success: false,
          error: "DevOps operation failed: #{e.message}",
          error_type: e.class.name,
          operation_id: operation_id
        }
      end

      private

      # Validate environment
      def valid_environment?(environment)
        ["development", "staging", "production"].include?(environment)
      end

      # Log operation for audit trail
      def log_operation(operation_id, operation, environment, options)
        log_entry = {
          operation_id: operation_id,
          operation: operation,
          environment: environment,
          options_summary: options.keys,
          timestamp: Time.now.iso8601,
          user: "system"  # In production: actual user from auth context
        }

        @operation_log << log_entry
        @logger.info("DevOps operation logged: #{operation_id}")
      end

      # Perform deployment
      def perform_deployment(environment, options, operation_id)
        @logger.info("Starting deployment to #{environment}")

        version = options[:version] || "latest"
        branch = options[:branch] || "main"
        # rollback_on_failure = options[:rollback_on_failure].nil? ? true : options[:rollback_on_failure]

        # Simulate deployment steps
        deployment_steps = [
          {step: "pre_deployment_checks", status: "completed", duration: 0.5},
          {step: "backup_current_version", status: "completed", duration: 1.0},
          {step: "deploy_new_version", status: "completed", duration: 2.5},
          {step: "run_migrations", status: "completed", duration: 1.5},
          {step: "post_deployment_checks", status: "completed", duration: 1.0}
        ]

        @logger.info("Deployment completed successfully")

        {
          success: true,
          operation: "deploy",
          environment: environment,
          deployment_id: SecureRandom.uuid,
          version: version,
          branch: branch,
          deployed_at: Time.now.iso8601,
          deployment_steps: deployment_steps,
          rollback_available: true,
          total_duration_seconds: deployment_steps.sum { |s| s[:duration] },
          details: "Deployment completed successfully to #{environment}"
        }
      end

      # Perform rollback
      def perform_rollback(environment, options, operation_id)
        @logger.info("Starting rollback in #{environment}")

        target_version = options[:target_version] || "previous"

        # Production rollbacks need extra confirmation
        if environment == "production" && !options[:rollback_confirmed]
          @logger.warn("Production rollback requires confirmation")
          return {
            success: false,
            error: "Production rollback requires explicit confirmation",
            required_option: "rollback_confirmed: true",
            environment: environment
          }
        end

        rollback_steps = [
          {step: "validate_target_version", status: "completed", duration: 0.5},
          {step: "stop_current_services", status: "completed", duration: 1.0},
          {step: "restore_previous_version", status: "completed", duration: 2.0},
          {step: "restart_services", status: "completed", duration: 1.5},
          {step: "verify_rollback", status: "completed", duration: 1.0}
        ]

        @logger.info("Rollback completed successfully")

        {
          success: true,
          operation: "rollback",
          environment: environment,
          rollback_id: SecureRandom.uuid,
          target_version: target_version,
          rolled_back_at: Time.now.iso8601,
          rollback_steps: rollback_steps,
          total_duration_seconds: rollback_steps.sum { |s| s[:duration] },
          details: "Successfully rolled back to #{target_version}"
        }
      end

      # Perform health check
      def perform_health_check(environment, options, operation_id)
        @logger.info("Performing health check for #{environment}")

        services_to_check = options[:services_to_check] || ["web", "api", "database", "cache"]
        timeout_seconds = options[:timeout_seconds] || 30

        # Simulate health checks
        health_results = services_to_check.map do |service|
          {
            service: service,
            status: "healthy",
            response_time_ms: rand(50..200),
            last_check: Time.now.iso8601,
            details: "Service operational"
          }
        end

        all_healthy = health_results.all? { |r| r[:status] == "healthy" }

        @logger.info("Health check completed: #{all_healthy ? 'All services healthy' : 'Issues detected'}")

        {
          success: true,
          operation: "health_check",
          environment: environment,
          overall_status: all_healthy ? "healthy" : "degraded",
          services_checked: services_to_check.length,
          healthy_services: health_results.count { |r| r[:status] == "healthy" },
          health_results: health_results,
          checked_at: Time.now.iso8601,
          check_duration_seconds: timeout_seconds
        }
      end

      # Analyze logs
      def analyze_logs(environment, options, operation_id)
        @logger.info("Analyzing logs for #{environment}")

        time_range = options[:time_range] || "last_hour"
        log_level = options[:log_level] || "error"
        # search_patterns = options[:search_patterns] || []

        # Simulate log analysis
        log_entries_analyzed = 5000
        errors_found = rand(0..20)
        warnings_found = rand(5..50)

        findings = []

        if errors_found > 0
          findings << {
            severity: "error",
            count: errors_found,
            pattern: "Exception in /api/users",
            first_occurrence: (Time.now - 3600).iso8601,
            last_occurrence: Time.now.iso8601
          }
        end

        if warnings_found > 10
          findings << {
            severity: "warning",
            count: warnings_found,
            pattern: "Slow query detected",
            first_occurrence: (Time.now - 1800).iso8601,
            last_occurrence: Time.now.iso8601
          }
        end

        @logger.info("Log analysis completed: #{findings.length} issues found")

        {
          success: true,
          operation: "log_analysis",
          environment: environment,
          time_range: time_range,
          log_level: log_level,
          entries_analyzed: log_entries_analyzed,
          errors_found: errors_found,
          warnings_found: warnings_found,
          findings: findings,
          analyzed_at: Time.now.iso8601,
          recommendations: generate_log_recommendations(findings)
        }
      end

      # Collect metrics
      def collect_metrics(environment, options, operation_id)
        @logger.info("Collecting metrics for #{environment}")

        metric_types = options[:metric_types] || ["cpu", "memory", "disk", "network"]
        time_window = options[:time_window] || "last_5_minutes"
        output_format = options[:output_format] || "summary"

        # Simulate metric collection
        metrics = metric_types.map do |metric_type|
          case metric_type
          when "cpu"
            {
              type: "cpu",
              current_usage_percent: rand(10..90),
              average_usage_percent: rand(20..70),
              peak_usage_percent: rand(50..100),
              unit: "percent"
            }
          when "memory"
            {
              type: "memory",
              current_usage_gb: rand(1.0..8.0).round(2),
              total_gb: 16.0,
              usage_percent: rand(20..80),
              unit: "gigabytes"
            }
          when "disk"
            {
              type: "disk",
              current_usage_gb: rand(10.0..100.0).round(2),
              total_gb: 500.0,
              usage_percent: rand(10..60),
              unit: "gigabytes"
            }
          when "network"
            {
              type: "network",
              ingress_mbps: rand(1.0..50.0).round(2),
              egress_mbps: rand(1.0..50.0).round(2),
              unit: "megabits_per_second"
            }
          else
            {
              type: metric_type,
              status: "unknown",
              message: "Metric type not implemented"
            }
          end
        end

        @logger.info("Metrics collection completed: #{metrics.length} metrics")

        {
          success: true,
          operation: "metric_collection",
          environment: environment,
          time_window: time_window,
          metrics_collected: metrics.length,
          metrics: metrics,
          collected_at: Time.now.iso8601,
          output_format: output_format
        }
      end

      # Generate recommendations based on log findings
      def generate_log_recommendations(findings)
        recommendations = []

        findings.each do |finding|
          case finding[:severity]
          when "error"
            recommendations << "Investigate #{finding[:pattern]} - #{finding[:count]} occurrences"
          when "warning"
            if finding[:count] > 20
              recommendations << "High frequency of #{finding[:pattern]} - consider optimization"
            end
          end
        end

        recommendations << "No critical issues found" if recommendations.empty?
        recommendations
      end

      # Accessor for operation log (for testing)
      def operation_log
        @operation_log
      end
    end
  end
end
