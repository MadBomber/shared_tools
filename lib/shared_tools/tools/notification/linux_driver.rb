# frozen_string_literal: true

require 'open3'

module SharedTools
  module Tools
    module Notification
      # Linux notification driver.
      #
      # notify  — uses notify-send (libnotify); logs a warning if no display is available.
      # alert   — uses zenity when a display is present; falls back to a terminal prompt.
      # speak   — tries espeak-ng first, then espeak.
      class LinuxDriver < BaseDriver
        # @param message [String]
        # @param title [String, nil]
        # @param subtitle [String, nil] appended to the message body
        # @param sound [String, nil] ignored on Linux
        # @return [Hash]
        def notify(message:, title: nil, subtitle: nil, sound: nil)
          unless display_available?
            RubyLLM.logger.warn('NotificationTool: No display server available, cannot show notification')
            return { success: false, error: 'No display server available' }
          end

          unless command_available?('notify-send')
            return { success: false, error: 'notify-send not found. Install libnotify-bin (Debian/Ubuntu) or libnotify (Fedora/Arch).' }
          end

          body = [message, subtitle].compact.join("\n")
          cmd  = ['notify-send', (title || 'Notification'), body]
          _, stderr, status = Open3.capture3(*cmd)
          status.success? ? { success: true, action: 'notify' } : { success: false, error: stderr.strip }
        end

        # @param message [String]
        # @param title [String, nil]
        # @param buttons [Array<String>]
        # @param default_button [String, nil]
        # @return [Hash] includes :button with the label of the clicked button
        def alert(message:, title: nil, buttons: ['OK'], default_button: nil)
          if display_available? && command_available?('zenity')
            alert_zenity(message:, title:, buttons:, default_button:)
          else
            alert_terminal(message:, buttons:, default_button:)
          end
        end

        # @param text [String]
        # @param voice [String, nil] espeak voice name (e.g. 'en', 'en-us')
        # @param rate [Integer, nil] words per minute (espeak -s flag)
        # @return [Hash]
        def speak(text:, voice: nil, rate: nil)
          binary = espeak_binary
          unless binary
            return { success: false, error: 'espeak-ng or espeak not found. Install espeak-ng (recommended) or espeak.' }
          end

          cmd  = [binary, text]
          cmd += ['-v', voice]    if voice
          cmd += ['-s', rate.to_s] if rate
          _, stderr, status = Open3.capture3(*cmd)
          status.success? ? { success: true, action: 'speak' } : { success: false, error: stderr.strip }
        end

        private

        def display_available?
          ENV['DISPLAY'] || ENV['WAYLAND_DISPLAY']
        end

        def espeak_binary
          return 'espeak-ng' if command_available?('espeak-ng')
          return 'espeak'    if command_available?('espeak')
          nil
        end

        def alert_zenity(message:, title:, buttons:, default_button:)
          if buttons.length == 1
            cmd  = ['zenity', '--info', '--text', message]
            cmd += ['--title', title] if title
            _, stderr, status = Open3.capture3(*cmd)
            status.success? ? { success: true, button: buttons.first } : { success: false, error: stderr.strip }
          else
            ok_label     = buttons[0]
            cancel_label = buttons[1]
            cmd  = ['zenity', '--question', '--text', message,
                    '--ok-label', ok_label, '--cancel-label', cancel_label]
            cmd += ['--title', title] if title
            # zenity supports --extra-button for additional buttons beyond two
            buttons[2..].each { |b| cmd += ['--extra-button', b] } if buttons.length > 2

            stdout, stderr, status = Open3.capture3(*cmd)
            case status.exitstatus
            when 0 then { success: true, button: ok_label }
            when 1 then { success: true, button: cancel_label }
            else
              btn = stdout.strip
              btn.empty? ? { success: false, error: stderr.strip } : { success: true, button: btn }
            end
          end
        end

        def alert_terminal(message:, buttons:, default_button:)
          $stdout.puts "\n[ALERT] #{message}"
          $stdout.puts "Options: #{buttons.each_with_index.map { |b, i| "#{i + 1}) #{b}" }.join('  ')}"
          $stdout.print "Enter choice (1-#{buttons.length}): "
          $stdout.flush
          input  = $stdin.gets&.strip.to_i
          button = buttons[input - 1] || default_button || buttons.first
          { success: true, button: button }
        end
      end
    end
  end
end
