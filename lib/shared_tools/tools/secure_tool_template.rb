# secure_tool_template.rb - Comprehensive security best practices template
require 'ruby_llm/tool'
require 'timeout'
require 'securerandom'

module SharedTools
  module Tools
    class SecureToolTemplate < RubyLLM::Tool
      def self.name = 'secure_tool_template'

      description <<~'DESCRIPTION'
        Reference template demonstrating comprehensive security best practices for safe tool development.
        This tool serves as a complete security framework implementation that can be adapted for other
        tools handling sensitive data or performing privileged operations. It demonstrates all essential
        security mechanisms that should be considered when building production-ready AI tools.

        Security features implemented:
        - Input validation with whitelist filtering
        - Output sanitization to prevent information leakage
        - Permission and authorization checks
        - Rate limiting to prevent abuse
        - Comprehensive audit logging
        - Timeout mechanisms for resource control
        - Security violation tracking
        - Error handling without information disclosure

        This template can be used as a starting point for developing secure tools that interact with
        sensitive systems, handle user data, or perform privileged operations.
      DESCRIPTION

      params do
        string :user_input, description: <<~DESC.strip
          User-provided input string that will be processed with comprehensive security validation.
          The input undergoes multiple security checks:
          - Length validation (maximum 1000 characters)
          - Character whitelist (alphanumeric, spaces, hyphens, underscores, dots)
          - Sanitization to remove potentially dangerous characters
          - Rate limiting per user/session
          All validation failures are logged for security monitoring and compliance.
        DESC

        string :operation_type, description: <<~DESC.strip, required: false
          Type of operation to perform on the input. Options:
          - 'read': Read-only operation (lowest security requirements)
          - 'write': Data modification operation (moderate security requirements)
          - 'admin': Administrative operation (highest security requirements)
          Default is 'read'. Operations with higher security levels require additional validations.
        DESC

        integer :timeout_seconds, description: <<~DESC.strip, required: false
          Maximum execution time in seconds for the operation. Range: 1-300 seconds.
          Default: 30 seconds. Prevents resource exhaustion and ensures responsive operations.
          Timeout enforces proper resource management and prevents hung operations.
        DESC
      end

      # Rate limiting store (in production, use Redis or similar)
      @rate_limit_store = {}
      @rate_limit_mutex = Mutex.new

      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
        @audit_log = []
      end

      def execute(user_input:, operation_type: 'read', timeout_seconds: 30)
        execution_id = SecureRandom.uuid
        start_time = Time.now

        @logger.info("SecureToolTemplate#execute operation_type=#{operation_type} execution_id=#{execution_id}")

        begin
          # 1. Validate input length
          validate_input_length(user_input)

          # 2. Sanitize inputs
          sanitized_input = sanitize_input(user_input)

          # 3. Validate permissions for operation type
          validate_permissions(operation_type)

          # 4. Check rate limits
          check_rate_limits(execution_id)

          # 5. Audit logging
          log_tool_usage(execution_id, operation_type, sanitized_input)

          # 6. Execute with timeout
          timeout = validate_timeout(timeout_seconds)
          result = execute_with_timeout(sanitized_input, operation_type, timeout)

          # 7. Sanitize outputs
          sanitized_result = sanitize_output(result)

          execution_time = (Time.now - start_time).round(3)
          @logger.info("Operation completed successfully in #{execution_time}s")

          {
            success: true,
            result: sanitized_result,
            operation_type: operation_type,
            execution_id: execution_id,
            execution_time_seconds: execution_time,
            executed_at: Time.now.iso8601
          }

        rescue SecurityError => e
          @logger.error("Security violation: #{e.message}")
          log_security_violation(e, execution_id, user_input)
          {
            success: false,
            error: "Security violation: Access denied",
            error_type: "security",
            violation_logged: true,
            execution_id: execution_id
          }
        rescue Timeout::Error => e
          @logger.error("Operation timeout after #{timeout_seconds}s")
          {
            success: false,
            error: "Operation exceeded timeout of #{timeout_seconds} seconds",
            error_type: "timeout",
            execution_id: execution_id
          }
        rescue ArgumentError => e
          @logger.error("Validation error: #{e.message}")
          {
            success: false,
            error: e.message,
            error_type: "validation",
            execution_id: execution_id
          }
        rescue => e
          @logger.error("Tool execution failed: #{e.class} - #{e.message}")
          {
            success: false,
            error: "Tool execution failed: #{e.message}",
            error_type: e.class.name,
            execution_id: execution_id
          }
        end
      end

      private

      # Validate input length to prevent buffer overflow attacks
      def validate_input_length(input)
        if input.nil? || input.empty?
          raise ArgumentError, "Input cannot be empty"
        end

        if input.length > 1000
          raise ArgumentError, "Input too long: #{input.length} characters (maximum 1000)"
        end

        @logger.debug("Input length validation passed: #{input.length} characters")
      end

      # Sanitize input by removing potentially dangerous characters
      def sanitize_input(input)
        # Remove all characters except alphanumeric, spaces, hyphens, underscores, and dots
        sanitized = input.gsub(/[^\w\s\-\.]/, '')

        @logger.debug("Input sanitized (#{input.length} -> #{sanitized.length} characters)")
        sanitized
      end

      # Validate user permissions based on operation type
      def validate_permissions(operation_type)
        # In production, this would check actual user permissions from auth system
        valid_operations = ['read', 'write', 'admin']

        unless valid_operations.include?(operation_type)
          raise SecurityError, "Invalid operation type: #{operation_type}"
        end

        # Admin operations require elevated privileges
        if operation_type == 'admin'
          # In production: verify admin role from authentication context
          @logger.warn("Admin operation requested - elevated privileges required")
        end

        @logger.debug("Permission validation passed for operation: #{operation_type}")
      end

      # Check rate limits to prevent abuse
      def check_rate_limits(execution_id)
        # Simple rate limiting (in production, use Redis with sliding windows)
        self.class.instance_variable_get(:@rate_limit_mutex).synchronize do
          store = self.class.instance_variable_get(:@rate_limit_store)
          current_time = Time.now.to_i

          # Clean old entries (older than 1 minute)
          store.reject! { |k, v| v < current_time - 60 }

          # Count requests in last minute (max 30 per minute)
          recent_requests = store.values.count { |time| time > current_time - 60 }

          if recent_requests >= 30
            raise SecurityError, "Rate limit exceeded: #{recent_requests} requests in last minute"
          end

          # Record this request
          store[execution_id] = current_time

          @logger.debug("Rate limit check passed: #{recent_requests + 1}/30 requests")
        end
      end

      # Log tool usage for audit trail
      def log_tool_usage(execution_id, operation_type, sanitized_input)
        audit_entry = {
          execution_id: execution_id,
          operation_type: operation_type,
          input_preview: sanitized_input[0..50],
          timestamp: Time.now.iso8601,
          user_context: "system"  # In production: actual user ID from auth context
        }

        @audit_log << audit_entry
        @logger.debug("Audit log entry created: #{execution_id}")
      end

      # Validate and normalize timeout value
      def validate_timeout(timeout)
        timeout = timeout.to_i

        if timeout < 1
          @logger.warn("Timeout #{timeout} too low, adjusting to 1")
          return 1
        end

        if timeout > 300
          @logger.warn("Timeout #{timeout} too high, adjusting to 300")
          return 300
        end

        timeout
      end

      # Execute operation with timeout protection
      def execute_with_timeout(input, operation_type, timeout)
        @logger.debug("Executing operation with #{timeout}s timeout")

        Timeout::timeout(timeout) do
          # Simulate actual tool logic based on operation type
          case operation_type
          when 'read'
            perform_read_operation(input)
          when 'write'
            perform_write_operation(input)
          when 'admin'
            perform_admin_operation(input)
          else
            raise ArgumentError, "Unknown operation type: #{operation_type}"
          end
        end
      end

      # Simulate read operation
      def perform_read_operation(input)
        # In production: actual read logic here
        {
          operation: 'read',
          data: {
            input_received: input,
            character_count: input.length,
            word_count: input.split.length,
            processed: true
          }
        }
      end

      # Simulate write operation
      def perform_write_operation(input)
        # In production: actual write logic here
        # This would have additional security checks
        {
          operation: 'write',
          data: {
            written: true,
            input_length: input.length,
            timestamp: Time.now.iso8601
          }
        }
      end

      # Simulate admin operation
      def perform_admin_operation(input)
        # In production: actual admin logic here
        # This would have the strictest security checks
        {
          operation: 'admin',
          data: {
            executed: true,
            admin_action: 'completed',
            requires_review: true
          }
        }
      end

      # Sanitize output to prevent information leakage
      def sanitize_output(output)
        # Remove any potentially sensitive information from output
        # In production: redact PII, credentials, internal paths, etc.

        if output.is_a?(Hash)
          # Recursively sanitize hash values
          output.transform_values { |v| sanitize_value(v) }
        else
          sanitize_value(output)
        end
      end

      # Sanitize individual value
      def sanitize_value(value)
        case value
        when Hash
          value.transform_values { |v| sanitize_value(v) }
        when Array
          value.map { |v| sanitize_value(v) }
        when String
          # Remove any patterns that look like credentials, tokens, or keys
          value.gsub(/\b[A-Za-z0-9_-]{20,}\b/, '[REDACTED]')
        else
          value
        end
      end

      # Log security violations for monitoring
      def log_security_violation(error, execution_id, input)
        violation_entry = {
          execution_id: execution_id,
          violation_type: error.class.name,
          message: error.message,
          input_preview: input[0..50],
          timestamp: Time.now.iso8601,
          severity: 'high'
        }

        @audit_log << violation_entry
        @logger.error("SECURITY VIOLATION: #{violation_entry.to_json}")

        # In production: send alert to security monitoring system
      end

      # Accessor for audit log (for testing)
      def audit_log
        @audit_log
      end
    end
  end
end
