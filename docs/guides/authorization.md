# Authorization System

SharedTools includes a built-in authorization system that provides human-in-the-loop confirmation for potentially dangerous operations.

## Overview

The authorization system is designed to prevent unintended or dangerous operations by requiring user confirmation before execution. This is particularly important when:

- Executing arbitrary code
- Deleting files or directories
- Running shell commands
- Modifying system state

## How It Works

The authorization system is controlled by the `SharedTools.execute?` method:

```ruby
SharedTools.execute?(tool: 'tool_name', stuff: 'operation description')
```

This method:

1. Checks if auto-execute mode is enabled
2. If not, displays what the AI wants to do
3. Prompts the user for confirmation
4. Returns `true` if approved, `false` otherwise

## Default Behavior

By default, SharedTools operates in **safe mode** with authorization enabled:

```ruby
eval_tool = SharedTools::Tools::EvalTool.new

# This prompts for confirmation
eval_tool.execute(action: "shell", command: "rm important_file.txt")

# Output:
# The AI (tool: eval_tool) wants to do the following ...
# ==========================================
# rm important_file.txt
# ==========================================
#
# Is it okay to proceed? (y/N)
```

User must press `y` to proceed. Any other key cancels the operation.

## Disabling Authorization

For automated scripts or trusted environments, you can disable authorization:

```ruby
# Disable authorization (enable auto-execute)
SharedTools.auto_execute(true)

# Now operations run without prompting
eval_tool.execute(action: "shell", command: "echo 'Hello'")

# Re-enable authorization when done
SharedTools.auto_execute(false)
```

## Which Tools Use Authorization?

Currently, the **EvalTool** uses authorization for all actions:

- `ruby` - Executing Ruby code
- `python` - Executing Python code
- `shell` - Running shell commands

Other tools (BrowserTool, DiskTool, DocTool, DatabaseTool) do not currently use authorization, but operate with built-in safety features like path traversal protection.

## Usage Patterns

### Pattern 1: Interactive Scripts

For scripts that interact with users, keep authorization enabled:

```ruby
#!/usr/bin/env ruby
require 'shared_tools'

eval_tool = SharedTools::Tools::EvalTool.new

# Authorization enabled by default
puts "This script will delete temporary files."

# User approves each deletion
eval_tool.execute(action: "shell", command: "rm /tmp/*.tmp")
```

### Pattern 2: Automated Scripts

For background jobs or CI/CD, disable authorization:

```ruby
#!/usr/bin/env ruby
require 'shared_tools'

# Disable authorization for automation
SharedTools.auto_execute(true)

eval_tool = SharedTools::Tools::EvalTool.new

# Runs without prompting
eval_tool.execute(action: "shell", command: "npm run build")
eval_tool.execute(action: "shell", command: "npm test")
```

### Pattern 3: Conditional Authorization

Enable authorization only for dangerous operations:

```ruby
require 'shared_tools'

eval_tool = SharedTools::Tools::EvalTool.new

# Safe operations: disable authorization
SharedTools.auto_execute(true)
eval_tool.execute(action: "ruby", code: "Time.now")
eval_tool.execute(action: "shell", command: "ls -la")

# Dangerous operations: enable authorization
SharedTools.auto_execute(false)
eval_tool.execute(action: "shell", command: "rm -rf /tmp/*")
```

### Pattern 4: Environment-Based

Use environment variables to control authorization:

```ruby
require 'shared_tools'

# Enable auto-execute in CI/CD environments
ci_environment = ENV['CI'] == 'true' || ENV['AUTOMATED'] == 'true'
SharedTools.auto_execute(ci_environment)

eval_tool = SharedTools::Tools::EvalTool.new

# Behavior depends on environment
eval_tool.execute(action: "shell", command: "deploy.sh")
```

## Complete Examples

### Example 1: File Cleanup Script

```ruby
#!/usr/bin/env ruby
require 'shared_tools'

eval_tool = SharedTools::Tools::EvalTool.new

# Keep authorization for file deletions
puts "Cleaning up temporary files..."

# User must approve each deletion
temp_dirs = ['/tmp', '/var/tmp', '~/.cache']

temp_dirs.each do |dir|
  puts "\nClearing #{dir}..."
  eval_tool.execute(
    action: "shell",
    command: "find #{dir} -type f -name '*.tmp' -delete"
  )
end

puts "\nCleanup complete!"
```

### Example 2: Deployment Script

```ruby
#!/usr/bin/env ruby
require 'shared_tools'

# Check if running in automated environment
if ARGV.include?('--auto')
  puts "Running in automated mode"
  SharedTools.auto_execute(true)
else
  puts "Running in interactive mode"
  puts "You will be prompted to approve each step"
end

eval_tool = SharedTools::Tools::EvalTool.new

# Deployment steps
steps = [
  { name: "Pull latest code", cmd: "git pull origin main" },
  { name: "Install dependencies", cmd: "bundle install" },
  { name: "Run migrations", cmd: "rake db:migrate" },
  { name: "Precompile assets", cmd: "rake assets:precompile" },
  { name: "Restart server", cmd: "systemctl restart app" }
]

steps.each do |step|
  puts "\n#{step[:name]}..."
  eval_tool.execute(action: "shell", command: step[:cmd])
end

puts "\nDeployment complete!"
```

### Example 3: Data Processing with Selective Authorization

```ruby
#!/usr/bin/env ruby
require 'shared_tools'

eval_tool = SharedTools::Tools::EvalTool.new
disk = SharedTools::Tools::DiskTool.new

# Phase 1: Data collection (no authorization needed)
SharedTools.auto_execute(true)

puts "Collecting data..."
data = eval_tool.execute(
  action: "ruby",
  code: "Dir.glob('data/*.csv').map { |f| File.read(f) }"
)

# Phase 2: Data processing (no authorization needed)
puts "Processing data..."
results = eval_tool.execute(
  action: "ruby",
  code: "process_data(#{data.inspect})"
)

# Phase 3: Data deletion (requires authorization)
SharedTools.auto_execute(false)

puts "\nProcessing complete. Ready to clean up."
eval_tool.execute(
  action: "shell",
  command: "rm -rf data/processed/*"
)
```

### Example 4: Testing Framework

```ruby
require 'shared_tools'

class TestRunner
  def initialize(auto_approve: false)
    @eval_tool = SharedTools::Tools::EvalTool.new
    SharedTools.auto_execute(auto_approve)
  end

  def run_tests(test_files)
    results = []

    test_files.each do |file|
      puts "Running #{file}..."

      result = @eval_tool.execute(
        action: "shell",
        command: "ruby #{file}"
      )

      results << {
        file: file,
        passed: $?.success?,
        output: result
      }
    end

    results
  end

  def report(results)
    passed = results.count { |r| r[:passed] }
    total = results.size

    puts "\nTest Results: #{passed}/#{total} passed"

    results.each do |r|
      status = r[:passed] ? "PASS" : "FAIL"
      puts "  [#{status}] #{r[:file]}"
    end
  end
end

# Interactive mode: requires approval for each test
runner = TestRunner.new(auto_approve: false)

# Automated mode: no approval needed
runner = TestRunner.new(auto_approve: true)

results = runner.run_tests(Dir.glob('test/**/*_test.rb'))
runner.report(results)
```

## Security Best Practices

### 1. Default to Authorization Enabled

```ruby
# Good: Authorization enabled by default
eval_tool = SharedTools::Tools::EvalTool.new
eval_tool.execute(action: "shell", command: cmd)

# Avoid: Auto-execute by default
# SharedTools.auto_execute(true)
```

### 2. Use Auto-Execute Sparingly

```ruby
# Good: Limited scope
SharedTools.auto_execute(true)
eval_tool.execute(action: "ruby", code: safe_code)
SharedTools.auto_execute(false)

# Avoid: Global auto-execute
# SharedTools.auto_execute(true)
# # ... rest of script
```

### 3. Validate User Input

```ruby
# Good: Validate before execution
allowed_commands = ['status', 'version', 'help']
if allowed_commands.include?(user_input)
  eval_tool.execute(action: "shell", command: user_input)
else
  puts "Invalid command"
end

# Avoid: Direct execution
# eval_tool.execute(action: "shell", command: user_input)
```

### 4. Use Environment Variables

```ruby
# Good: Check environment
auto = ENV['AUTO_APPROVE'] == 'true'
SharedTools.auto_execute(auto)

# Document in README:
# Set AUTO_APPROVE=true for automated environments
```

### 5. Log Authorization Decisions

```ruby
require 'logger'

logger = Logger.new('./authorization.log')

original_execute = SharedTools.method(:execute?)

SharedTools.define_singleton_method(:execute?) do |tool:, stuff:|
  approved = original_execute.call(tool: tool, stuff: stuff)

  logger.info({
    timestamp: Time.now,
    tool: tool,
    operation: stuff,
    approved: approved
  }.to_json)

  approved
end
```

## Testing with Authorization

### Mock Authorization for Tests

```ruby
require 'minitest/autorun'

class MyTest < Minitest::Test
  def setup
    # Enable auto-execute for tests
    SharedTools.auto_execute(true)
    @eval_tool = SharedTools::Tools::EvalTool.new
  end

  def teardown
    # Reset to default
    SharedTools.auto_execute(false)
  end

  def test_shell_execution
    result = @eval_tool.execute(action: "shell", command: "echo test")
    assert_equal "test\n", result
  end
end
```

### Test Authorization Behavior

```ruby
require 'minitest/autorun'
require 'stringio'

class AuthorizationTest < Minitest::Test
  def test_authorization_prompt
    # Disable auto-execute
    SharedTools.auto_execute(false)

    # Mock STDIN to simulate user input
    input = StringIO.new("y\n")
    $stdin = input

    eval_tool = SharedTools::Tools::EvalTool.new

    # Should succeed with 'y' input
    result = eval_tool.execute(action: "shell", command: "echo test")
    assert_equal "test\n", result

    # Reset
    $stdin = STDIN
  end
end
```

## Troubleshooting

### Authorization Not Working

If operations execute without prompting:

```ruby
# Check current state
puts "Auto-execute: #{SharedTools.instance_variable_get(:@auto_execute)}"

# Reset to default
SharedTools.auto_execute(false)
```

### Can't Run Automated Scripts

If scripts require manual approval in CI/CD:

```bash
# Set environment variable
export AUTO_APPROVE=true

# Or pass flag to script
ruby deploy.rb --auto

# Or modify script
SharedTools.auto_execute(true)
```

### Testing Issues

If tests hang waiting for input:

```ruby
# Always enable auto-execute in tests
class MyTest < Minitest::Test
  def setup
    SharedTools.auto_execute(true)
  end
end
```

## See Also

- [EvalTool Documentation](../tools/eval.md) - Tool that uses authorization
- [Basic Usage](../getting-started/basic-usage.md) - Common patterns
- [Examples](https://github.com/madbomber/shared_tools/tree/main/examples)
