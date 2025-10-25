# EvalTool

Execute code in multiple languages (Ruby, Python, Shell) with authorization controls for security.

## Installation

EvalTool is included with SharedTools:

```ruby
gem 'shared_tools'
```

For Python evaluation, you need Python 3 installed:

```bash
# macOS
brew install python3

# Ubuntu/Debian
apt-get install python3
```

## Basic Usage

```ruby
require 'shared_tools'

eval_tool = SharedTools::Tools::EvalTool.new

# Execute Ruby code
result = eval_tool.execute(action: "ruby", code: "2 + 2")
puts result  # => 4

# Execute Python code
result = eval_tool.execute(
  action: "python",
  code: "print('Hello from Python')"
)

# Execute shell command
result = eval_tool.execute(action: "shell", command: "echo 'Hello'")
```

## Authorization System

!!!warning "Security Notice"
    EvalTool executes arbitrary code. By default, all operations require user authorization.

```ruby
# Default behavior: prompts for confirmation
eval_tool = SharedTools::Tools::EvalTool.new
eval_tool.execute(action: "shell", command: "rm file.txt")

# Output:
# The AI (tool: eval_tool) wants to do the following ...
# ==========================================
# rm file.txt
# ==========================================
# Is it okay to proceed? (y/N)
```

Disable authorization for automated scripts (use with caution):

```ruby
SharedTools.auto_execute(true)

# Now executes without prompting
eval_tool.execute(action: "shell", command: "ls -la")
```

## Actions

### ruby

Execute Ruby code and return the result.

**Parameters:**

- `action`: "ruby"
- `code`: Ruby code to execute

**Examples:**

```ruby
# Simple calculation
result = eval_tool.execute(
  action: "ruby",
  code: "[1, 2, 3, 4, 5].sum"
)
puts result  # => 15

# String manipulation
result = eval_tool.execute(
  action: "ruby",
  code: "'hello world'.upcase.reverse"
)
puts result  # => "DLROW OLLEH"

# Data processing
result = eval_tool.execute(
  action: "ruby",
  code: <<~RUBY
    data = [1, 2, 3, 4, 5]
    data.map { |n| n * 2 }.select { |n| n > 5 }
  RUBY
)
puts result  # => [6, 8, 10]
```

---

### python

Execute Python code and return the output.

**Parameters:**

- `action`: "python"
- `code`: Python code to execute

**Examples:**

```ruby
# Print statement
result = eval_tool.execute(
  action: "python",
  code: "print('Hello from Python')"
)

# Mathematical operations
result = eval_tool.execute(
  action: "python",
  code: "import math; print(math.pi * 2)"
)

# Data processing
result = eval_tool.execute(
  action: "python",
  code: <<~PYTHON
    import json
    data = {'name': 'SharedTools', 'version': '0.5.1'}
    print(json.dumps(data, indent=2))
  PYTHON
)
```

---

### shell

Execute shell commands and return the output.

**Parameters:**

- `action`: "shell"
- `command`: Shell command to execute

**Examples:**

```ruby
# List files
result = eval_tool.execute(
  action: "shell",
  command: "ls -la"
)

# System information
result = eval_tool.execute(
  action: "shell",
  command: "uname -a"
)

# File operations
result = eval_tool.execute(
  action: "shell",
  command: "wc -l *.rb"
)

# Piped commands
result = eval_tool.execute(
  action: "shell",
  command: "ps aux | grep ruby"
)
```

## Complete Examples

### Example 1: Data Processing Pipeline

```ruby
require 'shared_tools'

eval_tool = SharedTools::Tools::EvalTool.new

# 1. Generate data with Ruby
data = eval_tool.execute(
  action: "ruby",
  code: "(1..10).map { |n| {id: n, value: rand(100)} }"
)

puts "Generated data: #{data}"

# 2. Process with Python
json_data = data.to_json
result = eval_tool.execute(
  action: "python",
  code: <<~PYTHON
    import json
    data = json.loads('#{json_data}')
    total = sum(item['value'] for item in data)
    print(f"Total: {total}")
  PYTHON
)

puts "Python result: #{result}"

# 3. Save with shell
eval_tool.execute(
  action: "shell",
  command: "echo '#{data}' > output.json"
)
```

### Example 2: System Monitoring

```ruby
require 'shared_tools'

eval_tool = SharedTools::Tools::EvalTool.new
SharedTools.auto_execute(true)  # Disable prompts for automation

# Collect system metrics
metrics = {}

# CPU info
metrics[:cpu] = eval_tool.execute(
  action: "shell",
  command: "top -l 1 | grep 'CPU usage'"
)

# Memory info
metrics[:memory] = eval_tool.execute(
  action: "shell",
  command: "vm_stat"
)

# Disk usage
metrics[:disk] = eval_tool.execute(
  action: "shell",
  command: "df -h"
)

# Process Ruby metrics
report = eval_tool.execute(
  action: "ruby",
  code: <<~RUBY
    metrics = #{metrics.inspect}
    report = "System Report\\n"
    report += "=" * 40 + "\\n"
    metrics.each do |key, value|
      report += "\\n#{key.upcase}:\\n#{value}\\n"
    end
    report
  RUBY
)

puts report
```

### Example 3: Code Testing

```ruby
require 'shared_tools'

eval_tool = SharedTools::Tools::EvalTool.new

# Test Ruby code
tests = [
  { code: "2 + 2", expected: 4 },
  { code: "'hello'.upcase", expected: "HELLO" },
  { code: "[1,2,3].sum", expected: 6 }
]

results = tests.map do |test|
  result = eval_tool.execute(action: "ruby", code: test[:code])
  {
    code: test[:code],
    expected: test[:expected],
    actual: result,
    passed: result == test[:expected]
  }
end

# Print results
results.each do |r|
  status = r[:passed] ? "PASS" : "FAIL"
  puts "[#{status}] #{r[:code]} => #{r[:actual]}"
end
```

### Example 4: File Analysis

```ruby
require 'shared_tools'

eval_tool = SharedTools::Tools::EvalTool.new
SharedTools.auto_execute(true)

# Count lines in Ruby files
line_count = eval_tool.execute(
  action: "shell",
  command: "find . -name '*.rb' | xargs wc -l | tail -1"
)

# Find large files
large_files = eval_tool.execute(
  action: "shell",
  command: "find . -type f -size +1M"
)

# Analyze with Ruby
analysis = eval_tool.execute(
  action: "ruby",
  code: <<~RUBY
    total_lines = "#{line_count}".split.first.to_i
    large_count = "#{large_files}".lines.count

    "Analysis:\\n" +
    "  Total lines: #{total_lines}\\n" +
    "  Large files: #{large_count}"
  RUBY
)

puts analysis
```

## Error Handling

```ruby
eval_tool = SharedTools::Tools::EvalTool.new

# Handle Ruby syntax errors
begin
  eval_tool.execute(action: "ruby", code: "invalid syntax {")
rescue StandardError => e
  puts "Ruby error: #{e.message}"
end

# Handle Python errors
begin
  eval_tool.execute(action: "python", code: "print(undefined_variable)")
rescue StandardError => e
  puts "Python error: #{e.message}"
end

# Handle shell command errors
begin
  eval_tool.execute(action: "shell", command: "nonexistent-command")
rescue StandardError => e
  puts "Shell error: #{e.message}"
end
```

## Security Best Practices

### 1. Use Authorization for Interactive Scripts

```ruby
# Keep authorization enabled by default
eval_tool = SharedTools::Tools::EvalTool.new

# User approves each operation
eval_tool.execute(action: "shell", command: "rm important_file.txt")
```

### 2. Sanitize User Input

```ruby
# BAD: Direct user input
user_input = gets.chomp
eval_tool.execute(action: "ruby", code: user_input)  # Dangerous!

# GOOD: Validate input
allowed_commands = ["list", "status", "version"]
if allowed_commands.include?(user_input)
  eval_tool.execute(action: "shell", command: user_input)
else
  puts "Invalid command"
end
```

### 3. Use Whitelisting for Commands

```ruby
SAFE_SHELL_COMMANDS = {
  "list" => "ls -la",
  "date" => "date",
  "whoami" => "whoami"
}.freeze

command_key = "list"
if SAFE_SHELL_COMMANDS.key?(command_key)
  eval_tool.execute(action: "shell", command: SAFE_SHELL_COMMANDS[command_key])
end
```

### 4. Limit Execution Time

```ruby
require 'timeout'

begin
  Timeout.timeout(5) do
    eval_tool.execute(
      action: "ruby",
      code: "sleep 10"  # Will timeout after 5 seconds
    )
  end
rescue Timeout::Error
  puts "Execution timed out"
end
```

### 5. Sandbox Ruby Code

```ruby
# Use a separate process for untrusted code
code = "potentially_dangerous_code"

result = eval_tool.execute(
  action: "ruby",
  code: <<~RUBY
    require 'open3'
    stdout, stderr, status = Open3.capture3("ruby", "-e", #{code.inspect})
    stdout
  RUBY
)
```

## Troubleshooting

### Python Not Found

```
Error: python3: command not found
```

**Solution:** Install Python 3:

```bash
# macOS
brew install python3

# Ubuntu/Debian
apt-get install python3
```

### Shell Command Fails

```
Error: command not found
```

**Solution:** Check if command exists:

```ruby
# Check if command exists
result = eval_tool.execute(
  action: "shell",
  command: "which some-command"
)

if result.empty?
  puts "Command not found"
else
  # Run command
end
```

### Ruby Syntax Error

```
Error: syntax error, unexpected ...
```

**Solution:** Validate Ruby code before execution:

```ruby
code = "puts 'hello"  # Invalid syntax

begin
  RubyVM::InstructionSequence.compile(code)
  # Code is valid
  eval_tool.execute(action: "ruby", code: code)
rescue SyntaxError => e
  puts "Invalid Ruby syntax: #{e.message}"
end
```

## Performance Tips

### 1. Minimize Shell Invocations

```ruby
# Less efficient: Multiple shell calls
result1 = eval_tool.execute(action: "shell", command: "ls")
result2 = eval_tool.execute(action: "shell", command: "pwd")

# More efficient: Single shell call
result = eval_tool.execute(
  action: "shell",
  command: "ls && pwd"
)
```

### 2. Use Ruby for Complex Logic

```ruby
# Instead of complex shell scripting
result = eval_tool.execute(
  action: "ruby",
  code: <<~RUBY
    Dir.glob("*.rb").select { |f| File.size(f) > 1000 }
  RUBY
)
```

### 3. Cache Results

```ruby
# Cache expensive operations
@system_info ||= eval_tool.execute(
  action: "shell",
  command: "uname -a"
)
```

## See Also

- [Authorization Guide](../guides/authorization.md) - Control operation approval
- [Basic Usage](../getting-started/basic-usage.md) - Common patterns
- [Examples](https://github.com/madbomber/shared_tools/tree/main/examples/eval_tool_example.rb)
