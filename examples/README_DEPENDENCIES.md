# Example Dependencies

This document lists the optional gem dependencies required for each example in the `examples/` directory.

## Quick Installation

To install all optional dependencies at once:

```bash
bundle install
```

Or install only what you need:

```bash
# For browser automation examples
gem install watir webdrivers

# For PDF processing examples
gem install pdf-reader

# For database examples
gem install sqlite3

# For computer automation examples (macOS only)
gem install macos
```

## Example-Specific Dependencies

### Browser Tool Example (`browser_tool_example.rb`)

**Required Gems:**
- `watir` - Browser automation framework
- `webdrivers` - Automatic webdriver management

**Installation:**
```bash
gem install watir webdrivers
```

**Additional Requirements:**
- Chrome, Firefox, or Safari browser installed
- Compatible webdriver (automatically managed by `webdrivers` gem)

---

### Computer Tool Example (`computer_tool_example.rb`)

**Required Gems:**
- `macos` - macOS automation framework (macOS only)

**Installation:**
```bash
gem install macos
```

**Additional Requirements:**
- macOS operating system
- Accessibility permissions granted:
  - System Preferences → Security & Privacy → Privacy → Accessibility
  - Add Terminal or your IDE to the allowed applications

---

### Doc Tool Example (`doc_tool_example.rb`)

**Required Gems:**
- `pdf-reader` - PDF parsing and text extraction

**Installation:**
```bash
gem install pdf-reader
```

**Additional Requirements:**
- A sample PDF file (the example looks for `test/fixtures/test.pdf`)

---

### Database Tool Example (`database_tool_example.rb`)

**Required Gems:**
- `sqlite3` - SQLite3 database adapter

**Installation:**
```bash
gem install sqlite3
```

**Additional Requirements:**
- None (uses in-memory database)

---

### Comprehensive Workflow Example (`comprehensive_workflow_example.rb`)

**Required Gems:**
- `sqlite3` - For database operations

**Installation:**
```bash
gem install sqlite3
```

**Additional Requirements:**
- None

---

### Disk Tool Example (`disk_tool_example.rb`)

**Required Gems:**
- None (uses standard Ruby libraries)

**Additional Requirements:**
- None

---

### Eval Tool Example (`eval_tool_example.rb`)

**Required Gems:**
- None (uses standard Ruby libraries)

**Additional Requirements:**
- Python installed (for Python evaluation examples)
- Shell access (for shell command examples)

---

## Dependency Summary

| Tool Category | Required Gems | Platform | Notes |
|--------------|---------------|----------|-------|
| Browser | `watir`, `webdrivers` | All | Requires browser installed |
| Computer | `macos` | macOS | Requires accessibility permissions |
| Doc/PDF | `pdf-reader` | All | For PDF processing |
| Database | `sqlite3` | All | For SQLite examples |
| Disk | None | All | Standard library |
| Eval | None | All | Python optional for Python eval |

## Troubleshooting

### "LoadError: cannot load such file"

This means a required gem is not installed. Read the error message carefully - it will tell you which gem is missing. Install it using:

```bash
gem install <gem-name>
```

### Browser automation fails

1. Make sure Chrome (or your preferred browser) is installed
2. Check that `webdrivers` gem is installed: `gem install webdrivers`
3. Try running with a visible browser (non-headless) for debugging

### Computer automation fails on macOS

1. Grant accessibility permissions:
   - System Preferences → Security & Privacy → Privacy → Accessibility
   - Add your Terminal app or IDE
   - Restart the application after granting permissions

### PDF reading fails

1. Make sure `pdf-reader` gem is installed: `gem install pdf-reader`
2. Verify the PDF file exists at the specified path
3. Check that the PDF is not corrupted or password-protected

## Development Dependencies

All optional dependencies are declared in `shared_tools.gemspec` as development dependencies, so they're automatically installed when you run `bundle install` in the gem's root directory.

If you're using the gem in your own project, you can add only the tools you need:

```ruby
# Gemfile
gem 'shared_tools'

# Optional: Add only what you need
gem 'watir' if you_need_browser_tools
gem 'pdf-reader' if you_need_pdf_tools
gem 'sqlite3' if you_need_database_examples
gem 'macos' if you_need_computer_tools && RUBY_PLATFORM.include?('darwin')
```
