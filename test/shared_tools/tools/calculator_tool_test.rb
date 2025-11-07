# frozen_string_literal: true

require "test_helper"

class CalculatorToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::CalculatorTool.new
  end

  def test_tool_name
    assert_equal 'calculator', SharedTools::Tools::CalculatorTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  # Basic arithmetic operations
  def test_simple_addition
    result = @tool.execute(expression: "2 + 2")

    assert result[:success]
    assert_equal 4.0, result[:result]
    assert_equal "2 + 2", result[:expression]
    assert_equal 2, result[:precision]
  end

  def test_simple_subtraction
    result = @tool.execute(expression: "10 - 3")

    assert result[:success]
    assert_equal 7.0, result[:result]
  end

  def test_simple_multiplication
    result = @tool.execute(expression: "5 * 6")

    assert result[:success]
    assert_equal 30.0, result[:result]
  end

  def test_simple_division
    result = @tool.execute(expression: "20 / 4")

    assert result[:success]
    assert_equal 5.0, result[:result]
  end

  def test_modulo_operation
    result = @tool.execute(expression: "17 % 5")

    assert result[:success]
    assert_equal 2.0, result[:result]
  end

  def test_exponentiation
    result = @tool.execute(expression: "2 ^ 8")

    assert result[:success]
    assert_equal 256.0, result[:result]
  end

  # Complex expressions
  def test_expression_with_parentheses
    result = @tool.execute(expression: "(10 + 5) * 2")

    assert result[:success]
    assert_equal 30.0, result[:result]
  end

  def test_nested_parentheses
    result = @tool.execute(expression: "((10 + 5) * 2) / 3")

    assert result[:success]
    assert_equal 10.0, result[:result]
  end

  def test_order_of_operations
    result = @tool.execute(expression: "2 + 3 * 4")

    assert result[:success]
    assert_equal 14.0, result[:result]
  end

  def test_decimal_arithmetic
    result = @tool.execute(expression: "15.5 - 3.2")

    assert result[:success]
    assert_equal 12.3, result[:result]
  end

  # Precision handling
  def test_default_precision_is_two
    result = @tool.execute(expression: "10 / 3")

    assert result[:success]
    assert_equal 2, result[:precision]
    assert_equal 3.33, result[:result]
  end

  def test_custom_precision
    result = @tool.execute(expression: "10 / 3", precision: 4)

    assert result[:success]
    assert_equal 4, result[:precision]
    assert_equal 3.3333, result[:result]
  end

  def test_zero_precision
    result = @tool.execute(expression: "10 / 3", precision: 0)

    assert result[:success]
    assert_equal 0, result[:precision]
    assert_equal 3, result[:result]
  end

  def test_precision_capped_at_ten
    result = @tool.execute(expression: "1 / 7", precision: 15)

    assert result[:success]
    assert_equal 10, result[:precision]
    assert_in_delta 0.1428571429, result[:result], 0.0000000001
  end

  def test_negative_precision_adjusted_to_zero
    result = @tool.execute(expression: "5.7", precision: -5)

    assert result[:success]
    assert_equal 0, result[:precision]
    assert_equal 6, result[:result]
  end

  # Mathematical functions
  def test_sqrt_function
    result = @tool.execute(expression: "sqrt(16)")

    assert result[:success]
    assert_equal 4.0, result[:result]
  end

  def test_round_function
    result = @tool.execute(expression: "round(3.14159)")

    assert result[:success]
    assert_equal 3.0, result[:result]
  end

  def test_round_function_with_precision
    result = @tool.execute(expression: "round(3.14159, 2)")

    assert result[:success]
    assert_equal 3.14, result[:result]
  end

  # Comparison and logical operations
  def test_comparison_greater_than
    result = @tool.execute(expression: "10 > 5")

    assert result[:success]
    assert_equal true, result[:result]
  end

  def test_comparison_equals
    result = @tool.execute(expression: "5 = 5")

    assert result[:success]
    assert_equal true, result[:result]
  end

  def test_logical_and
    result = @tool.execute(expression: "(10 > 5) and (3 < 5)")

    assert result[:success]
    assert_equal true, result[:result]
  end

  def test_logical_or
    result = @tool.execute(expression: "(10 > 5) or (3 > 5)")

    assert result[:success]
    assert_equal true, result[:result]
  end

  # Error handling
  def test_division_by_zero
    result = @tool.execute(expression: "10 / 0")

    # Dentaku may handle division by zero differently
    # It might return Infinity or raise an error
    refute result[:success] unless result[:result] == Float::INFINITY
  end

  def test_invalid_expression_empty
    result = @tool.execute(expression: "")

    refute result[:success]
    assert result[:error]
    assert result[:suggestion]
  end

  def test_invalid_expression_malformed
    result = @tool.execute(expression: "2 + + 3")

    refute result[:success]
    assert result[:error]
    assert result[:suggestion]
  end

  def test_unmatched_parentheses
    result = @tool.execute(expression: "(2 + 3")

    refute result[:success]
    assert result[:error]
  end

  def test_invalid_function
    result = @tool.execute(expression: "notafunction(5)")

    refute result[:success]
    assert result[:error]
  end

  def test_function_with_wrong_arguments
    result = @tool.execute(expression: "sqrt()")

    refute result[:success]
    assert result[:error]
  end

  # Raw result preservation
  def test_includes_raw_result
    result = @tool.execute(expression: "10 / 3", precision: 2)

    assert result[:success]
    assert result.key?(:raw_result)
    assert_in_delta 3.333333, result[:raw_result], 0.000001
    assert_equal 3.33, result[:result]
  end

  # Complex real-world calculations
  def test_financial_calculation
    # Calculate compound interest: P(1 + r)^n
    result = @tool.execute(expression: "1000 * (1 + 0.05) ^ 10", precision: 2)

    assert result[:success]
    assert_in_delta 1628.89, result[:result], 0.01
  end

  def test_percentage_calculation
    result = @tool.execute(expression: "150 * 0.15")

    assert result[:success]
    assert_equal 22.5, result[:result]
  end

  def test_area_of_circle
    # Area = π * r^2 (using approximation of π)
    result = @tool.execute(expression: "3.14159 * 5 ^ 2", precision: 2)

    assert result[:success]
    assert_in_delta 78.54, result[:result], 0.01
  end

  # Edge cases
  def test_negative_numbers
    result = @tool.execute(expression: "-5 + 3")

    assert result[:success]
    assert_equal(-2.0, result[:result])
  end

  def test_very_large_numbers
    result = @tool.execute(expression: "999999999 + 1")

    assert result[:success]
    assert_equal 1000000000.0, result[:result]
  end

  def test_very_small_decimals
    result = @tool.execute(expression: "0.0001 + 0.0002", precision: 4)

    assert result[:success]
    assert_equal 0.0003, result[:result]
  end

  def test_whitespace_handling
    result = @tool.execute(expression: "  2  +  2  ")

    assert result[:success]
    assert_equal 4.0, result[:result]
  end
end
