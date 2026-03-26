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
          options = text.to_s.split('+')
          key     = options.pop
          mask    = options.reduce(0) { |m, opt| m | Library::CoreGraphics::EventFlags.find(opt) }

          @keyboard.key_down(key, mask: mask)
          Kernel.sleep(duration.to_f)
          @keyboard.key_up(key, mask: mask)

          { success: true, key: text, duration: duration }
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

        # @param amount [Integer]    number of scroll units
        # @param direction [String] "up", "down", "left", or "right"
        def scroll(amount:, direction:)
          # Attach CGEventCreateScrollWheelEvent2 if not already done
          unless Library::CoreGraphics.respond_to?(:CGEventCreateScrollWheelEvent2)
            Library::CoreGraphics.module_eval do
              attach_function :CGEventCreateScrollWheelEvent2,
                              [:pointer, :uint32, :uint32, :int32, :int32, :int32],
                              :pointer
            end
          end

          amt = amount.to_i
          # kCGScrollEventUnitLine = 1; wheel_count = 2 (vertical + horizontal)
          delta_y, delta_x = case direction.to_s.downcase
                             when 'up'    then [ amt,  0]
                             when 'down'  then [-amt,  0]
                             when 'left'  then [0, -amt]
                             when 'right' then [0,  amt]
                             else              [0,    0]
                             end

          event = Library::CoreGraphics.CGEventCreateScrollWheelEvent2(nil, 1, 2, delta_y, delta_x, 0)
          Library::CoreGraphics.CGEventPost(
            Library::CoreGraphics::EventTapLocation::HID_EVENT_TAP, event
          )
          Library::CoreGraphics.CFRelease(event)

          { success: true, direction: direction, amount: amt }
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
