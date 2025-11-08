# CalculatorTool

Safe mathematical calculations without code execution risks using the Dentaku expression parser.

## Overview

The CalculatorTool provides a secure way to evaluate mathematical expressions without the security risks associated with using `eval()` or executing arbitrary code. It uses the [Dentaku](https://github.com/rubysolo/dentaku) gem for safe expression parsing and evaluation.

## Features

- **Safe Expression Evaluation**: Uses Dentaku parser, no arbitrary code execution
- **Basic Arithmetic**: +, -, *, /, %, ^ (power)
- **Mathematical Functions**: sqrt, round, roundup, rounddown, abs
- **Trigonometric Functions**: sin, cos, tan
- **Comparison Operators**: =, <, >, <=, >=, !=
- **Logical Operators**: and, or, not
- **Configurable Precision**: 0-10 decimal places
- **Comprehensive Error Handling**: Parse errors, argument errors, division by zero
- **Result Caching**: Dentaku caching enabled for performance

## Installation

The CalculatorTool requires the `dentaku` gem, which is included in SharedTools dependencies:

```ruby
gem 'shared_tools'
```

## Basic Usage

### Simple Calculations

```ruby
require 'shared_tools'

calculator = SharedTools::Tools::CalculatorTool.new

# Basic arithmetic
result = calculator.execute(expression: "2 + 2")
puts result[:result]  # => 4.0

# With multiplication and division
result = calculator.execute(expression: "(10 * 5) / 2")
puts result[:result]  # => 25.0

# Modulo operation
result = calculator.execute(expression: "17 % 5")
puts result[:result]  # => 2.0
```

### Mathematical Functions

```ruby
# Square root
result = calculator.execute(expression: "sqrt(16)")
puts result[:result]  # => 4.0

# Combined operations
result = calculator.execute(expression: "sqrt(144) * 2 + 10")
puts result[:result]  # => 34.0

# Absolute value
result = calculator.execute(expression: "abs(-42)")
puts result[:result]  # => 42.0

# Rounding
result = calculator.execute(expression: "round(3.14159, 2)")
puts result[:result]  # => 3.14
```

### Trigonometric Functions

```ruby
# Sine
result = calculator.execute(expression: "sin(0)")
puts result[:result]  # => 0.0

# Cosine
result = calculator.execute(expression: "cos(0)")
puts result[:result]  # => 1.0

# Tangent
result = calculator.execute(expression: "tan(0)")
puts result[:result]  # => 0.0
```

## Precision Control

### Setting Decimal Places

```ruby
# Default precision (2 decimal places)
result = calculator.execute(expression: "10 / 3")
puts result[:result]  # => 3.33

# High precision
result = calculator.execute(expression: "10 / 3", precision: 6)
puts result[:result]  # => 3.333333

# No decimal places
result = calculator.execute(expression: "10.7 + 5.3", precision: 0)
puts result[:result]  # => 16.0
```

### Precision Limits

The precision parameter is automatically validated and constrained:

```ruby
# Negative precision adjusted to 0
result = calculator.execute(expression: "10 / 3", precision: -5)
puts result[:precision]  # => 0

# Precision above 10 adjusted to 10
result = calculator.execute(expression: "10 / 3", precision: 20)
puts result[:precision]  # => 10
```

## Error Handling

### Parse Errors

```ruby
# Invalid expression
result = calculator.execute(expression: "2 + + 2")
puts result[:success]     # => false
puts result[:error]       # => "Invalid expression: ..."
puts result[:suggestion]  # => "Try expressions like '2 + 2', ..."
```

### Division by Zero

```ruby
result = calculator.execute(expression: "10 / 0")
puts result[:success]  # => false
puts result[:error]    # => "Division by zero"
```

### Argument Errors

```ruby
# Function with wrong number of arguments
result = calculator.execute(expression: "round()")
puts result[:success]     # => false
puts result[:error]       # => "Invalid arguments: ..."
puts result[:suggestion]  # => "Check that functions have the correct number of arguments"
```

## Response Format

### Successful Response

```ruby
{
  success:    true,
  result:     3.33,           # Formatted result
  expression: "10 / 3",       # Original expression
  precision:  2,              # Used precision
  raw_result: 3.333333...     # Unformatted result
}
```

### Error Response

```ruby
{
  success:    false,
  error:      "Invalid expression: Could not parse expression",
  expression: "2 + + 2",
  suggestion: "Try expressions like '2 + 2', '(10 * 5) / 2', or 'sqrt(16)'"
}
```

## Supported Operations

### Arithmetic Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `+` | Addition | `2 + 2` = 4 |
| `-` | Subtraction | `10 - 3` = 7 |
| `*` | Multiplication | `5 * 4` = 20 |
| `/` | Division | `10 / 2` = 5 |
| `%` | Modulo | `17 % 5` = 2 |
| `^` or `**` | Exponentiation | `2 ^ 3` = 8 |

### Mathematical Functions

| Function | Description | Example |
|----------|-------------|---------|
| `sqrt(x)` | Square root | `sqrt(16)` = 4 |
| `round(x, n)` | Round to n places | `round(3.14159, 2)` = 3.14 |
| `roundup(x)` | Round up | `roundup(3.1)` = 4 |
| `rounddown(x)` | Round down | `rounddown(3.9)` = 3 |
| `abs(x)` | Absolute value | `abs(-5)` = 5 |

### Trigonometric Functions

| Function | Description | Example |
|----------|-------------|---------|
| `sin(x)` | Sine | `sin(0)` = 0 |
| `cos(x)` | Cosine | `cos(0)` = 1 |
| `tan(x)` | Tangent | `tan(0)` = 0 |

### Comparison Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `=` or `==` | Equal | `5 = 5` = true |
| `<` | Less than | `3 < 5` = true |
| `>` | Greater than | `5 > 3` = true |
| `<=` | Less than or equal | `3 <= 3` = true |
| `>=` | Greater than or equal | `5 >= 3` = true |
| `!=` | Not equal | `3 != 5` = true |

### Logical Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `and` | Logical AND | `true and false` = false |
| `or` | Logical OR | `true or false` = true |
| `not` | Logical NOT | `not true` = false |

## Advanced Examples

### Complex Expressions

```ruby
# Financial calculation
result = calculator.execute(
  expression: "round((1000 * 1.05) - (1000 * 0.02), 2)",
  precision: 2
)
puts result[:result]  # => 1030.0

# Distance calculation (Pythagorean theorem)
result = calculator.execute(
  expression: "sqrt((3 ^ 2) + (4 ^ 2))"
)
puts result[:result]  # => 5.0

# Average calculation
result = calculator.execute(
  expression: "(10 + 20 + 30 + 40 + 50) / 5"
)
puts result[:result]  # => 30.0
```

### Boolean Logic

```ruby
# Comparison result
result = calculator.execute(expression: "10 > 5 and 3 < 7")
puts result[:result]  # => true

# Complex conditions
result = calculator.execute(expression: "(10 > 5) and (20 < 30) or (5 = 3)")
puts result[:result]  # => true
```

## Integration with LLM Agents

```ruby
require 'ruby_llm'

agent = RubyLLM::Agent.new(
  tools: [
    SharedTools::Tools::CalculatorTool.new
  ]
)

# Let the LLM use the calculator
response = agent.process("What is the square root of 144 multiplied by 3?")
# The agent will use the calculator tool and return: 36
```

## Configuration

### Custom Logger

```ruby
require 'logger'

custom_logger = Logger.new($stdout)
custom_logger.level = Logger::DEBUG

calculator = SharedTools::Tools::CalculatorTool.new(logger: custom_logger)
```

## Performance Considerations

- **Caching**: Dentaku caching is enabled for repeated expressions
- **Expression Complexity**: Complex expressions with many operations may take longer
- **Precision**: Higher precision values may slightly impact performance

## Security

The CalculatorTool is designed with security in mind:

- ✅ No `eval()` or code execution
- ✅ Expression parsing only
- ✅ No access to Ruby methods or constants
- ✅ Safe for untrusted input
- ✅ No file system or network access

## Limitations

- **Variables**: Does not support variable assignments (use expression evaluation only)
- **Custom Functions**: Limited to built-in Dentaku functions
- **Precision**: Maximum precision is 10 decimal places
- **Expression Length**: Extremely long expressions may impact performance

## Troubleshooting

### Expression Not Parsing

**Problem**: Expression returns parse error

**Solution**: Check for balanced parentheses, valid operators, and correct function syntax

```ruby
# Bad
"2 + + 2"
"sqrt(16"

# Good
"2 + 2"
"sqrt(16)"
```

### Unexpected Results

**Problem**: Result doesn't match expectations

**Solution**: Check operator precedence and use parentheses for clarity

```ruby
# May be ambiguous
"10 + 5 * 2"  # => 20 (multiplication first)

# Clear intention
"(10 + 5) * 2"  # => 30
```

## Related Tools

- [EvalTool](eval.md) - For executing Ruby/Python code (more powerful but less safe)
- [CompositeAnalysisTool](index.md) - For data analysis with calculations

## References

- [Dentaku GitHub Repository](https://github.com/rubysolo/dentaku)
- [Dentaku Documentation](https://github.com/rubysolo/dentaku/wiki)
