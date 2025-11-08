# Computer Tools

The ComputerTool provides system-level automation capabilities for mouse and keyboard control, enabling LLMs to interact with applications and perform desktop automation tasks.

## Overview

ComputerTool allows LLMs to:

- Control mouse movements and clicks
- Type text and keyboard shortcuts
- Scroll windows
- Automate desktop workflows
- Fill forms and interact with UI elements

!!!warning "Platform Compatibility"
    Computer automation features work best on macOS with accessibility permissions enabled. Other platforms may require additional configuration.

## Actions

### Mouse Actions

#### Mouse Click

Click at specific coordinates with various button options.

```ruby
computer = SharedTools::Tools::ComputerTool.new

# Left click
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_CLICK,
  coordinate: { x: 100, y: 200 },
  mouse_button: "left"
)

# Right click
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_CLICK,
  coordinate: { x: 100, y: 200 },
  mouse_button: "right"
)

# Double click
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_CLICK,
  coordinate: { x: 100, y: 200 },
  mouse_button: "left",
  num_clicks: 2
)
```

**Parameters:**
- `coordinate`: Hash with `x` and `y` keys (required)
- `mouse_button`: "left" (default), "right", or "middle"
- `num_clicks`: Number of clicks (default: 1)

#### Mouse Move

Move mouse to specific coordinates.

```ruby
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_MOVE,
  coordinate: { x: 500, y: 300 }
)
```

#### Mouse Position

Get current mouse position.

```ruby
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_POSITION
)

puts "Mouse is at: #{result[:x]}, #{result[:y]}"
```

### Keyboard Actions

#### Type Text

Type text at current cursor position.

```ruby
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::TYPE,
  text: "Hello, World!"
)
```

#### Press Key

Press keyboard keys including modifiers.

```ruby
# Single key
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::KEY,
  text: "Return"
)

# Keyboard shortcut
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::KEY,
  text: "cmd+c"  # Copy on macOS
)

# Multiple modifiers
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::KEY,
  text: "cmd+shift+v"  # Paste and match style
)
```

**Common Keys:**
- `Return`, `Enter`, `Tab`, `Escape`
- `Backspace`, `Delete`, `Space`
- `ArrowUp`, `ArrowDown`, `ArrowLeft`, `ArrowRight`
- `cmd` (macOS), `ctrl` (Windows/Linux)
- `shift`, `alt`, `option`

#### Hold Key

Hold a key for a specific duration.

```ruby
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::HOLD_KEY,
  text: "shift",
  duration: 2  # Hold for 2 seconds
)
```

### Scroll Action

Scroll in a window.

```ruby
# Scroll down
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::SCROLL,
  scroll_direction: "down",
  scroll_amount: 5
)

# Scroll up
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::SCROLL,
  scroll_direction: "up",
  scroll_amount: 3
)
```

### Wait Action

Wait for a specified duration.

```ruby
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::WAIT,
  duration: 2  # Wait 2 seconds
)
```

## Complete Examples

### Form Automation

```ruby
computer = SharedTools::Tools::ComputerTool.new

# Click on name field
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_CLICK,
  coordinate: { x: 300, y: 200 }
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
  text: "john@example.com"
)

# Submit form
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::KEY,
  text: "Return"
)
```

### Text Selection and Copy

```ruby
# Triple-click to select line
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_CLICK,
  coordinate: { x: 400, y: 300 },
  num_clicks: 3
)

# Copy
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::KEY,
  text: "cmd+c"
)

# Wait a moment
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::WAIT,
  duration: 0.5
)

# Click elsewhere
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_CLICK,
  coordinate: { x: 400, y: 500 }
)

# Paste
computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::KEY,
  text: "cmd+v"
)
```

## Working with Drivers

### Built-in Mock Driver

The default driver is a mock implementation useful for testing:

```ruby
computer = SharedTools::Tools::ComputerTool.new
# Uses mock driver by default
```

### Platform-Specific Drivers

For real automation, implement platform-specific drivers:

```ruby
# macOS example using AppleScript/CGEvent
class MacOSDriver
  def mouse_click(coordinate:, mouse_button: "left", num_clicks: 1)
    # Use CGEvent or AppleScript
    system("cliclick c:#{coordinate[:x]},#{coordinate[:y]}")
  end

  def type_text(text:)
    # Type using CGEvent
  end

  # ... other methods
end

computer = SharedTools::Tools::ComputerTool.new(
  driver: MacOSDriver.new
)
```

## Best Practices

### Coordinate Finding

1. **Use Screenshot Tools**: Take screenshots and identify coordinates
2. **Add Delays**: System UIs may need time to respond
3. **Verify UI State**: Check if elements are ready before clicking

### Reliability

```ruby
# Add waits between actions
computer.execute(action: :mouse_click, coordinate: {x: 100, y: 200})
computer.execute(action: :wait, duration: 0.5)
computer.execute(action: :type, text: "Hello")
```

### Error Handling

```ruby
result = computer.execute(
  action: SharedTools::Tools::ComputerTool::Action::MOUSE_CLICK,
  coordinate: { x: 100, y: 200 }
)

if result[:error]
  puts "Click failed: #{result[:error]}"
else
  puts "Click succeeded"
end
```

## Troubleshooting

### Accessibility Permissions

On macOS, enable accessibility permissions:

1. System Preferences → Security & Privacy → Privacy
2. Select "Accessibility"
3. Add your application/terminal

### Coordinate Issues

- Screen coordinates are from top-left (0,0)
- Use screenshot tools to find exact coordinates
- Consider screen resolution and scaling

### Timing Problems

- Add waits between actions
- Increase duration for slower UIs
- Check if dialogs are modal

## See Also

- [BrowserTool](browser.md) - For web automation
- [Examples](../examples/index.md#computer-tool-example) - More examples
- [Driver Guide](../guides/drivers.md) - Custom driver creation
