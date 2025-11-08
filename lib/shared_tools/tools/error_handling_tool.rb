# error_handling_tool.rb - Comprehensive error handling demonstration
require 'ruby_llm/tool'
require 'securerandom'
require 'net/http'
require 'json'

module SharedTools
  module Tools
    # Custom error classes for different error scenarios
    class ValidationError < StandardError
      attr_reader :suggestions

      def initialize(message, suggestions: [])
        super(message)
        @suggestions = suggestions
      end
    end

    class NetworkError < StandardError; end
    class AuthorizationError < StandardError; end
    class RetryableError < StandardError; end
    class ResourceNotFoundError < StandardError; end

    class ErrorHandlingTool < RubyLLM::Tool
      def self.name = 'error_handling_tool'

      description <<~'DESCRIPTION'
        Reference tool demonstrating comprehensive error handling patterns and resilience strategies
        for robust tool development. This tool showcases best practices for handling different
        types of errors including validation errors, network failures, authorization issues,
        and general exceptions. It implements retry mechanisms with exponential backoff,
        proper resource cleanup, detailed error categorization, and user-friendly error messages.

        This tool performs a demonstration operation (data validation and processing) that can
        encounter various error scenarios to showcase the error handling patterns.

        Error handling features:
        - Input validation with helpful suggestions
        - Network retry with exponential backoff
        - Authorization checks
        - Resource cleanup in ensure blocks
        - Detailed error categorization
        - Operation metadata tracking
        - Support reference IDs for debugging

        Example usage:
          tool = SharedTools::Tools::ErrorHandlingTool.new
          result = tool.execute(
            operation: "validate",
            data: {name: "test", value: 42},
            simulate_error: nil
          )
      DESCRIPTION

      params do
        string :operation, description: <<~DESC.strip
          The operation to perform. Options:
          - 'validate': Validate data structure and content
          - 'process': Process data with simulated network operation
          - 'authorize': Check authorization (always succeeds unless simulating error)

          This parameter demonstrates how to validate enum-like inputs.
        DESC

        object :data, description: <<~DESC.strip, required: false do
          Data object to process. Contains the data to be validated or processed.
          Example: {name: "example", value: 100, optional_field: "extra info"}
        DESC
          string :name, description: "Name or identifier of the data item. Should be at least 2 characters long.", required: false
          number :value, description: "Numeric value to process. Must be a valid number. Negative values will generate a warning.", required: false
          string :optional_field, description: "Any optional string field for additional data or context.", required: false
        end

        string :simulate_error, description: <<~DESC.strip, required: false
          Simulate a specific error type for testing error handling. Options:
          - 'validation': Trigger validation error
          - 'network': Trigger network error
          - 'authorization': Trigger authorization error
          - 'retryable': Trigger retryable error
          - 'resource_not_found': Trigger resource not found error
          - null/empty: Normal operation (default)

          This is useful for testing error handling in client applications.
        DESC

        integer :max_retries, description: <<~DESC.strip, required: false
          Maximum number of retries for retryable operations. Default: 3.
          Valid range: 0-10. Set to 0 to disable retries.
        DESC
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
        @resources_allocated = []
        @operation_start_time = nil
      end

      # Execute operation with comprehensive error handling
      #
      # @param operation [String] Operation to perform
      # @param data [Hash] Data to process
      # @param simulate_error [String, nil] Error type to simulate
      # @param max_retries [Integer] Maximum retry attempts
      #
      # @return [Hash] Operation result with success status
      def execute(operation:, simulate_error: nil, max_retries: 3, **data)
        @operation_start_time = Time.now
        @logger.info("ErrorHandlingTool#execute operation=#{operation} simulate_error=#{simulate_error}")

        begin
          # Validate inputs
          validate_preconditions(operation, data, max_retries)

          # Allocate resources (demonstration)
          allocate_resources

          # Perform main operation
          result = perform_operation(operation, data, simulate_error, max_retries)

          # Validate outputs
          validate_postconditions(result)

          @logger.info("Operation completed successfully")

          {
            success:  true,
            result:   result,
            metadata: operation_metadata
          }
        rescue ValidationError => e
          @logger.error("Validation error: #{e.message}")
          handle_validation_error(e, operation)
        rescue NetworkError => e
          @logger.error("Network error: #{e.message}")
          handle_network_error(e, operation)
        rescue AuthorizationError => e
          @logger.error("Authorization error: #{e.message}")
          handle_authorization_error(e, operation)
        rescue ResourceNotFoundError => e
          @logger.error("Resource not found: #{e.message}")
          handle_resource_not_found_error(e, operation)
        rescue StandardError => e
          @logger.error("General error: #{e.class} - #{e.message}")
          handle_general_error(e, operation)
        ensure
          cleanup_resources
        end
      end

      private

      # Validate operation parameters before execution
      def validate_preconditions(operation, data, max_retries)
        valid_operations = %w[validate process authorize]
        unless valid_operations.include?(operation)
          raise ValidationError.new(
            "Invalid operation: #{operation}",
            suggestions: ["Use one of: #{valid_operations.join(', ')}"]
          )
        end

        if max_retries < 0 || max_retries > 10
          raise ValidationError.new(
            "max_retries must be between 0 and 10, got #{max_retries}",
            suggestions: ["Use a value between 0 and 10"]
          )
        end

        if operation == 'process' && data.empty?
          raise ValidationError.new(
            "Data is required for 'process' operation",
            suggestions: ["Provide a data object with 'name' and 'value' fields"]
          )
        end

        @logger.debug("Preconditions validated successfully")
      end

      # Main operation with retry logic
      def perform_operation(operation, data, simulate_error, max_retries)
        retry_count = 0

        begin
          # Simulate specific error if requested
          simulate_error_if_requested(simulate_error, retry_count)

          case operation
          when 'validate'
            perform_validation(data)
          when 'process'
            perform_processing(data)
          when 'authorize'
            perform_authorization(data)
          else
            raise ArgumentError, "Unknown operation: #{operation}"
          end

        rescue RetryableError => e
          retry_count += 1
          @logger.warn("Retryable error occurred, attempt #{retry_count}/#{max_retries}")

          if retry_count <= max_retries
            sleep_duration = 2 ** retry_count  # Exponential backoff
            @logger.debug("Sleeping for #{sleep_duration} seconds before retry")
            sleep(sleep_duration)
            retry
          else
            @logger.error("Max retries (#{max_retries}) exceeded")
            raise NetworkError, "Operation failed after #{max_retries} retries: #{e.message}"
          end
        end
      end

      # Simulate errors for testing purposes
      def simulate_error_if_requested(error_type, retry_count)
        return if error_type.nil? || error_type.empty?

        case error_type
        when 'validation'
          raise ValidationError.new(
            "Simulated validation error",
            suggestions: ["Fix the data format", "Check required fields"]
          )
        when 'network'
          raise NetworkError, "Simulated network connection failure"
        when 'authorization'
          raise AuthorizationError, "Simulated authorization failure"
        when 'retryable'
          # Only fail on first two attempts to test retry logic
          if retry_count < 2
            raise RetryableError, "Simulated temporary failure (will retry)"
          end
        when 'resource_not_found'
          raise ResourceNotFoundError, "Simulated resource not found"
        end
      end

      # Perform data validation
      def perform_validation(data)
        @logger.debug("Performing validation")

        errors = []
        warnings = []

        if data[:name].nil? || data[:name].to_s.empty?
          errors << "name is required"
        elsif data[:name].to_s.length < 2
          warnings << "name is very short"
        end

        if data[:value].nil?
          errors << "value is required"
        elsif !data[:value].is_a?(Numeric)
          errors << "value must be a number"
        elsif data[:value] < 0
          warnings << "value is negative"
        end

        if errors.any?
          raise ValidationError.new(
            "Data validation failed: #{errors.join(', ')}",
            suggestions: ["Ensure all required fields are present and valid"]
          )
        end

        {
          validated: true,
          data: data,
          warnings: warnings,
          validated_at: Time.now.iso8601
        }
      end

      # Perform data processing (simulates network operation)
      def perform_processing(data)
        @logger.debug("Performing processing")

        # Simulate processing work
        sleep(0.1)

        processed_value = data[:value].to_f * 1.5
        {
          processed: true,
          original_value: data[:value],
          processed_value: processed_value.round(2),
          name: data[:name],
          processed_at: Time.now.iso8601
        }
      end

      # Perform authorization check
      def perform_authorization(data)
        @logger.debug("Performing authorization")

        {
          authorized: true,
          operation: "authorize",
          authorized_at: Time.now.iso8601
        }
      end

      # Validate operation results
      def validate_postconditions(result)
        unless result.is_a?(Hash)
          raise StandardError, "Operation result must be a Hash"
        end

        @logger.debug("Postconditions validated successfully")
      end

      # Allocate resources (demonstration)
      def allocate_resources
        resource_id = SecureRandom.uuid
        @resources_allocated << resource_id
        @logger.debug("Allocated resource: #{resource_id}")
      end

      # Handle validation errors
      def handle_validation_error(error, operation)
        {
          success:         false,
          error_type:      "validation",
          error:           error.message,
          suggestions:     error.suggestions,
          operation:       operation,
          support_reference: SecureRandom.uuid
        }
      end

      # Handle network errors
      def handle_network_error(error, operation)
        {
          success:         false,
          error_type:      "network",
          error:           "Network operation failed: #{error.message}",
          retry_suggested: true,
          retry_after:     30,
          operation:       operation,
          support_reference: SecureRandom.uuid
        }
      end

      # Handle authorization errors
      def handle_authorization_error(error, operation)
        {
          success:          false,
          error_type:       "authorization",
          error:            "Access denied: #{error.message}",
          documentation_url: "https://github.com/madbomber/shared_tools",
          operation:        operation,
          support_reference: SecureRandom.uuid
        }
      end

      # Handle resource not found errors
      def handle_resource_not_found_error(error, operation)
        {
          success:          false,
          error_type:       "resource_not_found",
          error:            "Resource not found: #{error.message}",
          operation:        operation,
          support_reference: SecureRandom.uuid
        }
      end

      # Handle general errors
      def handle_general_error(error, operation)
        {
          success:           false,
          error_type:        "general",
          error:             "An unexpected error occurred: #{error.message}",
          error_class:       error.class.name,
          operation:         operation,
          support_reference: SecureRandom.uuid
        }
      end

      # Collect operation metadata
      def operation_metadata
        execution_time = @operation_start_time ? (Time.now - @operation_start_time).round(3) : 0

        {
          execution_time_seconds: execution_time,
          resources_allocated: @resources_allocated.length,
          timestamp: Time.now.iso8601,
          tool_version: "1.0.0"
        }
      end

      # Clean up allocated resources
      def cleanup_resources
        if @resources_allocated.any?
          @logger.debug("Cleaning up #{@resources_allocated.length} resources")
          @resources_allocated.each do |resource_id|
            @logger.debug("Released resource: #{resource_id}")
          end
          @resources_allocated.clear
        end
      end
    end
  end
end
