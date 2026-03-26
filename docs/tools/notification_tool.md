# NotificationTool

Cross-platform desktop notifications, modal alert dialogs, and text-to-speech. Supports macOS and Linux with no gem dependencies — all actions use OS-native commands.

## Platform Support

| Feature | macOS | Linux |
|---------|-------|-------|
| `notify` | `osascript display notification` | `notify-send` (libnotify) |
| `alert` | `osascript display dialog` | `zenity` (GUI) or terminal prompt (headless) |
| `speak` | `say` | `espeak-ng` → `espeak` fallback |

## Basic Usage

```ruby
require 'shared_tools'
require 'shared_tools/tools/notification'

tool = SharedTools::Tools::NotificationTool.new

# Desktop banner
tool.execute(action: "notify", message: "Build complete", title: "CI")

# Modal dialog — blocks until user clicks
result = tool.execute(action: "alert", message: "Deploy to production?", buttons: ["Yes", "No"])
result[:button]  # => "Yes" or "No"

# Text-to-speech
tool.execute(action: "speak", message: "Task finished successfully")
```

## Actions

### notify

Send a non-blocking desktop banner notification.

```ruby
tool.execute(
  action:   "notify",
  message:  "All tests passed",
  title:    "CI Pipeline",     # optional
  subtitle: "main branch",     # optional
  sound:    "Glass"            # optional, macOS only (e.g. "Glass", "Ping", "Basso")
)
# => { success: true, action: "notify" }
```

---

### alert

Show a modal dialog. **Blocks** until the user clicks a button. Returns the label of the clicked button.

```ruby
result = tool.execute(
  action:         "alert",
  message:        "This will delete all temp files. Continue?",
  title:          "Confirm",          # optional
  buttons:        ["Delete", "Cancel"], # optional, default: ["OK"]
  default_button: "Cancel"            # optional
)
result[:button]  # => "Delete" or "Cancel"
```

On Linux without a display (headless/SSH), falls back to a terminal prompt:

```
[ALERT] This will delete all temp files. Continue?
Options: 1) Delete  2) Cancel
Enter choice (1-2):
```

---

### speak

Speak text aloud using the system TTS engine. Non-blocking.

```ruby
tool.execute(
  action:  "speak",
  message: "Deployment complete",
  voice:   "Samantha",   # optional — macOS voice name or espeak voice code
  rate:    160           # optional — words per minute
)
# => { success: true, action: "speak" }
```

**Voice examples:**

| Platform | Voice examples |
|----------|---------------|
| macOS | `"Samantha"`, `"Alex"`, `"Victoria"`, `"Daniel"` |
| Linux espeak-ng | `"en"`, `"en-us"`, `"en-gb"`, `"fr"`, `"de"` |

---

## Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `action` | String | Yes | `notify`, `alert`, or `speak` |
| `message` | String | Yes | The message to display or speak |
| `title` | String | No | Title for notify or alert |
| `subtitle` | String | No | Subtitle for notify |
| `sound` | String | No | Sound name for notify (macOS only) |
| `buttons` | Array | No | Button labels for alert (default: `["OK"]`) |
| `default_button` | String | No | Default focused button for alert |
| `voice` | String | No | TTS voice name for speak |
| `rate` | Integer | No | Words per minute for speak |

## Response Shape

All actions return a Hash with a `:success` key:

```ruby
# notify / speak success
{ success: true, action: "notify" }

# alert success
{ success: true, button: "OK" }

# any failure
{ success: false, error: "notify-send not found. Install libnotify-bin." }
```

## Pluggable Drivers

The tool uses a driver pattern for platform abstraction. You can inject a driver for testing or custom backends:

```ruby
# Inject a stub for testing — no OS commands executed
class MyTestDriver < SharedTools::Tools::Notification::BaseDriver
  def notify(message:, **) = { success: true, action: "notify" }
  def alert(message:, buttons: ["OK"], **) = { success: true, button: buttons.first }
  def speak(text:, **) = { success: true, action: "speak" }
end

tool = SharedTools::Tools::NotificationTool.new(driver: MyTestDriver.new)
```

## Linux Prerequisites

Install the appropriate packages for each action:

```bash
# notify action
sudo apt install libnotify-bin      # Debian/Ubuntu
sudo dnf install libnotify          # Fedora
sudo pacman -S libnotify            # Arch

# alert action (GUI)
sudo apt install zenity

# speak action
sudo apt install espeak-ng          # recommended
sudo apt install espeak             # fallback
```

`alert` does not require `zenity` — it falls back to a terminal prompt automatically if no display server is available.

## Combining with Other Tools

Use `alert` to create human-in-the-loop checkpoints inside a workflow:

```ruby
chat = RubyLLM.chat.with_tools(
  SharedTools::Tools::WorkflowManagerTool.new,
  SharedTools::Tools::NotificationTool.new
)

chat.ask(<<~PROMPT)
  Start a deployment workflow. Before each major step, show an alert dialog
  asking for confirmation. Speak a summary when the workflow is complete.
PROMPT
```
