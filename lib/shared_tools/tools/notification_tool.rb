# frozen_string_literal: true

module SharedTools
  module Tools
    # Cross-platform notification tool for desktop banners, modal dialogs, and TTS.
    #
    # Supports macOS (osascript, say) and Linux (notify-send, zenity/terminal, espeak-ng/espeak).
    # On unsupported platforms all actions return {success: false}.
    #
    # @example Desktop notification
    #   tool = SharedTools::Tools::NotificationTool.new
    #   tool.execute(action: 'notify', message: 'Build complete', title: 'CI')
    #
    # @example Modal alert
    #   result = tool.execute(action: 'alert', message: 'Deploy to production?', buttons: ['Yes', 'No'])
    #   result[:button] # => 'Yes' or 'No'
    #
    # @example Text-to-speech
    #   tool.execute(action: 'speak', message: 'Task finished')
    class NotificationTool < ::RubyLLM::Tool
      def self.name = 'notification_tool'

      description <<~DESC.strip
        Send desktop notifications, modal alerts, or text-to-speech messages.
        Supports macOS and Linux. On macOS uses osascript and say.
        On Linux uses notify-send, zenity (or terminal fallback), and espeak-ng/espeak.
      DESC

      params do
        string :action, description: <<~TEXT.strip
          The notification action to perform:
          * `notify` — Non-blocking desktop banner notification.
          * `alert`  — Modal dialog; waits for the user to click a button. Returns the button label.
          * `speak`  — Speak text aloud using text-to-speech.
        TEXT

        string :message, description: "The message to display or speak. Required for all actions."

        string :title, description: "Title for the notification or alert dialog. Optional.", required: false

        string :subtitle, description: "Subtitle line (notify action, macOS and Linux). Optional.", required: false

        string :sound, description: "Sound name to play with a notification (macOS only, e.g. 'Glass', 'Ping'). Optional.", required: false

        array :buttons, of: :string, description: <<~TEXT.strip, required: false
          Button labels for the alert dialog (e.g. ['Yes', 'No']). Defaults to ['OK'].
        TEXT

        string :default_button, description: "Default focused button label for the alert dialog. Optional.", required: false

        string :voice, description: "TTS voice name for the speak action (e.g. 'Samantha' on macOS, 'en' on Linux). Optional.", required: false

        integer :rate, description: "Speech rate in words per minute for the speak action. Optional.", required: false
      end

      # @param driver [Notification::BaseDriver] optional; auto-detected from platform if omitted
      def initialize(driver: nil)
        @driver = driver || default_driver
      end

      def execute(action:, message: nil, title: nil, subtitle: nil, sound: nil,
                  buttons: nil, default_button: nil, voice: nil, rate: nil)
        buttons ||= ['OK']

        case action
        when 'notify'
          return missing_param('message', 'notify') if blank?(message)
          @driver.notify(message:, title:, subtitle:, sound:)
        when 'alert'
          return missing_param('message', 'alert') if blank?(message)
          @driver.alert(message:, title:, buttons:, default_button:)
        when 'speak'
          return missing_param('message', 'speak') if blank?(message)
          @driver.speak(text: message, voice:, rate:)
        else
          { success: false, error: "Unknown action: #{action.inspect}. Must be notify, alert, or speak." }
        end
      end

      private

      def default_driver
        case RUBY_PLATFORM
        when /darwin/ then Notification::MacDriver.new
        when /linux/  then Notification::LinuxDriver.new
        else               Notification::NullDriver.new
        end
      end

      def blank?(value)
        value.nil? || value.to_s.strip.empty?
      end

      def missing_param(param, action)
        { success: false, error: "'#{param}' is required for the #{action} action" }
      end
    end
  end
end
