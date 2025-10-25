# Browser Tool Example

The BrowserTool provides a unified interface for web automation tasks. It supports multiple actions like visiting pages, inspecting content, clicking elements, filling forms, and taking screenshots.

## Overview

This example demonstrates how to use the BrowserTool facade to automate browser interactions. The tool uses a driver pattern, allowing you to swap different browser drivers (like WatirDriver for real browsers or a mock driver for testing).

## Example Code

View the complete example: [browser_tool_example.rb](https://github.com/madbomber/shared_tools/blob/main/examples/browser_tool_example.rb)

## Key Features

### 1. Page Navigation

Navigate to any URL using the `VISIT` action:

```ruby
browser = SharedTools::Tools::BrowserTool.new(driver: driver)

browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::VISIT,
  url: "https://example.com"
)
```

### 2. Page Inspection

Inspect page content with the `PAGE_INSPECT` action:

```ruby
result = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::PAGE_INSPECT,
  full_html: false  # Get summary instead of full HTML
)
```

### 3. Finding Elements

Find elements by text content:

```ruby
result = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::UI_INSPECT,
  text_content: "Login"
)
```

Find elements by CSS selector:

```ruby
result = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::SELECTOR_INSPECT,
  selector: "input[type='text']"
)
```

### 4. Interacting with Elements

Click elements:

```ruby
result = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::CLICK,
  selector: "button[type='submit']"
)
```

Fill in text fields:

```ruby
result = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::TEXT_FIELD_SET,
  selector: "#username",
  value: "demo_user"
)
```

### 5. Screenshots

Take screenshots:

```ruby
result = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::SCREENSHOT
)
# Returns base64-encoded PNG image
```

## Complete Workflow Example

The example includes a complete login automation workflow:

```ruby
# Step 1: Navigate to login page
browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::VISIT,
  url: "https://example.com/login"
)

# Step 2: Fill in username
browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::TEXT_FIELD_SET,
  selector: "#username",
  value: "admin"
)

# Step 3: Fill in password
browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::TEXT_FIELD_SET,
  selector: "#password",
  value: "secret123"
)

# Step 4: Click login button
browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::CLICK,
  selector: "button[type='submit']"
)

# Cleanup
browser.cleanup!
```

## Available Actions

- `VISIT` - Navigate to a URL
- `PAGE_INSPECT` - Get page HTML content
- `UI_INSPECT` - Find elements by text content
- `SELECTOR_INSPECT` - Find elements by CSS selector
- `CLICK` - Click an element
- `TEXT_FIELD_SET` - Fill in a text field
- `SCREENSHOT` - Take a screenshot

## Run the Example

```bash
cd examples
bundle exec ruby browser_tool_example.rb
```

The example uses a demo driver that simulates browser interactions. For real browser automation, you would use a driver like `WatirDriver` with a real browser instance.

## Related Documentation

- [BrowserTool Documentation](../tools/browser.md)
- [Facade Pattern](../api/facade-pattern.md)
- [Driver Pattern Documentation](../api/driver-interface.md)
- [Architecture Guide](../development/architecture.md)

## Notes

- The BrowserTool uses a driver pattern for flexibility
- Supports multiple browser drivers (Watir, Selenium, etc.)
- All actions return structured results
- Screenshots are returned as base64-encoded strings
- Remember to call `cleanup!` to close the browser when done
