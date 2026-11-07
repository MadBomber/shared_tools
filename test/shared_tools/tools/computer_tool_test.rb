# frozen_string_literal: true

require "test_helper"
require "open3"
require "rbconfig"

class ComputerToolTest < Minitest::Test
  class MockDriver
    attr_reader :last_action, :last_params

    def key(text:)
      @last_action = :key
      @last_params = { text: text }
      "Pressed key: #{text}"
    end

    def hold_key(text:, duration:)
      @last_action = :hold_key
      @last_params = { text: text, duration: duration }
      "Held key: #{text} for #{duration}s"
    end

    def mouse_position
      @last_action = :mouse_position
      @last_params = {}
      { x: 100, y: 200 }
    end

    def mouse_move(coordinate:)
      @last_action = :mouse_move
      @last_params = { coordinate: coordinate }
      "Moved to #{coordinate}"
    end

    def mouse_click(coordinate:, button:)
      @last_action = :mouse_click
      @last_params = { coordinate: coordinate, button: button }
      "Clicked #{button} at #{coordinate}"
    end

    def mouse_double_click(coordinate:, button:)
      @last_action = :mouse_double_click
      @last_params = { coordinate: coordinate, button: button }
      "Double clicked #{button} at #{coordinate}"
    end

    def mouse_triple_click(coordinate:, button:)
      @last_action = :mouse_triple_click
      @last_params = { coordinate: coordinate, button: button }
      "Triple clicked #{button} at #{coordinate}"
    end

    def mouse_down(coordinate:, button:)
      @last_action = :mouse_down
      @last_params = { coordinate: coordinate, button: button }
      "Mouse down #{button} at #{coordinate}"
    end

    def mouse_up(coordinate:, button:)
      @last_action = :mouse_up
      @last_params = { coordinate: coordinate, button: button }
      "Mouse up #{button} at #{coordinate}"
    end

    def mouse_drag(coordinate:, button:)
      @last_action = :mouse_drag
      @last_params = { coordinate: coordinate, button: button }
      "Dragged to #{coordinate}"
    end

    def type(text:)
      @last_action = :type
      @last_params = { text: text }
      "Typed: #{text}"
    end

    def scroll(amount:, direction:)
      @last_action = :scroll
      @last_params = { amount: amount, direction: direction }
      "Scrolled #{direction} by #{amount}"
    end

    def wait(duration:)
      @last_action = :wait
      @last_params = { duration: duration }
      "Waited #{duration}s"
    end
  end

  def setup
    @driver = MockDriver.new
    @tool = SharedTools::Tools::ComputerTool.new(driver: @driver)
  end

  def test_tool_name
    assert_equal 'computer', SharedTools::Tools::ComputerTool.tool_name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_has_all_action_constants
    assert_equal "key", SharedTools::Tools::ComputerTool::Action::KEY
    assert_equal "hold_key", SharedTools::Tools::ComputerTool::Action::HOLD_KEY
    assert_equal "mouse_position", SharedTools::Tools::ComputerTool::Action::MOUSE_POSITION
    assert_equal "mouse_move", SharedTools::Tools::ComputerTool::Action::MOUSE_MOVE
    assert_equal "mouse_click", SharedTools::Tools::ComputerTool::Action::MOUSE_CLICK
    assert_equal "mouse_down", SharedTools::Tools::ComputerTool::Action::MOUSE_DOWN
    assert_equal "mouse_drag", SharedTools::Tools::ComputerTool::Action::MOUSE_DRAG
    assert_equal "mouse_up", SharedTools::Tools::ComputerTool::Action::MOUSE_UP
    assert_equal "type", SharedTools::Tools::ComputerTool::Action::TYPE
    assert_equal "scroll", SharedTools::Tools::ComputerTool::Action::SCROLL
    assert_equal "wait", SharedTools::Tools::ComputerTool::Action::WAIT
  end

  def test_key_action
    @tool.execute(action: SharedTools::Tools::ComputerTool::Action::KEY, text: "Return")
    assert_equal :key, @driver.last_action
    assert_equal "Return", @driver.last_params[:text]
  end

  def test_hold_key_action
    @tool.execute(
      action: SharedTools::Tools::ComputerTool::Action::HOLD_KEY,
      text: "ctrl+c",
      duration: 2
    )
    assert_equal :hold_key, @driver.last_action
    assert_equal "ctrl+c", @driver.last_params[:text]
    assert_equal 2, @driver.last_params[:duration]
  end

  def test_mouse_position_action
    result = @tool.execute(action: SharedTools::Tools::ComputerTool::Action::MOUSE_POSITION)
    assert_equal :mouse_position, @driver.last_action
    assert_kind_of Hash, result
  end

  def test_mouse_move_action
    @tool.execute(
      action: SharedTools::Tools::ComputerTool::Action::MOUSE_MOVE,
      coordinate: { x: 100, y: 200 }
    )
    assert_equal :mouse_move, @driver.last_action
    assert_equal({ x: 100, y: 200 }, @driver.last_params[:coordinate])
  end

  def test_mouse_click_action
    @tool.execute(
      action: SharedTools::Tools::ComputerTool::Action::MOUSE_CLICK,
      coordinate: { x: 150, y: 250 },
      mouse_button: "left"
    )
    assert_equal :mouse_click, @driver.last_action
    assert_equal({ x: 150, y: 250 }, @driver.last_params[:coordinate])
    assert_equal "left", @driver.last_params[:button]
  end

  def test_type_action
    @tool.execute(
      action: SharedTools::Tools::ComputerTool::Action::TYPE,
      text: "Hello World"
    )
    assert_equal :type, @driver.last_action
    assert_equal "Hello World", @driver.last_params[:text]
  end

  def test_scroll_action
    @tool.execute(
      action: SharedTools::Tools::ComputerTool::Action::SCROLL,
      scroll_direction: "down",
      scroll_amount: 5
    )
    assert_equal :scroll, @driver.last_action
    assert_equal "down", @driver.last_params[:direction]
    assert_equal 5, @driver.last_params[:amount]
  end

  def test_wait_action
    @tool.execute(
      action: SharedTools::Tools::ComputerTool::Action::WAIT,
      duration: 3
    )
    assert_equal :wait, @driver.last_action
    assert_equal 3, @driver.last_params[:duration]
  end

  def test_mouse_button_constants
    assert_equal "left", SharedTools::Tools::ComputerTool::MouseButton::LEFT
    assert_equal "middle", SharedTools::Tools::ComputerTool::MouseButton::MIDDLE
    assert_equal "right", SharedTools::Tools::ComputerTool::MouseButton::RIGHT
  end

  def test_scroll_direction_constants
    assert_equal "up", SharedTools::Tools::ComputerTool::ScrollDirection::UP
    assert_equal "down", SharedTools::Tools::ComputerTool::ScrollDirection::DOWN
    assert_equal "left", SharedTools::Tools::ComputerTool::ScrollDirection::LEFT
    assert_equal "right", SharedTools::Tools::ComputerTool::ScrollDirection::RIGHT
  end

  def test_default_driver_raises_load_error_without_mac_driver
    tool = SharedTools::Tools::ComputerTool.new(logger: Logger.new(IO::NULL))
    tool.stub(:mac_driver_available?, false) do
      error = assert_raises(LoadError) { tool.send(:default_driver) }
      assert_match(/driver: parameter/, error.message)
    end
  end

  # Same defect as issue #3: under aia, `SharedTools.load_all_tools` loads
  # ComputerTool but nothing requires the macos gem, so `defined?(MacOS)` was
  # false even with the gem installed. Run in a fresh process so this suite's
  # own requires can't hide that.
  def test_default_driver_finds_the_installed_macos_gem_in_a_fresh_process
    skip "macOS only" unless RUBY_PLATFORM.include?("darwin")
    skip "the macos gem is not installed" if Gem::Specification.find_all_by_name("macos").empty?

    script = <<~RUBY
      require "shared_tools"
      SharedTools.load_all_tools
      tool = SharedTools::Tools::ComputerTool.new(logger: Logger.new(IO::NULL))
      exit(tool.send(:default_driver).is_a?(SharedTools::Tools::Computer::MacDriver) ? 0 : 1)
    RUBY
    lib = File.expand_path("../../../lib", __dir__)
    _out, err, status = Open3.capture3(RbConfig.ruby, "-I", lib, "-e", script)

    assert status.success?, "ComputerTool#default_driver failed with the macos gem installed\n#{err}"
  end
end
