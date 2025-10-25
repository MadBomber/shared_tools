# Development Guide

Welcome to the SharedTools development guide. This section covers everything you need to know to contribute to SharedTools, understand its architecture, and develop new tools.

## Quick Start for Contributors

```bash
# Clone the repository
git clone https://github.com/madbomber/shared_tools.git
cd shared_tools

# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Check test coverage
open coverage/index.html
```

## Documentation Structure

### [Architecture](./architecture.md)

Deep dive into SharedTools architecture:

- Module organization and Zeitwerk autoloading
- Tool hierarchy and inheritance
- Facade pattern implementation
- Driver interface design
- Authorization system
- Framework detection and compatibility

### [Contributing](./contributing.md)

Guidelines for contributing:

- Code style and conventions
- Git workflow and branch strategy
- Pull request process
- Issue reporting
- Adding new tools
- Writing documentation
- Community guidelines

### [Testing](./testing.md)

Comprehensive testing guide:

- Test structure and organization
- Using RSpec effectively
- Mock drivers and fixtures
- Test coverage requirements
- Integration testing
- Testing LLM interactions
- Performance testing

### [Changelog](./changelog.md)

Version history and migration guides:

- Current version: 0.2.1
- Breaking changes
- New features
- Bug fixes
- Deprecations
- Migration guides

## Development Setup

### Prerequisites

- Ruby 3.0 or higher
- Bundler
- Git

### Optional Dependencies

For full functionality, install:

```bash
# Browser automation
gem install watir selenium-webdriver

# Database support
gem install sqlite3 pg

# PDF processing
gem install pdf-reader

# Development tools
gem install rubocop yard
```

### Project Structure

```
shared_tools/
├── lib/
│   └── shared_tools/
│       ├── tools/          # Tool implementations
│       │   ├── browser/    # Browser sub-tools
│       │   ├── database/   # Database drivers
│       │   ├── disk/       # Disk drivers
│       │   ├── computer/   # Computer drivers
│       │   ├── eval/       # Eval sub-tools
│       │   └── doc/        # Doc sub-tools
│       └── shared_tools.rb # Main module
├── examples/               # Usage examples
├── test/                   # Test files
└── docs/                   # Documentation
```

### Key Files

- `lib/shared_tools.rb`: Main module with authorization system
- `lib/shared_tools/tools/browser_tool.rb`: BrowserTool facade
- `lib/shared_tools/tools/disk_tool.rb`: DiskTool facade
- `lib/shared_tools/tools/database_tool.rb`: DatabaseTool facade
- `shared_tools.gemspec`: Gem specification

## Development Workflow

### 1. Pick an Issue or Feature

- Check GitHub issues for open items
- Comment on the issue to claim it
- Or create a new issue to discuss your idea

### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/bug-description
```

### 3. Develop with TDD

Write tests first:

```ruby
# spec/shared_tools/tools/my_new_tool_spec.rb
RSpec.describe SharedTools::Tools::MyNewTool do
  describe "#execute" do
    it "performs the action" do
      tool = described_class.new
      result = tool.execute(action: "test")
      expect(result).to eq("expected")
    end
  end
end
```

Then implement:

```ruby
# lib/shared_tools/tools/my_new_tool.rb
module SharedTools
  module Tools
    class MyNewTool < ::RubyLLM::Tool
      def self.name = 'my_new_tool'

      description "Tool description"

      param :action, desc: "Action to perform"

      def execute(action:)
        # Implementation
      end
    end
  end
end
```

### 4. Run Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test
bundle exec rspec spec/shared_tools/tools/my_new_tool_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

### 5. Check Code Style

```bash
# Run Rubocop
bundle exec rubocop

# Auto-fix issues
bundle exec rubocop -a
```

### 6. Update Documentation

- Add/update YARD comments in code
- Update relevant markdown documentation
- Add examples if applicable

### 7. Commit Changes

```bash
git add .
git commit -m "feat: add MyNewTool for XYZ functionality"
```

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `test:` Adding tests
- `refactor:` Code refactoring
- `chore:` Maintenance tasks

### 8. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

## Adding a New Tool

### Step-by-Step Guide

1. **Create the tool file**:

```ruby
# lib/shared_tools/tools/my_tool.rb
module SharedTools
  module Tools
    class MyTool < ::RubyLLM::Tool
      def self.name = 'my_tool'

      description <<~TEXT
        What this tool does.

        ## Usage
        - Example usage
      TEXT

      param :action, desc: "Action to perform"
      param :required_param, desc: "Required parameter"
      param :optional_param, desc: "Optional parameter"

      def initialize(driver: nil, logger: nil)
        @driver = driver
        @logger = logger || RubyLLM.logger
      end

      def execute(action:, required_param:, optional_param: nil)
        @logger&.info("Executing #{action}")
        # Implementation
      end
    end
  end
end
```

2. **Create tests**:

```ruby
# spec/shared_tools/tools/my_tool_spec.rb
require 'spec_helper'

RSpec.describe SharedTools::Tools::MyTool do
  let(:tool) { described_class.new }

  describe "#execute" do
    it "works" do
      result = tool.execute(
        action: "test",
        required_param: "value"
      )
      expect(result).to be_truthy
    end
  end
end
```

3. **Add example**:

```ruby
# examples/my_tool_example.rb
require 'bundler/setup'
require 'shared_tools'

tool = SharedTools::Tools::MyTool.new
result = tool.execute(
  action: "demo",
  required_param: "test"
)

puts result
```

4. **Update documentation**:

- Add tool to `docs/tools/my-tool.md`
- Reference in `docs/api/index.md`
- Add to examples index

## Testing Guidelines

### Test Organization

```ruby
RSpec.describe SharedTools::Tools::MyTool do
  # Context for different scenarios
  context "when action is valid" do
    it "performs the action" do
      # Test implementation
    end
  end

  context "when action is invalid" do
    it "raises an error" do
      expect {
        tool.execute(action: "invalid")
      }.to raise_error(ArgumentError)
    end
  end

  # Test parameter validation
  describe "parameter validation" do
    it "requires action parameter" do
      expect {
        tool.execute(required_param: "value")
      }.to raise_error(ArgumentError, /action/)
    end
  end

  # Test different actions
  describe "actions" do
    describe "test_action" do
      it "returns expected result" do
        result = tool.execute(action: "test_action", required_param: "value")
        expect(result).to eq("expected")
      end
    end
  end
end
```

### Using Mock Drivers

```ruby
let(:mock_driver) do
  instance_double(
    SharedTools::Tools::Browser::BaseDriver,
    goto: "navigated",
    html: "<html>test</html>",
    click: "clicked"
  )
end

let(:tool) { described_class.new(driver: mock_driver) }
```

## Code Style

### Ruby Style Guide

Follow the [Ruby Style Guide](https://rubystyle.guide/):

- Use 2 spaces for indentation
- Maximum line length: 120 characters
- Use snake_case for methods and variables
- Use CamelCase for classes and modules

### Documentation Style

Use YARD for code documentation:

```ruby
# Description of what the method does
#
# @param action [String] the action to perform
# @param options [Hash] optional parameters
# @option options [String] :url URL to visit
# @option options [Integer] :timeout timeout in seconds
#
# @return [String] result of the operation
#
# @raise [ArgumentError] if action is invalid
#
# @example Basic usage
#   tool.execute(action: "visit", options: { url: "https://example.com" })
def execute(action:, options: {})
  # Implementation
end
```

## Performance Considerations

- Use lazy loading for sub-tools and drivers
- Cache expensive computations
- Avoid unnecessary object creation
- Use connection pooling for databases
- Profile code with `ruby-prof` if needed

## Security Considerations

- Validate all user inputs
- Use authorization system for dangerous operations
- Sanitize SQL to prevent injection
- Escape HTML/CSS selectors
- Don't log sensitive information
- Use secure temp files

## Release Process

1. Update version in `lib/shared_tools/tools/version.rb`
2. Update `CHANGELOG.md`
3. Run full test suite
4. Commit changes
5. Tag release: `git tag v0.x.x`
6. Push: `git push && git push --tags`
7. Build gem: `gem build shared_tools.gemspec`
8. Publish: `gem push shared_tools-0.x.x.gem`

## Getting Help

- GitHub Discussions: Ask questions
- GitHub Issues: Report bugs
- Code Review: Request feedback on PRs
- Documentation: Read the docs

## Resources

- [RubyLLM Documentation](https://github.com/mariochavez/ruby_llm)
- [Watir Documentation](http://watir.com/guides/)
- [RSpec Documentation](https://rspec.info/)
- [YARD Documentation](https://yardoc.org/)

## Next Steps

- Read the [Architecture Guide](./architecture.md)
- Review [Contributing Guidelines](./contributing.md)
- Learn about [Testing Strategies](./testing.md)
- Check the [Changelog](./changelog.md)
