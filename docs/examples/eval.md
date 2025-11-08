# Eval Tool Example

The EvalTool provides a unified interface for evaluating Ruby code, Python code, and shell commands safely with user authorization.

## Overview

This example demonstrates how to use the EvalTool facade to execute code in different languages. The tool includes built-in safety features with user authorization (which can be bypassed for automation).

## Example Code

View the complete example: [eval_tool_example.rb](https://github.com/madbomber/shared_tools/blob/main/examples/eval_tool_example.rb)

## Key Features

### 1. Ruby Code Evaluation

Execute Ruby code and get results:

```ruby
eval_tool = SharedTools::Tools::EvalTool.new

result = eval_tool.execute(
  action: SharedTools::Tools::EvalTool::Action::RUBY,
  code: "2 + 2"
)

puts "Result: #{result[:result]}"    # 4
puts "Success: #{result[:success]}"  # true
```

Ruby code with console output:

```ruby
result = eval_tool.execute(
  action: SharedTools::Tools::EvalTool::Action::RUBY,
  code: "puts 'Hello from Ruby!'; 42"
)

puts "Display:\n#{result[:display]}"  # Shows console output
```

Multi-line Ruby code:

```ruby
code = <<~RUBY
  x = 10
  y = 20
  x * y
RUBY

result = eval_tool.execute(
  action: SharedTools::Tools::EvalTool::Action::RUBY,
  code: code
)

puts "Result: #{result[:result]}"  # 200
```

### 2. Python Code Evaluation

Execute Python code (requires python3):

```ruby
result = eval_tool.execute(
  action: SharedTools::Tools::EvalTool::Action::PYTHON,
  code: "2 ** 10"
)

puts "Result: #{result[:result]}"       # 1024
puts "Python Type: #{result[:python_type]}"  # int
```

Python with imports:

```ruby
python_code = <<~PYTHON
  import math
  math.sqrt(16) + math.pi
PYTHON

result = eval_tool.execute(
  action: SharedTools::Tools::EvalTool::Action::PYTHON,
  code: python_code
)

puts "Result: #{result[:result]}"  # ~7.14
```

### 3. Shell Command Execution

Execute shell commands:

```ruby
result = eval_tool.execute(
  action: SharedTools::Tools::EvalTool::Action::SHELL,
  command: "echo 'Hello from Shell!'"
)

puts "Output: #{result[:stdout].strip}"
puts "Exit Status: #{result[:exit_status]}"
```

Shell commands with pipes:

```ruby
result = eval_tool.execute(
  action: SharedTools::Tools::EvalTool::Action::SHELL,
  command: "echo 'apple\nbanana\ncherry' | grep 'ban'"
)

puts "Output: #{result[:stdout].strip}"  # banana
```

## Authorization Control

By default, EvalTool requires user authorization for each execution. For automation, you can enable auto-execution:

```ruby
# Enable auto-execution (bypass authorization prompts)
SharedTools.auto_execute(true)

# Your code here

# Restore default authorization behavior
SharedTools.auto_execute(false)
```

**Important:** Always use `auto_execute(false)` in production for security.

## Error Handling

The tool gracefully handles errors:

```ruby
result = eval_tool.execute(
  action: SharedTools::Tools::EvalTool::Action::RUBY,
  code: "1 / 0"
)

puts "Success: #{result[:success]}"  # false
puts "Error: #{result[:error]}"      # divided by 0 (ZeroDivisionError)
```

## Using Individual Tools Directly

You can also use individual eval tools directly for more control:

```ruby
ruby_tool = SharedTools::Tools::Eval::RubyEvalTool.new
result = ruby_tool.execute(code: "'Direct tool call'.upcase")

puts "Result: #{result[:result]}"  # DIRECT TOOL CALL
```

## Practical Example - Calculator

```ruby
expressions = [
  "10 + 5",
  "20 - 8",
  "6 * 7",
  "100 / 4"
]

expressions.each do |expr|
  result = eval_tool.execute(
    action: SharedTools::Tools::EvalTool::Action::RUBY,
    code: expr
  )
  puts "#{expr} = #{result[:result]}"
end

# Output:
# 10 + 5 = 15
# 20 - 8 = 12
# 6 * 7 = 42
# 100 / 4 = 25
```

## Available Actions

- `RUBY` - Evaluate Ruby code
- `PYTHON` - Evaluate Python code (requires python3)
- `SHELL` - Execute shell commands

## Result Structure

### Ruby Results
```ruby
{
  success: true/false,
  result: <evaluated result>,
  display: <console output>,
  error: <error message if failed>
}
```

### Python Results
```ruby
{
  success: true/false,
  result: <evaluated result>,
  python_type: <type name>,
  display: <console output>,
  error: <error message if failed>
}
```

### Shell Results
```ruby
{
  success: true/false,
  stdout: <standard output>,
  stderr: <standard error>,
  exit_status: <exit code>
}
```

## Run the Example

```bash
cd examples
bundle exec ruby eval_tool_example.rb
```

The example demonstrates various code evaluation scenarios with auto-execution enabled for demonstration purposes.

## Related Documentation

- [EvalTool Documentation](../tools/eval.md)
- [Authorization System](../guides/authorization.md)
- [Facade Pattern](../api/facade-pattern.md)

## Security Notes

- Always use authorization in production (`auto_execute(false)`)
- Shell commands can be dangerous - validate inputs
- Python execution requires python3 to be installed
- Ruby code is evaluated in the current process context
- Each execution type has built-in error handling

## Key Takeaways

- EvalTool provides a unified interface for Ruby, Python, and Shell execution
- Each execution type has built-in safety with user authorization (when enabled)
- Results include success status, output, and error information
- Individual tools can be used directly for more control
- Always use `auto_execute(false)` in production for security
