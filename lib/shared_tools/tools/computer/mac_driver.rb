# frozen_string_literal: true

module SharedTools
  module Tools
    module Computer
      # A driver for interacting with a Mac. Be careful with using as it can perform actions on your computer!
      class MacDriver < BaseDriver
        def initialize(keyboard: MacOS.keyboard, mouse: MacOS.mouse, display: MacOS.display)
          @keyboard = keyboard
          @mouse = mouse
          @display = display

          super(display_width: display.wide, display_height: display.high, display_number: display.id)
        end

        # @param text [String]
        def key(text:)
          @keyboard.keys(text)
        end

        # @param text [String]
        # @param duration [Integer]
        def hold_key(text:, duration:)
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # @return [Hash<{ x: Integer, y: Integer }>]
        def mouse_position
          position = @mouse.position
          x = position.x
          y = position.y

          {
            x:,
            y:,
          }
        end

        def mouse_move(coordinate:)
          x = coordinate[:x]
          y = coordinate[:y]

          @mouse.move(x:, y:)
        end

        # @param coordinate [Hash<{ x: Integer, y: Integer }>]
        # @param button [String] e.g. "left", "middle", "right"
        def mouse_click(coordinate:, button:)
          x = coordinate[:x]
          y = coordinate[:y]

          case button
          when "left" then @mouse.left_click(x:, y:)
          when "middle" then @mouse.middle_click(x:, y:)
          when "right" then @mouse.right_click(x:, y:)
          end
        end

        # @param coordinate [Hash<{ x: Integer, y: Integer }>]
        def mouse_down(coordinate:, button: DEFAULT_MOUSE_BUTTON)
          x = coordinate[:x]
          y = coordinate[:y]

          case button
          when "left" then @mouse.left_down(x:, y:)
          when "middle" then @mouse.middle_down(x:, y:)
          when "right" then @mouse.right_down(x:, y:)
          end
        end

        # @param coordinate [Hash<{ x: Integer, y: Integer }>]
        # @param button [String] e.g. "left", "middle", "right"
        def mouse_up(coordinate:, button: DEFAULT_MOUSE_BUTTON)
          x = coordinate[:x]
          y = coordinate[:y]

          case button
          when "left" then @mouse.left_up(x:, y:)
          when "middle" then @mouse.middle_up(x:, y:)
          when "right" then @mouse.right_up(x:, y:)
          end
        end

        # @param text [String]
        def type(text:)
          @keyboard.type(text)
        end

        # @param amount [Integer]
        # @param direction [String] e.g. "up", "down", "left", "right"
        def scroll(amount:, direction:)
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # @yield [file]
        # @yieldparam file [File]
        def screenshot(&)
          @display.screenshot(&)
        end
      end
    end
  end
end
