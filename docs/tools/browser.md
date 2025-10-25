# BrowserTool

Web browser automation tool using Watir for visiting pages, inspecting content, clicking elements, filling forms, and capturing screenshots.

## Installation

BrowserTool requires the Watir gem:

```ruby
gem 'watir'
```

You also need a browser driver (ChromeDriver, GeckoDriver, etc.):

```bash
# macOS
brew install --cask chromedriver

# Ubuntu/Debian
apt-get install chromium-chromedriver
```

## Basic Usage

```ruby
require 'shared_tools'

# Initialize with default Watir driver
browser = SharedTools::Tools::BrowserTool.new

# Visit a website
browser.execute(action: "visit", url: "https://example.com")

# Get page content
html = browser.execute(action: "page_inspect", full_html: true)

# Clean up when done
browser.cleanup!
```

## Actions

### visit

Navigate to a URL.

**Parameters:**

- `action`: "visit"
- `url`: Website URL to navigate to

**Example:**

```ruby
browser.execute(
  action: "visit",
  url: "https://github.com/madbomber/shared_tools"
)
```

---

### page_inspect

Get page HTML or summary.

**Parameters:**

- `action`: "page_inspect"
- `full_html`: (optional) `true` for full HTML, `false` for summary (default: false)

**Examples:**

```ruby
# Get page summary
summary = browser.execute(action: "page_inspect")

# Get full HTML
html = browser.execute(action: "page_inspect", full_html: true)
```

---

### ui_inspect

Find elements by text content.

**Parameters:**

- `action`: "ui_inspect"
- `text_content`: Text to search for in elements
- `selector`: (optional) CSS selector to search within
- `context_size`: (optional) Number of parent elements to include (default: 2)

**Examples:**

```ruby
# Find elements containing "Login"
elements = browser.execute(
  action: "ui_inspect",
  text_content: "Login"
)

# Search within specific container
elements = browser.execute(
  action: "ui_inspect",
  text_content: "Submit",
  selector: ".form-container"
)

# Include more context
elements = browser.execute(
  action: "ui_inspect",
  text_content: "Sign Up",
  context_size: 3
)
```

---

### selector_inspect

Find elements by CSS selector.

**Parameters:**

- `action`: "selector_inspect"
- `selector`: CSS selector to match
- `context_size`: (optional) Number of parent elements to include (default: 2)

**Examples:**

```ruby
# Find buttons
elements = browser.execute(
  action: "selector_inspect",
  selector: "button"
)

# Find by class
elements = browser.execute(
  action: "selector_inspect",
  selector: ".nav-item"
)

# Complex selector
elements = browser.execute(
  action: "selector_inspect",
  selector: "form button[type='submit']"
)
```

---

### click

Click an element by CSS selector.

**Parameters:**

- `action`: "click"
- `selector`: CSS selector for element to click

**Examples:**

```ruby
# Click submit button
browser.execute(
  action: "click",
  selector: "button[type='submit']"
)

# Click link
browser.execute(
  action: "click",
  selector: "a[href='/login']"
)

# Click by ID
browser.execute(
  action: "click",
  selector: "#submit-btn"
)
```

---

### text_field_set

Enter text in input fields or text areas.

**Parameters:**

- `action`: "text_field_set"
- `selector`: CSS selector for input element
- `value`: Text to enter

**Examples:**

```ruby
# Fill search box
browser.execute(
  action: "text_field_set",
  selector: "#search",
  value: "shared_tools"
)

# Fill form field
browser.execute(
  action: "text_field_set",
  selector: "input[name='email']",
  value: "user@example.com"
)

# Fill text area
browser.execute(
  action: "text_field_set",
  selector: "textarea.comment",
  value: "This is a comment"
)
```

---

### screenshot

Take a screenshot of the current page.

**Parameters:**

- `action`: "screenshot"

**Example:**

```ruby
# Returns base64-encoded PNG
screenshot_data = browser.execute(action: "screenshot")

# Save to file
require 'base64'
File.open("page.png", "wb") do |f|
  f.write(Base64.decode64(screenshot_data))
end
```

## CSS Selectors

BrowserTool uses CSS selectors to locate elements. Here are common patterns:

### By Element Type

```ruby
"button"           # All buttons
"input"            # All inputs
"a"                # All links
```

### By ID

```ruby
"#username"        # Element with id="username"
"#submit-btn"      # Element with id="submit-btn"
```

### By Class

```ruby
".button"          # Elements with class="button"
".nav-item"        # Elements with class="nav-item"
```

### By Attribute

```ruby
"button[type='submit']"       # Button with type="submit"
"a[href='/login']"            # Link with href="/login"
"input[name='password']"      # Input with name="password"
"button[aria-label='Close']"  # Button with aria-label="Close"
```

### Combinators

```ruby
"form button"                 # Buttons inside forms
"div#parent > span.child"     # Direct child span
"nav a.active"                # Active links in nav
```

## Complete Example

```ruby
require 'shared_tools'

browser = SharedTools::Tools::BrowserTool.new

begin
  # 1. Navigate to login page
  puts "Navigating to login page..."
  browser.execute(
    action: "visit",
    url: "https://example.com/login"
  )

  # 2. Check if we're on the right page
  summary = browser.execute(action: "page_inspect")
  puts "Current page: #{summary}"

  # 3. Find login button to verify page loaded
  elements = browser.execute(
    action: "ui_inspect",
    text_content: "Sign In"
  )

  if elements.empty?
    puts "Login page not loaded correctly"
    exit 1
  end

  # 4. Fill in credentials
  puts "Entering credentials..."
  browser.execute(
    action: "text_field_set",
    selector: "#username",
    value: "demo@example.com"
  )

  browser.execute(
    action: "text_field_set",
    selector: "#password",
    value: "secret123"
  )

  # 5. Submit form
  puts "Submitting form..."
  browser.execute(
    action: "click",
    selector: "button[type='submit']"
  )

  # 6. Take screenshot of result
  sleep 2  # Wait for page load
  screenshot = browser.execute(action: "screenshot")

  # Save screenshot
  require 'base64'
  File.open("login_result.png", "wb") do |f|
    f.write(Base64.decode64(screenshot))
  end

  puts "Login complete! Screenshot saved."

ensure
  browser.cleanup!
end
```

## Custom Driver

You can provide a custom browser driver:

```ruby
# Create custom driver implementing the driver interface
class MyCustomDriver < SharedTools::Tools::Browser::BaseDriver
  def goto(url:)
    # Your implementation
  end

  def html
    # Return page HTML
  end

  def click(selector:)
    # Click element
  end

  # ... implement other methods
end

# Use custom driver
driver = MyCustomDriver.new
browser = SharedTools::Tools::BrowserTool.new(driver: driver)
```

## Error Handling

```ruby
browser = SharedTools::Tools::BrowserTool.new

begin
  browser.execute(action: "visit", url: "https://invalid-url")
rescue StandardError => e
  puts "Navigation failed: #{e.message}"
end

begin
  browser.execute(action: "click", selector: ".non-existent")
rescue StandardError => e
  puts "Element not found: #{e.message}"
end
```

## Best Practices

### 1. Always Clean Up

```ruby
browser = SharedTools::Tools::BrowserTool.new
begin
  # Do work...
ensure
  browser.cleanup!  # Close browser
end
```

### 2. Wait for Elements

```ruby
# Check if element exists before clicking
elements = browser.execute(
  action: "selector_inspect",
  selector: "button.submit"
)

if !elements.empty?
  browser.execute(action: "click", selector: "button.submit")
else
  puts "Submit button not found"
end
```

### 3. Use Specific Selectors

```ruby
# Good: Specific selector
browser.execute(action: "click", selector: "button[type='submit']")

# Avoid: Too generic
browser.execute(action: "click", selector: "button")
```

### 4. Handle Timeouts

```ruby
require 'timeout'

begin
  Timeout.timeout(10) do
    browser.execute(action: "visit", url: "https://slow-site.com")
  end
rescue Timeout::Error
  puts "Page load timed out"
end
```

## Troubleshooting

### Browser Driver Not Found

```
Error: Unable to find chromedriver
```

**Solution:** Install the browser driver:

```bash
# macOS
brew install --cask chromedriver

# Ubuntu
apt-get install chromium-chromedriver
```

### Element Not Found

```
Error: Element not found
```

**Solution:** Wait for page to load or use more specific selectors:

```ruby
# Add delay
sleep 2

# Or verify element exists first
elements = browser.execute(action: "selector_inspect", selector: "button")
```

### Permission Denied

```
Error: Permission denied accessing browser
```

**Solution:** Run ChromeDriver with proper permissions or allow in System Preferences.

## See Also

- [Basic Usage](../getting-started/basic-usage.md) - Common patterns
- [Working with Drivers](../guides/drivers.md) - Custom driver implementation
- [Examples](https://github.com/madbomber/shared_tools/tree/main/examples/browser_tool_example.rb)
