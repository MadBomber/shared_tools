#!/usr/bin/env ruby
# frozen_string_literal: true

# Example: Using ComputerTool for system automation
#
# This example demonstrates how to use the ComputerTool to automate
# computer interactions like mouse movements, keyboard input, and scrolling.
#
# Note: This example uses a mock driver for demonstration.
# For real automation on macOS, you would need additional dependencies.

require 'bundler/setup'
require 'shared_tools'

# Create a mock driver for demonstration
# In production, you would use platform-specific drivers
class DemoComputerDriver
  def key(text:)
    puts "  [Driver] Pressing key: #{text}"
    "Pressed #{text}"
  end

  def hold_key(text:, duration:)
    puts "  [Driver] Holding key '#{text}' for #{duration} seconds"
    "Held #{text} for #{duration}s"
  end

  def mouse_position
    x, y = rand(100..1000), rand(100..800)
    puts "  [Driver] Getting mouse position: (#{x}, #{y})"
    { x: x, y: y }
  end

  def mouse_move(coordinate:)
    puts "  [Driver] Moving mouse to: (#{coordinate[:x]}, #{coordinate[:y]})"
    "Moved to (#{coordinate[:x]}, #{coordinate[:y]})"
  end

  def mouse_click(coordinate:, button:)
    puts "  [Driver] Clicking #{button} button at: (#{coordinate[:x]}, #{coordinate[:y]})"
    "Clicked #{button} at (#{coordinate[:x]}, #{coordinate[:y]})"
  end

  def mouse_double_click(coordinate:, button:)
    puts "  [Driver] Double-clicking #{button} button at: (#{coordinate[:x]}, #{coordinate[:y]})"
    "Double-clicked #{button} at (#{coordinate[:x]}, #{coordinate[:y]})"
  end

  def mouse_triple_click(coordinate:, button:)
    puts "  [Driver] Triple-clicking #{button} button at: (#{coordinate[:x]}, #{coordinate[:y]})"
    "Triple-clicked #{button} at (#{coordinate[:x]}, #{coordinate[:y]})"
  end

  def mouse_down(coordinate:, button:)
    puts "  [Driver] Pressing #{button} mouse button down at: (#{coordinate[:x]}, #{coordinate[:y]})"
    "Mouse down #{button} at (#{coordinate[:x]}, #{coordinate[:y]})"
  end

  def mouse_up(coordinate:, button:)
    puts "  [Driver] Releasing #{button} mouse button at: (#{coordinate[:x]}, #{coordinate[:y]})"
    "Mouse up #{button} at (#{coordinate[:x]}, #{coordinate[:y]})"
  end

  def mouse_drag(coordinate:, button:)
    puts "  [Driver] Dragging with #{button} button to: (#{coordinate[:x]}, #{coordinate[:y]})"
    "Dragged #{button} to (#{coordinate[:x]}, #{coordinate[:y]})"
  end

  def type(text:)
    puts "  [Driver] Typing text: #{text}"
    "Typed: #{text}"
  end

  def scroll(amount:, direction:)
    puts "  [Driver] Scrolling #{direction} by #{amount} clicks"
    "Scrolled #{direction} #{amount} clicks"
  end

  def wait(duration:)
    puts "  [Driver] Waiting for #{duration} seconds..."
    sleep(0.1)  # Minimal sleep for demo
    "Waited #{duration}s"
  end
end

puts "=" * 80
puts "ComputerTool Example - System Automation"
puts "=" * 80
puts

# Initialize the computer tool with our demo driver
driver = DemoComputerDriver.new
computer = SharedTools::Tools::ComputerTool.new(driver: driver)

# Example 1: Get mouse position
puts "1. Getting current mouse position"
puts "-" * 40
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_POSITION
)
puts "Result: #{result}"
puts

# Example 2: Move mouse to specific coordinates
puts "2. Moving mouse to coordinates"
puts "-" * 40
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_MOVE,
  coordinate: { x: 500, y: 300 }
)
puts "Result: #{result}"
puts

# Example 3: Click at coordinates
puts "3. Clicking left mouse button"
puts "-" * 40
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_CLICK,
  coordinate: { x: 500, y: 300 },
  mouse_button: SharedTools::Tools::ComputerTool::MouseButton::LEFT
)
puts "Result: #{result}"
puts

# Example 4: Double-click
puts "4. Double-clicking"
puts "-" * 40
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_DOUBLE_CLICK,
  coordinate: { x: 600, y: 400 },
  mouse_button: SharedTools::Tools::ComputerTool::MouseButton::LEFT
)
puts "Result: #{result}"
puts

# Example 5: Right-click for context menu
puts "5. Right-clicking (context menu)"
puts "-" * 40
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_CLICK,
  coordinate: { x: 700, y: 500 },
  mouse_button: SharedTools::Tools::ComputerTool::MouseButton::RIGHT
)
puts "Result: #{result}"
puts

# Example 6: Drag and drop
puts "6. Drag and drop operation"
puts "-" * 40
# Press mouse button down
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_DOWN,
  coordinate: { x: 100, y: 100 },
  mouse_button: SharedTools::Tools::ComputerTool::MouseButton::LEFT
)
# Drag to new position
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_DRAG,
  coordinate: { x: 300, y: 300 },
  mouse_button: SharedTools::Tools::ComputerTool::MouseButton::LEFT
)
# Release mouse button
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_UP,
  coordinate: { x: 300, y: 300 },
  mouse_button: SharedTools::Tools::ComputerTool::MouseButton::LEFT
)
puts "Drag and drop completed"
puts

# Example 7: Type text
puts "7. Typing text"
puts "-" * 40
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::TYPE,
  text: "Hello, World! This is automated typing."
)
puts "Result: #{result}"
puts

# Example 8: Press keyboard keys
puts "8. Pressing keyboard keys"
puts "-" * 40
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::KEY,
  text: "Return"
)
puts "Pressed Enter/Return key"
puts

# Example 9: Keyboard shortcuts
puts "9. Using keyboard shortcuts"
puts "-" * 40
shortcuts = [
  "cmd+c",      # Copy
  "cmd+v",      # Paste
  "cmd+s",      # Save
  "cmd+Tab",    # Switch applications
  "ctrl+shift+t"  # Reopen closed tab
]

shortcuts.each do |shortcut|
  computer.execute(
    action: SharedTools::Tools::ComputerTool::Action::KEY,
    text: shortcut
  )
end
puts "Executed keyboard shortcuts"
puts

# Example 10: Hold key for duration
puts "10. Holding a key"
puts "-" * 40
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::HOLD_KEY,
  text: "shift",
  duration: 2
)
puts "Result: #{result}"
puts

# Example 11: Scroll
puts "11. Scrolling"
puts "-" * 40
# Scroll down
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::SCROLL,
  scroll_direction: SharedTools::Tools::ComputerTool::ScrollDirection::DOWN,
  scroll_amount: 5
)
# Scroll up
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::SCROLL,
  scroll_direction: SharedTools::Tools::ComputerTool::ScrollDirection::UP,
  scroll_amount: 3
)
puts "Scrolled down 5 clicks, then up 3 clicks"
puts

# Example 12: Wait/pause
puts "12. Waiting/pausing"
puts "-" * 40
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::WAIT,
  duration: 2
)
puts "Result: #{result}"
puts

# Example 13: Complete workflow - Form filling automation
puts "13. Complete Workflow - Form Filling Automation"
puts "-" * 40
puts "Simulating automated form filling..."
puts

# Click on first field
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_CLICK,
  coordinate: { x: 400, y: 200 },
  mouse_button: SharedTools::Tools::ComputerTool::MouseButton::LEFT
)

# Type name
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::TYPE,
  text: "John Doe"
)

# Tab to next field
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::KEY,
  text: "Tab"
)

# Type email
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::TYPE,
  text: "john.doe@example.com"
)

# Tab to next field
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::KEY,
  text: "Tab"
)

# Type message
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::TYPE,
  text: "This is an automated message."
)

# Submit form (click submit button)
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_CLICK,
  coordinate: { x: 500, y: 600 },
  mouse_button: SharedTools::Tools::ComputerTool::MouseButton::LEFT
)

puts "Form filling automation completed!"
puts

# Example 14: Text selection workflow
puts "14. Text Selection Workflow"
puts "-" * 40
puts "Simulating text selection and copying..."

# Double-click to select word
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_DOUBLE_CLICK,
  coordinate: { x: 300, y: 400 },
  mouse_button: SharedTools::Tools::ComputerTool::MouseButton::LEFT
)

# Copy selected text
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::KEY,
  text: "cmd+c"
)

# Triple-click to select paragraph
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_TRIPLE_CLICK,
  coordinate: { x: 300, y: 400 },
  mouse_button: SharedTools::Tools::ComputerTool::MouseButton::LEFT
)

# Cut selected text
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::KEY,
  text: "cmd+x"
)

puts "Text selection workflow completed!"
puts

puts "=" * 80
puts "Example completed successfully!"
puts "=" * 80
puts
puts "Note: This example uses a mock driver for demonstration."
puts "For real system automation on macOS, you would need platform-specific drivers."
puts "The ComputerTool supports macOS with appropriate dependencies installed."
