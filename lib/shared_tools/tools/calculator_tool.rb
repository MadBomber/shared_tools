# calculator_tool.rb - Safe mathematical calculator
require 'ruby_llm/tool'
require 'dentaku'

module SharedTools
  module Tools
    class CalculatorTool < RubyLLM::Tool
      def self.name = 'calculator'

      description <<~'DESCRIPTION'
        Perform advanced mathematical calculations with comprehensive error handling and validation.
        This tool supports basic arithmetic operations, parentheses, and common mathematical functions.
        It uses Dentaku for safe evaluation of mathematical expressions without executing arbitrary code,
        making it suitable for use in AI-assisted calculations where security is critical.
        The tool returns formatted results with configurable precision and helpful error messages
        when invalid expressions are provided.

        Supported operations:
        - Basic arithmetic: +, -, *, /, %
        - Parentheses for grouping: ( )
        - Exponentiation: ^ or pow(base, exponent)
        - Comparison operators: =, <, >, <=, >=, !=
        - Logical operators: and, or, not
        - Mathematical functions: sqrt, round, roundup, rounddown, abs
        - Trigonometric functions: sin, cos, tan

        Example usage:
          tool = SharedTools::Tools::CalculatorTool.new
          result = tool.execute(expression: "2 + 2")
          puts "Result: #{result[:result]}"

          # With precision
          result = tool.execute(expression: "10 / 3", precision: 4)
          puts "Result: #{result[:result]}" # 3.3333
      DESCRIPTION

      params do
        string :expression, description: <<~DESC.strip
          Mathematical expression to evaluate using standard arithmetic operators and parentheses.
          Supported operations include: addition (+), subtraction (-), multiplication (*),
          division (/), modulo (%), exponentiation (**), and parentheses for grouping.
          Examples: '2 + 2', '(10 * 5) / 2', '15.5 - 3.2', 'sqrt(16)', 'round(3.14159, 2)'.
          The expression is evaluated safely using Dentaku math parser.
        DESC

        integer :precision, description: <<~DESC.strip, required: false
          Number of decimal places to display in the result. Must be between 0 and 10.
          Set to 0 for whole numbers only, or higher values for more precise decimal results.
          Default is 2 decimal places, which works well for most financial and general calculations.
        DESC
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
        @calculator = Dentaku::Calculator.new

        # Enable case-insensitive function names
        Dentaku.enable_caching!
      end

      # Execute mathematical calculation
      #
      # @param expression [String] Mathematical expression to evaluate
      # @param precision [Integer] Number of decimal places (0-10), default 2
      #
      # @return [Hash] Calculation result with success status
      def execute(expression:, precision: 2)
        @logger.info("CalculatorTool#execute expression=#{expression.inspect} precision=#{precision}")

        begin
          # Validate precision
          precision = validate_precision(precision)

          # Evaluate expression safely using Dentaku
          result = @calculator.evaluate(expression)

          # Handle nil result (invalid expression)
          unless result
            raise Dentaku::ParseError, "Could not parse expression"
          end

          # Format result with specified precision
          formatted_result = format_result(result, precision)

          @logger.info("Calculation successful: #{expression} = #{formatted_result}")

          {
            success:    true,
            result:     formatted_result,
            expression: expression,
            precision:  precision,
            raw_result: result
          }
        rescue Dentaku::ParseError => e
          @logger.error("Parse error for expression '#{expression}': #{e.message}")
          {
            success:    false,
            error:      "Invalid expression: #{e.message}",
            expression: expression,
            suggestion: "Try expressions like '2 + 2', '(10 * 5) / 2', or 'sqrt(16)'"
          }
        rescue Dentaku::ArgumentError => e
          @logger.error("Argument error for expression '#{expression}': #{e.message}")
          {
            success:    false,
            error:      "Invalid arguments: #{e.message}",
            expression: expression,
            suggestion: "Check that functions have the correct number of arguments"
          }
        rescue ZeroDivisionError => e
          @logger.error("Division by zero in expression '#{expression}'")
          {
            success:    false,
            error:      "Division by zero",
            expression: expression,
            suggestion: "Ensure the denominator is not zero"
          }
        rescue => e
          @logger.error("Calculation failed for '#{expression}': #{e.message}")
          {
            success:    false,
            error:      "Calculation error: #{e.message}",
            expression: expression,
            suggestion: "Verify the expression syntax and try again"
          }
        end
      end

      private

      # Validate and normalize precision value
      #
      # @param precision [Integer] Requested precision
      # @return [Integer] Validated precision (0-10)
      def validate_precision(precision)
        precision = precision.to_i

        if precision < 0
          @logger.warn("Negative precision #{precision} adjusted to 0")
          return 0
        end

        if precision > 10
          @logger.warn("Precision #{precision} exceeds maximum, adjusted to 10")
          return 10
        end

        precision
      end

      # Format result with specified precision
      #
      # @param result [Numeric] Raw calculation result
      # @param precision [Integer] Number of decimal places
      # @return [Numeric] Formatted result
      def format_result(result, precision)
        # Handle boolean results
        return result if result == true || result == false

        # Handle numeric results
        return result unless result.is_a?(Numeric)

        # Round to specified precision
        result.round(precision)
      end
    end
  end
end
