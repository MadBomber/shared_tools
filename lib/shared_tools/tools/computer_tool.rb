# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  module Tools
    # A tool for interacting with a computer. Be careful with using as it can perform actions on your computer!
    #
    # @example
    #   computer = SharedTools::Tools::ComputerTool.new
    #   computer.execute(action: 'mouse_position')
    #   computer.execute(action: 'type', text: 'Hello')
    class ComputerTool < ::RubyLLM::Tool
      def self.name = 'computer_tool' 
      description "A tool for interacting with a computer."

      module Action
        KEY = "key" # press a key
        HOLD_KEY = "hold_key" # hold a key
        MOUSE_POSITION = "mouse_position" # get the current (x, y) pixel coordinate of the cursor on the screen
        MOUSE_MOVE = "mouse_move" # move the cursor to a specific (x, y) pixel coordinate on the screen
        MOUSE_CLICK = "mouse_click" # click at a specific x / y coordinate
        MOUSE_DOWN = "mouse_down" # press the mouse button down
        MOUSE_DRAG = "mouse_drag" # drag the mouse to a specific x / y coordinate
        MOUSE_UP = "mouse_up" # release the mouse button
        MOUSE_DOUBLE_CLICK = "mouse_double_click" # double click at a specific x / y coordinate
        MOUSE_TRIPLE_CLICK = "mouse_triple_click" # triple click at a specific x / y coordinate
        TYPE = "type" # type a string
        SCROLL = "scroll"
        WAIT = "wait"
      end

      module MouseButton
        LEFT = "left"
        MIDDLE = "middle"
        RIGHT = "right"
      end

      module ScrollDirection
        UP = "up"
        DOWN = "down"
        LEFT = "left"
        RIGHT = "right"
      end

      ACTIONS = [
        Action::KEY,
        Action::HOLD_KEY,
        Action::MOUSE_POSITION,
        Action::MOUSE_MOVE,
        Action::MOUSE_CLICK,
        Action::MOUSE_DOWN,
        Action::MOUSE_DRAG,
        Action::MOUSE_UP,
        Action::TYPE,
        Action::SCROLL,
        Action::WAIT,
      ].freeze

      MOUSE_BUTTON_OPTIONS = [
        MouseButton::LEFT,
        MouseButton::MIDDLE,
        MouseButton::RIGHT,
      ].freeze

      SCROLL_DIRECTION_OPTIONS = [
        ScrollDirection::UP,
        ScrollDirection::DOWN,
        ScrollDirection::LEFT,
        ScrollDirection::RIGHT,
      ].freeze

      param :action, desc: <<~TEXT
        Options:
        * `#{Action::KEY}`: Press a single key / combination of keys on the keyboard:
          - supports xdotool's `key` syntax (e.g. "alt+Tab", "Return", "ctrl+s", etc)
        * `#{Action::HOLD_KEY}`: Hold down a key or multiple keys for a specified duration (in seconds):
          - supports xdotool's `key` syntax (e.g. "alt+Tab", "Return", "ctrl+s", etc)
        * `#{Action::MOUSE_POSITION}`: Get the current (x,y) pixel coordinate of the cursor on the screen.
        * `#{Action::MOUSE_MOVE}`: Move the cursor to a specified (x,y) pixel coordinate on the screen.
        * `#{Action::MOUSE_CLICK}`: Click the mouse button at the specified (x,y) pixel coordinate on the screen.
        * `#{Action::MOUSE_DOUBLE_CLICK}`: Double click at the specified (x,y) pixel coordinate on the screen.
        * `#{Action::MOUSE_TRIPLE_CLICK}`: Triple click at the specified (x,y) pixel coordinate on the screen.
        * `#{Action::MOUSE_DOWN}`: Press the mouse button at the specified (x,y) pixel coordinate on the screen.
        * `#{Action::MOUSE_DRAG}`: Click and drag the cursor to a specified (x, y) pixel coordinate on the screen.
        * `#{Action::MOUSE_UP}`: Release the mouse button at the specified (x,y) pixel coordinate on the screen.
        * `#{Action::TYPE}`: Type a string of text on the keyboard.
        * `#{Action::SCROLL}`: Scroll the screen in a specified direction by a specified amount of clicks of the scroll wheel.
        * `#{Action::WAIT}`: Wait for a specified duration (in seconds).
      TEXT

      param :coordinate, desc: <<~TEXT
        An (x,y) coordinate hash with integer values (e.g. {x: 100, y: 200}). Required for the following actions:
        * `#{Action::MOUSE_MOVE}`
        * `#{Action::MOUSE_CLICK}`
        * `#{Action::MOUSE_DOWN}`
        * `#{Action::MOUSE_DRAG}`
        * `#{Action::MOUSE_UP}`
        * `#{Action::MOUSE_DOUBLE_CLICK}`
        * `#{Action::MOUSE_TRIPLE_CLICK}`
      TEXT

      param :text, desc: <<~TEXT
        The text to type. Required for the following actions:
        * `#{Action::KEY}`
        * `#{Action::HOLD_KEY}`
        * `#{Action::TYPE}`
      TEXT

      param :duration, desc: <<~TEXT
        A duration in seconds. Required for the following actions:
        * `#{Action::HOLD_KEY}`
        * `#{Action::WAIT}`
      TEXT

      param :mouse_button, desc: <<~TEXT
        The mouse button to use. Required for the following actions:
        * `#{Action::MOUSE_CLICK}`
        * `#{Action::MOUSE_DOWN}`
        * `#{Action::MOUSE_DRAG}`
        * `#{Action::MOUSE_UP}`
        * `#{Action::MOUSE_DOUBLE_CLICK}`
        * `#{Action::MOUSE_TRIPLE_CLICK}`
      TEXT

      param :scroll_direction, desc: <<~TEXT
        The direction to scroll. Required for the following actions:
        * `#{Action::SCROLL}`
      TEXT

      param :scroll_amount, desc: <<~TEXT
        The amount of clicks to scroll. Required for the following actions:
        * `#{Action::SCROLL}`
      TEXT


      # @param driver [Computer::BaseDriver] optional, will attempt to create platform-specific driver if not provided
      # @param logger [Logger] optional logger
      def initialize(driver: nil, logger: nil)
        @logger = logger || RubyLLM.logger
        @driver = driver || default_driver
      end

      # @param action [String]
      # @param coordinate [Hash<{ width: Integer, height: Integer }>] the (x,y) coordinate
      # @param text [String]
      # @param duration [Integer] the duration in seconds
      # @param mouse_button [String] e.g. "left", "middle", "right"
      # @param scroll_direction [String] e.g. "up", "down", "left", "right"
      # @param scroll_amount [Integer] the amount of clicks to scroll
      def execute(
        action:,
        coordinate: nil,
        text: nil,
        duration: nil,
        mouse_button: nil,
        scroll_direction: nil,
        scroll_amount: nil
      )
        @logger.info({
          action:,
          coordinate:,
          text:,
          duration:,
          mouse_button:,
          scroll_direction:,
          scroll_amount:,
        }.compact.map { |key, value| "#{key}=#{value.inspect}" }.join(" "))

        case action
        when Action::KEY then @driver.key(text:)
        when Action::HOLD_KEY then @driver.hold_key(text:, duration:)
        when Action::MOUSE_POSITION then @driver.mouse_position
        when Action::MOUSE_MOVE then @driver.mouse_move(coordinate:)
        when Action::MOUSE_CLICK then @driver.mouse_click(coordinate:, button: mouse_button)
        when Action::MOUSE_DOUBLE_CLICK then @driver.mouse_double_click(coordinate:, button: mouse_button)
        when Action::MOUSE_TRIPLE_CLICK then @driver.mouse_triple_click(coordinate:, button: mouse_button)
        when Action::MOUSE_DOWN then @driver.mouse_down(coordinate:, button: mouse_button)
        when Action::MOUSE_UP then @driver.mouse_up(coordinate:, button: mouse_button)
        when Action::MOUSE_DRAG then @driver.mouse_drag(coordinate:, button: mouse_button)
        when Action::TYPE then @driver.type(text:)
        when Action::SCROLL then @driver.scroll(amount: scroll_amount, direction: scroll_direction)
        when Action::WAIT then @driver.wait(duration:)
        end
      end

    private

      # @return [Computer::BaseDriver]
      def default_driver
        if RUBY_PLATFORM.include?('darwin') && defined?(MacOS)
          Computer::MacDriver.new
        else
          raise LoadError, "ComputerTool requires a platform-specific driver. Either install the required gem for your platform or pass a driver: parameter"
        end
      end
    end
  end
end
