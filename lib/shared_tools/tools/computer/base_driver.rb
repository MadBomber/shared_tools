# frozen_string_literal: true

module SharedTools
  module Tools
    module Computer
      # A tool for interacting with a computer. Be careful with using as it can perform actions on your computer!
      #
      # @example
      #   class SomeDriver < BaseDriver
      #     @param text [String]
      #     def key(text:)
      #       # TODO
      #     end
      #
      #     # @param text [String]
      #     # @param duration [Integer]
      #     def hold_key(text:, duration:)
      #       # TODO
      #     end
      #
      #     # @return [Hash<{ x: Integer, y: Integer }>]
      #     def mouse_position
      #       # TODO
      #     end
      #
      #     # @param coordinate [Hash<{ x: Integer, y: Integer }>]
      #     # @param button [String] e.g. "left", "middle", "right"
      #     def mouse_move(coordinate:)
      #       # TODO
      #     end
      #
      #     # @param coordinate [Hash<{ x: Integer, y: Integer }>]
      #     # @param button [String] e.g. "left", "middle", "right"
      #     def mouse_click(coordinate:, button:)
      #       # TODO
      #     end
      #
      #     # @param coordinate [Hash<{ x: Integer, y: Integer }>]
      #     # @param button [String] e.g. "left", "middle", "right"
      #     def mouse_down(coordinate:, button:)
      #       # TODO
      #     end
      #
      #     # @param coordinate [Hash<{ x: Integer, y: Integer }>]
      #     # @param button [String] e.g. "left", "middle", "right"
      #     def mouse_up(coordinate:, button:)
      #       # TODO
      #     end
      #
      #     # @param text [String]
      #     def type(text:)
      #       # TODO
      #     end
      #
      #     # @param amount [Integer]
      #     # @param direction [String] e.g. "up", "down", "left", "right"
      #     def scroll(amount:, direction:)
      #       # TODO
      #     end
      #
      #     # @yield [file]
      #     # @yieldparam file [File]
      #     def screenshot
      #       # TODO
      #     end
      #   end
      class BaseDriver
        DEFAULT_MOUSE_BUTTON = "left"
        DEFAULT_DISPLAY_SCALE = 2

        # @!attr_accessor :display_height
        #   @return [Integer] the height of the display in pixels
        attr_accessor :display_width

        # @!attr_accessor :display_height
        #   @return [Integer] the height of the display in pixels
        attr_accessor :display_height

        # @!attr_accessor :display_number
        #   @return [Integer] the display number
        attr_accessor :display_number

        # @param display_width [Integer] the width of the display in pixels
        # @param display_height [Integer] the height of the display in pixels
        # @param display_number [Integer] the display number
        def initialize(display_width:, display_height:, display_number:)
          @display_width = display_width
          @display_height = display_height

          @display_number = display_number
        end

        # @param text [String]
        def key(text:)
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # @param text [String]
        # @param duration [Integer]
        def hold_key(text:, duration:)
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # @return [Hash<{ x: Integer, y: Integer }>]
        def mouse_position
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # @param coordinate [Hash<{ x: Integer, y: Integer }>]
        # @param button [String] e.g. "left", "middle", "right"
        def mouse_move(coordinate:)
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # @param coordinate [Hash<{ x: Integer, y: Integer }>]
        # @param button [String] e.g. "left", "middle", "right"
        def mouse_click(coordinate:, button:)
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # @param coordinate [Hash<{ x: Integer, y: Integer }>]
        # @param button [String] e.g. "left", "middle", "right"
        def mouse_down(coordinate:, button:)
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # @param coordinate [Hash<{ x: Integer, y: Integer }>]
        # @param button [String] e.g. "left", "middle", "right"
        def mouse_up(coordinate:, button:)
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # @param coordinate [Hash<{ x: Integer, y: Integer }>]
        # @param button [String] e.g. "left", "middle", "right"
        def mouse_drag(coordinate:, button: DEFAULT_MOUSE_BUTTON)
          mouse_down(coordinate: mouse_position, button:)
          mouse_move(coordinate:, button:)
          mouse_up(coordinate:, button:)
        end

        # @param coordinate [Hash<{ x: Integer, y: Integer }>]
        # @param button [String] e.g. "left", "middle", "right"
        def mouse_double_click(coordinate:, button:)
          2.times { mouse_click(coordinate:, button:) }
        end

        # @param coordinate [Hash<{ x: Integer, y: Integer }>]
        # @param button [String] e.g. "left", "middle", "right"
        def mouse_triple_click(coordinate:, button:)
          3.times { mouse_click(coordinate:, button:) }
        end

        # @param text [String]
        def type(text:)
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # @param amount [Integer]
        # @param direction [String] e.g. "up", "down", "left", "right"
        def scroll(amount:, direction:)
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # @yield [file]
        # @yieldparam file [File]
        def screenshot
          raise NotImplementedError, "#{self.class.name}##{__method__} undefined"
        end

        # @param duration [Integer]
        def wait(duration:)
          Kernel.sleep(duration)
        end
      end
    end
  end
end
