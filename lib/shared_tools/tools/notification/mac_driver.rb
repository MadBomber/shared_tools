# frozen_string_literal: true

require 'open3'

module SharedTools
  module Tools
    module Notification
      # macOS notification driver using osascript and the say command.
      class MacDriver < BaseDriver
        # @param message [String]
        # @param title [String, nil]
        # @param subtitle [String, nil]
        # @param sound [String, nil] e.g. 'Glass', 'Ping'
        # @return [Hash]
        def notify(message:, title: nil, subtitle: nil, sound: nil)
          parts = ["display notification #{message.inspect}"]
          parts << "with title #{title.inspect}" if title
          parts << "subtitle #{subtitle.inspect}"  if subtitle
          parts << "sound name #{sound.inspect}"   if sound
          run_osascript(parts.join(' '))
            .then { |r| r[:success] ? r.merge(action: 'notify') : r }
        end

        # @param message [String]
        # @param title [String, nil]
        # @param buttons [Array<String>]
        # @param default_button [String, nil]
        # @return [Hash] includes :button with label of clicked button
        def alert(message:, title: nil, buttons: ['OK'], default_button: nil)
          btn_list  = buttons.map(&:inspect).join(', ')
          script    = "display dialog #{message.inspect}"
          script   += " with title #{title.inspect}" if title
          script   += " buttons {#{btn_list}}"
          script   += " default button #{default_button.inspect}" if default_button

          stdout, stderr, status = Open3.capture3('osascript', '-e', script)
          if status.success?
            button = stdout.match(/button returned:(.+)/i)&.captures&.first&.strip
            { success: true, button: button }
          else
            { success: false, error: stderr.strip }
          end
        end

        # @param text [String]
        # @param voice [String, nil] e.g. 'Samantha'
        # @param rate [Integer, nil] words per minute
        # @return [Hash]
        def speak(text:, voice: nil, rate: nil)
          cmd  = ['say', text]
          cmd += ['-v', voice]    if voice
          cmd += ['-r', rate.to_s] if rate
          _, stderr, status = Open3.capture3(*cmd)
          status.success? ? { success: true, action: 'speak' } : { success: false, error: stderr.strip }
        end

        private

        def run_osascript(script)
          _, stderr, status = Open3.capture3('osascript', '-e', script)
          status.success? ? { success: true } : { success: false, error: stderr.strip }
        end
      end
    end
  end
end
