# frozen_string_literal: true

module SharedTools
  module Tools
    module Notification
      # Fallback driver for unsupported platforms.
      # All actions return a failure response with a clear error message.
      class NullDriver < BaseDriver
        def notify(message:, title: nil, subtitle: nil, sound: nil)
          unsupported
        end

        def alert(message:, title: nil, buttons: ['OK'], default_button: nil)
          unsupported
        end

        def speak(text:, voice: nil, rate: nil)
          unsupported
        end

        private

        def unsupported
          { success: false, error: "NotificationTool is not supported on platform: #{RUBY_PLATFORM}" }
        end
      end
    end
  end
end
