#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using BrowserTool for web automation
#
# This example demonstrates how to use the BrowserTool facade to automate
# browser interactions. The BrowserTool supports multiple actions like
# visiting pages, inspecting content, clicking elements, and taking screenshots.

require 'bundler/setup'
require 'shared_tools'

# Create a mock driver for demonstration
# In production, you would use a real driver like WatirDriver
class DemoBrowserDriver
  def goto(url:)
    puts "  [Driver] Navigating to: #{url}"
    "Navigated to #{url}"
  end

  def html
    <<~HTML
      <html>
        <body>
          <h1>Welcome to SharedTools</h1>
          <form id="login-form">
            <input type="text" id="username" placeholder="Username" />
            <input type="password" id="password" placeholder="Password" />
            <button type="submit">Login</button>
          </form>
          <div class="content">
            <p>This is a demo page for browser automation.</p>
            <a href="/about">About</a>
          </div>
        </body>
      </html>
    HTML
  end

  def click(selector:)
    puts "  [Driver] Clicking: #{selector}"
    "Clicked #{selector}"
  end

  def fill_in(selector:, text:)
    puts "  [Driver] Filling '#{selector}' with: #{text}"
    "Filled in #{selector}"
  end

  def screenshot
    puts "  [Driver] Taking screenshot..."
    require 'tempfile'
    require 'base64'
    # Minimal 1x1 transparent PNG
    png_data = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")
    Tempfile.create(['screenshot', '.png']) do |file|
      file.binmode
      file.write(png_data)
      file.rewind
      yield file
    end
  end

  def close
    puts "  [Driver] Browser closed"
  end
end

puts "=" * 80
puts "BrowserTool Example - Web Automation"
puts "=" * 80
puts

# Initialize the browser tool with our demo driver
driver = DemoBrowserDriver.new
browser = SharedTools::Tools::BrowserTool.new(driver: driver)

# Example 1: Visit a URL
puts "1. Visiting a website"
puts "-" * 40
result = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::VISIT,
  url: "https://example.com"
)
puts "Result: #{result}"
puts

# Example 2: Inspect page content
puts "2. Inspecting page HTML"
puts "-" * 40
result = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::PAGE_INSPECT,
  full_html: false  # Get summary instead of full HTML
)
puts "Page Summary:"
puts result
puts

# Example 3: Find UI elements by text content
puts "3. Finding elements by text content"
puts "-" * 40
result = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::UI_INSPECT,
  text_content: "Login"
)
puts "Found elements:"
puts result
puts

# Example 4: Find elements by CSS selector
puts "4. Finding elements by CSS selector"
puts "-" * 40
result = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::SELECTOR_INSPECT,
  selector: "input[type='text']"
)
puts "Found elements:"
puts result
puts

# Example 5: Click a button
puts "5. Clicking a button"
puts "-" * 40
result = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::CLICK,
  selector: "button[type='submit']"
)
puts "Result: #{result}"
puts

# Example 6: Fill in a text field
puts "6. Filling in a text field"
puts "-" * 40
result = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::TEXT_FIELD_SET,
  selector: "#username",
  value: "demo_user"
)
puts "Result: #{result}"
puts

# Example 7: Take a screenshot
puts "7. Taking a screenshot"
puts "-" * 40
result = browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::SCREENSHOT
)
puts "Screenshot (base64): #{result[0..100]}..."
puts

# Example 8: Complete workflow - Login automation
puts "8. Complete Login Workflow"
puts "-" * 40
puts "Step 1: Navigate to login page"
browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::VISIT,
  url: "https://example.com/login"
)

puts "Step 2: Fill in username"
browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::TEXT_FIELD_SET,
  selector: "#username",
  value: "admin"
)

puts "Step 3: Fill in password"
browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::TEXT_FIELD_SET,
  selector: "#password",
  value: "secret123"
)

puts "Step 4: Click login button"
browser.execute(
  action: SharedTools::Tools::BrowserTool::Action::CLICK,
  selector: "button[type='submit']"
)

puts "Login workflow completed!"
puts

# Cleanup
browser.cleanup!
puts "Browser closed."
puts
puts "=" * 80
puts "Example completed successfully!"
puts "=" * 80
