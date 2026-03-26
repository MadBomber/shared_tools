# frozen_string_literal: true

module SharedTools
  module Tools
    module Notification
      # Abstract base class for platform-specific notification drivers.
      # Subclasses must implement notify, alert, and speak.
      class BaseDriver
        # Show a non-blocking desktop banner notification.
        #
        # @param message [String]
        # @param title [String, nil]
        # @param subtitle [String, nil]
        # @param sound [String, nil]
        # @return [Hash]
        def notify(message:, title: nil, subtitle: nil, sound: nil)
          raise NotImplementedError, "#{self.class}##{__method__} undefined"
        end

        # Show a modal dialog and wait for the user to click a button.
        #
        # @param message [String]
        # @param title [String, nil]
        # @param buttons [Array<String>]
        # @param default_button [String, nil]
        # @return [Hash] includes :button with the label of the clicked button
        def alert(message:, title: nil, buttons: ['OK'], default_button: nil)
          raise NotImplementedError, "#{self.class}##{__method__} undefined"
        end

        # Speak text aloud using text-to-speech.
        #
        # @param text [String]
        # @param voice [String, nil]
        # @param rate [Integer, nil] words per minute
        # @return [Hash]
        def speak(text:, voice: nil, rate: nil)
          raise NotImplementedError, "#{self.class}##{__method__} undefined"
        end

        protected

        # @param cmd [String]
        # @return [Boolean]
        def command_available?(cmd)
          system("which #{cmd} > /dev/null 2>&1")
        end
      end
    end
  end
end
