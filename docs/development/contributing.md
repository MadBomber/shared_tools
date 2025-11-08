# Contributing to SharedTools

Thank you for your interest in contributing to SharedTools! This guide will help you get started.

## Code of Conduct

Be respectful, inclusive, and professional. We're all here to build great tools for the Ruby LLM community.

## Ways to Contribute

- Report bugs and issues
- Suggest new features or tools
- Improve documentation
- Fix bugs
- Add new tools
- Improve existing tools
- Write examples
- Review pull requests

## Getting Started

### 1. Fork and Clone

```bash
# Fork on GitHub, then:
git clone https://github.com/YOUR_USERNAME/shared_tools.git
cd shared_tools
```

### 2. Set Up Development Environment

```bash
# Install dependencies
bundle install

# Run tests to verify setup
bundle exec rspec

# All tests should pass
```

### 3. Create a Branch

```bash
# For new features
git checkout -b feature/tool-name

# For bug fixes
git checkout -b fix/issue-description

# For documentation
git checkout -b docs/what-you-are-documenting
```

## Development Process

### Writing Code

#### 1. Follow Ruby Style Guide

```ruby
# Good
def execute(action:, path:)
  validate_params!(action, path)
  perform_action(action, path)
end

# Bad
def execute(action:,path:)
    ValidateParams!(action,path)
    PerformAction(action,path)
end
```

#### 2. Use Consistent Naming

```ruby
# Class names: CamelCase
class BrowserTool < ::RubyLLM::Tool
end

# Method names: snake_case
def execute_action
end

# Constants: SCREAMING_SNAKE_CASE
MODULE_VERSION = "1.0.0"

# Action constants: SCREAMING_SNAKE_CASE
module Action
  VISIT = "visit"
end
```

#### 3. Add YARD Documentation

```ruby
# Describe what the method does
#
# @param action [String] the action to perform
# @param path [String] file or directory path
#
# @return [String] result message
#
# @raise [ArgumentError] if action is invalid
#
# @example
#   tool.execute(action: "read", path: "./file.txt")
def execute(action:, path:)
  # ...
end
```

### Writing Tests

#### Test Structure

```ruby
RSpec.describe SharedTools::Tools::MyTool do
  # Use let for test data
  let(:tool) { described_class.new }
  let(:mock_driver) { instance_double(Driver) }

  # Group related tests
  describe "#execute" do
    context "when action is valid" do
      it "performs the action" do
        result = tool.execute(action: "test")
        expect(result).to eq("expected")
      end
    end

    context "when action is invalid" do
      it "raises ArgumentError" do
        expect {
          tool.execute(action: "invalid")
        }.to raise_error(ArgumentError, /Unknown action/)
      end
    end
  end

  describe "parameter validation" do
    it "requires action parameter" do
      expect {
        tool.execute
      }.to raise_error(ArgumentError)
    end
  end
end
```

#### Test Coverage

- Aim for 80%+ coverage (enforced by SimpleCov)
- Test happy paths
- Test error cases
- Test edge cases
- Test parameter validation

#### Running Tests

```bash
# All tests
bundle exec rspec

# Specific file
bundle exec rspec spec/shared_tools/tools/my_tool_spec.rb

# Specific test
bundle exec rspec spec/shared_tools/tools/my_tool_spec.rb:23

# With coverage
COVERAGE=true bundle exec rspec

# Watch mode (if guard is installed)
bundle exec guard
```

### Code Quality

#### Run Rubocop

```bash
# Check style
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a

# Check specific files
bundle exec rubocop lib/shared_tools/tools/my_tool.rb
```

#### Common Rubocop Issues

```ruby
# Line too long - split it
long_method_call(param1, param2, param3)
# →
long_method_call(
  param1,
  param2,
  param3
)

# Missing frozen_string_literal
# Add to top of file:
# frozen_string_literal: true

# Trailing whitespace - remove it
puts "hello"   # ← remove these spaces

# Missing documentation - add YARD comments
```

## Pull Request Process

### 1. Ensure Tests Pass

```bash
bundle exec rspec
bundle exec rubocop
```

### 2. Update Documentation

- Add/update YARD comments
- Update relevant markdown docs
- Add examples if appropriate

### 3. Write Good Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Format
<type>: <subject>

<body>

<footer>

# Types
feat: new feature
fix: bug fix
docs: documentation only
test: adding tests
refactor: code refactoring
chore: maintenance

# Examples
feat: add DatabaseTool for SQL execution

Add new DatabaseTool that supports multiple database backends
through a driver interface. Includes SqliteDriver and PostgresDriver.

Closes #42

---

fix: handle nil driver in BrowserTool

Previously would raise NoMethodError when driver was nil.
Now raises ArgumentError with helpful message.

---

docs: add architecture documentation

Add comprehensive architecture guide covering design patterns,
component interaction, and extensibility points.
```

### 4. Create Pull Request

1. Push your branch
```bash
git push origin feature/my-feature
```

2. Go to GitHub and create PR

3. Fill out PR template:
```markdown
## Description
Clear description of what this PR does

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring

## Testing
- [ ] Added tests for new functionality
- [ ] All tests pass
- [ ] Updated documentation

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed code
- [ ] Commented complex code
- [ ] Updated documentation
- [ ] No new warnings
- [ ] Added tests
- [ ] All tests pass
```

4. Request review

### 5. Address Review Comments

- Be receptive to feedback
- Ask questions if unclear
- Make requested changes
- Update PR description if scope changes

### 6. Merge

Once approved:
- Squash commits if requested
- Maintainer will merge

## Adding a New Tool

### Step-by-Step Guide

#### 1. Plan the Tool

Consider:
- What problem does it solve?
- What actions will it support?
- Does it need a driver?
- What are the parameters?

#### 2. Create Tool File

```ruby
# lib/shared_tools/tools/my_tool.rb
# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  module Tools
    class MyTool < ::RubyLLM::Tool
      def self.name = 'my_tool'

      description <<~TEXT
        Brief description of what this tool does.

        ## Actions
        - `action1`: What this action does
        - `action2`: What this action does

        ## Usage
        {"action": "action1", "param": "value"}
      TEXT

      param :action, desc: "The action to perform (action1, action2)"
      param :required_param, desc: "Required parameter"
      param :optional_param, desc: "Optional parameter (default: value)"

      def initialize(driver: nil, logger: nil)
        @driver = driver
        @logger = logger || RubyLLM.logger
      end

      def execute(action:, required_param:, optional_param: 'default')
        @logger&.info("Executing #{action}")

        case action
        when "action1"
          perform_action1(required_param)
        when "action2"
          perform_action2(required_param, optional_param)
        else
          raise ArgumentError, "Unknown action: #{action}"
        end
      end

      private

      def perform_action1(param)
        # Implementation
      end

      def perform_action2(param, optional)
        # Implementation
      end
    end
  end
end
```

#### 3. Create Tests

```ruby
# spec/shared_tools/tools/my_tool_spec.rb
require 'spec_helper'

RSpec.describe SharedTools::Tools::MyTool do
  let(:tool) { described_class.new }

  describe ".name" do
    it "returns tool name" do
      expect(described_class.name).to eq('my_tool')
    end
  end

  describe "#execute" do
    context "with action1" do
      it "performs action1" do
        result = tool.execute(
          action: "action1",
          required_param: "value"
        )
        expect(result).to be_truthy
      end
    end

    context "with invalid action" do
      it "raises ArgumentError" do
        expect {
          tool.execute(action: "invalid", required_param: "value")
        }.to raise_error(ArgumentError, /Unknown action/)
      end
    end

    context "with missing required parameter" do
      it "raises ArgumentError" do
        expect {
          tool.execute(action: "action1")
        }.to raise_error(ArgumentError)
      end
    end
  end
end
```

#### 4. Create Example

```ruby
# examples/my_tool_example.rb
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'shared_tools'

puts "=" * 80
puts "MyTool Example"
puts "=" * 80
puts

# Initialize tool
tool = SharedTools::Tools::MyTool.new

# Example 1: Action 1
puts "Example 1: Action 1"
result = tool.execute(
  action: "action1",
  required_param: "test"
)
puts "Result: #{result}"
puts

# Example 2: Action 2
puts "Example 2: Action 2"
result = tool.execute(
  action: "action2",
  required_param: "test",
  optional_param: "custom"
)
puts "Result: #{result}"
puts

puts "=" * 80
puts "Example completed!"
puts "=" * 80
```

#### 5. Document the Tool

```markdown
# docs/tools/my-tool.md
# MyTool

Brief description.

## Actions

### action1
Description of action1

**Parameters:**
- `action`: "action1"
- `required_param`: Description

**Example:**
```ruby
tool.execute(action: "action1", required_param: "value")
```

### action2
Description of action2

**Parameters:**
- `action`: "action2"
- `required_param`: Description
- `optional_param`: Description (optional)

**Example:**
```ruby
tool.execute(action: "action2", required_param: "value", optional_param: "custom")
```
```

#### 6. Update API Index

Add your tool to `docs/api/index.md`:

```markdown
| [MyTool](../tools/my-tool.md) | Description | Driver | Use case |
```

## Adding a Driver

### 1. Create Driver File

```ruby
# lib/shared_tools/tools/my_system/my_driver.rb
module SharedTools
  module Tools
    module MySystem
      class MyDriver < BaseDriver
        def initialize(config:)
          @config = config
        end

        def perform_action(params:)
          # Implementation
        end

        # Implement all BaseDriver methods
      end
    end
  end
end
```

### 2. Add Driver Tests

```ruby
RSpec.describe SharedTools::Tools::MySystem::MyDriver do
  let(:driver) { described_class.new(config: test_config) }

  describe "#perform_action" do
    it "performs the action" do
      result = driver.perform_action(params: { key: "value" })
      expect(result).to be_truthy
    end
  end
end
```

## Documentation Standards

### Code Comments

```ruby
# Brief description of class
#
# @example
#   tool = MyTool.new
#   tool.execute(action: "test")
class MyTool < ::RubyLLM::Tool
  # Brief description of method
  #
  # @param action [String] description
  # @return [String] description
  # @raise [ArgumentError] when action is invalid
  def execute(action:)
    # ...
  end
end
```

### Markdown Documentation

- Use clear headings
- Include code examples
- Link related pages
- Keep line length reasonable
- Use proper formatting

## Release Process

Maintainers only:

1. Update version in `lib/shared_tools/tools/version.rb`
2. Update `CHANGELOG.md`
3. Commit: `git commit -am "chore: bump version to X.Y.Z"`
4. Tag: `git tag vX.Y.Z`
5. Push: `git push && git push --tags`
6. Build: `gem build shared_tools.gemspec`
7. Publish: `gem push shared_tools-X.Y.Z.gem`

## Getting Help

- **Questions**: Open a GitHub Discussion
- **Bugs**: Create an issue with reproducible example
- **Features**: Create an issue with use case explanation
- **PRs**: Tag maintainers for review

## Recognition

Contributors are recognized in:
- README.md contributors section
- CHANGELOG.md release notes
- Git history

Thank you for contributing to SharedTools!
