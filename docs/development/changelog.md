# Changelog

All notable changes to SharedTools will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Changing direction. Beginning with 0.3.0 will only support RubyLLM framework

### Deprecated
- Support for OmniAI framework (use RubyLLM instead)
- Support for llm.rb framework (use RubyLLM instead)
- Support for Raix framework (use RubyLLM instead)

## [0.2.1] - 2025-07-03

### Fixed
- iMCP server app for MacOS is noisy logger, now redirects stderr to /dev/null

## [0.2.0] - 2025-07-01

### Added
- `ruby_llm/mcp/github_mcp_server.rb` example integration
- `SharedTools.mcp_servers` as an Array to track MCP server instances
- Class method `name` to all tool classes (snake_case of class name)
- `ruby_llm/mcp/imcp.rb` for MacOS app integration
- `ruby_llm/incomplete/` directory with under-development example tools

### Changed
- Tool naming convention now consistent across all tools

## [0.1.3] - 2025-06-18

### Fixed
- Tweaked the load-all-tools process for better reliability

## [0.1.2] - 2025-06-10

### Added
- Zeitwerk gem for automatic code loading

### Changed
- Migrated from manual requires to Zeitwerk autoloading

## [0.1.0] - 2025-06-05

Initial gem release

### Added
- SharedTools core module with authorization system
- Human-in-the-loop confirmation (`SharedTools.execute?`)
- RubyLLM tool implementations:
  - `EditFile`: Edit files with find/replace
  - `ListFiles`: Directory listing
  - `PdfPageReader`: PDF content extraction
  - `ReadFile`: File reading with error handling
  - `RunShellCommand`: Shell command execution
- Framework detection system
- Logger integration with RubyLLM
- Zeitwerk autoloading support
- Basic documentation and examples

---

## Version History Format

Each version should document changes in these categories:

### Added
New features and capabilities

### Changed
Changes to existing functionality

### Deprecated
Features that will be removed in future versions

### Removed
Features that have been removed

### Fixed
Bug fixes

### Security
Security-related changes

---

## Migration Guides

### Migrating to 0.3.0 (RubyLLM Only)

**Breaking Change**: Version 0.3.0 drops support for OmniAI, llm.rb, and Raix.

#### Before (0.2.x with OmniAI)

```ruby
require 'omniai'
require 'shared_tools'

# Tools were loaded based on framework detection
tools = SharedTools.tools_for(:omniai)
```

#### After (0.3.0 with RubyLLM)

```ruby
require 'ruby_llm'
require 'shared_tools'

# All tools now extend RubyLLM::Tool
agent = RubyLLM::Agent.new(
  tools: [
    SharedTools::Tools::BrowserTool.new,
    SharedTools::Tools::DiskTool.new
  ]
)
```

### Required Changes

1. **Update Gemfile**:
```ruby
# Remove
gem 'omniai-tools'

# Add
gem 'ruby_llm'
gem 'shared_tools', '~> 0.3'
```

2. **Update Tool Initialization**:
```ruby
# Old way (any framework)
tools = SharedTools.load_tools_for(framework)

# New way (RubyLLM only)
tools = [
  SharedTools::Tools::BrowserTool.new,
  SharedTools::Tools::DiskTool.new,
  SharedTools::Tools::DatabaseTool.new
]
```

3. **Update Custom Tools**:
```ruby
# Old way (OmniAI)
class MyTool < OmniAI::Tool
  # ...
end

# New way (RubyLLM)
class MyTool < ::RubyLLM::Tool
  def self.name = 'my_tool'

  description "Tool description"

  param :action, desc: "Action to perform"

  def execute(action:)
    # ...
  end
end
```

### Why This Change?

- **Focus**: Better to support one framework well than many frameworks poorly
- **Maintenance**: Reduces maintenance burden significantly
- **Features**: Enables RubyLLM-specific features and optimizations
- **Simplicity**: Clearer codebase and documentation

### Need Help?

- Open an issue on GitHub for migration assistance
- Check the [RubyLLM documentation](https://github.com/mariochavez/ruby_llm)
- Review our [examples directory](https://github.com/madbomber/shared_tools/tree/main/examples) for updated examples

---

## Release Process

For maintainers releasing a new version:

### 1. Update Version

Edit `lib/shared_tools/tools/version.rb`:

```ruby
module SharedTools
  module Tools
    VERSION = "X.Y.Z"
  end
end
```

### 2. Update This Changelog

Add new version section with changes:

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New feature description

### Changed
- Change description

### Fixed
- Bug fix description
```

### 3. Commit Changes

```bash
git add lib/shared_tools/tools/version.rb CHANGELOG.md
git commit -m "chore: bump version to X.Y.Z"
```

### 4. Create Git Tag

```bash
git tag vX.Y.Z
git push origin main
git push origin vX.Y.Z
```

### 5. Build and Push Gem

```bash
gem build shared_tools.gemspec
gem push shared_tools-X.Y.Z.gem
```

### 6. Create GitHub Release

- Go to GitHub Releases
- Create new release from tag
- Copy changelog section for this version
- Publish release

---

## Semantic Versioning

SharedTools follows [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Breaking changes
- **MINOR** (0.X.0): New features, backwards compatible
- **PATCH** (0.0.X): Bug fixes, backwards compatible

### Breaking Changes

Breaking changes (major version bumps) include:

- Removing or renaming public APIs
- Changing method signatures
- Removing tools
- Changing default behavior in incompatible ways
- Dropping framework support

### New Features

New features (minor version bumps) include:

- Adding new tools
- Adding new actions to existing tools
- Adding optional parameters
- Adding new drivers
- Performance improvements

### Bug Fixes

Bug fixes (patch version bumps) include:

- Fixing crashes
- Fixing incorrect behavior
- Documentation fixes
- Test improvements
- Performance optimizations (minor)

---

## Version Support

| Version | Status | Ruby Version | RubyLLM Version | End of Support |
|---------|--------|--------------|-----------------|----------------|
| 0.3.x   | Active | 3.0+         | 0.4+           | TBD            |
| 0.2.x   | Maintenance | 3.0+    | 0.3+           | 2025-12-31     |
| 0.1.x   | Unsupported | 3.0+    | 0.2+           | 2025-06-30     |

### Support Levels

- **Active**: Full support, new features, bug fixes
- **Maintenance**: Critical bug fixes and security updates only
- **Unsupported**: No updates, use at your own risk

---

## Upgrade Policy

### Minor Version Updates

Can be done safely:

```bash
bundle update shared_tools
```

### Major Version Updates

Require code changes:

1. Review changelog for breaking changes
2. Check migration guide
3. Update code as needed
4. Test thoroughly
5. Deploy

---

## Deprecation Policy

Features marked as deprecated:

1. **Announcement**: Deprecated in changelog
2. **Warning Period**: At least one minor version
3. **Removal**: In next major version

Example:

```
0.2.0: Feature X deprecated (warning)
0.2.x: Feature X still works with warning
0.3.0: Feature X removed (breaking change)
```

---

## Contributing to Changelog

When contributing:

1. Add your changes to [Unreleased] section
2. Use appropriate category (Added, Changed, Fixed, etc.)
3. Write clear, user-focused descriptions
4. Link to issues/PRs when relevant
5. Maintainers will move to versioned section on release

Example:

```markdown
## [Unreleased]

### Added
- New ComputerTool for system automation ([#123](https://github.com/user/repo/pull/123))

### Fixed
- BrowserTool now handles missing elements gracefully ([#124](https://github.com/user/repo/issues/124))
```

---

## Historical Releases

See [GitHub Releases](https://github.com/madbomber/shared_tools/releases) for:

- Full release notes
- Downloadable gems
- Source code archives
- Release checksums
