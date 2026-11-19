# frozen_string_literal: true

require "test_helper"

# Uses fake keyboard/mouse/display objects and stubs CGEventPost, so no real
# input events reach the desktop.
class MacDriverTest < Minitest::Test
  FakeDisplay = Struct.new(:wide, :high, :id)

  class FakeKeyboard
    attr_reader :calls

    def initialize = @calls = []
    def key_down(key, mask:) = @calls << [:down, key, mask]
    def key_up(key, mask:) = @calls << [:up, key, mask]
  end

  def setup
    skip "macOS only" unless RUBY_PLATFORM.include?("darwin")
    begin
      require "macos"
    rescue LoadError
      skip "the macos gem is not installed"
    end

    @keyboard = FakeKeyboard.new
    @driver = SharedTools::Tools::Computer::MacDriver.new(
      keyboard: @keyboard, mouse: Object.new, display: FakeDisplay.new(1920, 1080, 1)
    )
  end

  def test_hold_key_resolves_modifier_flags
    result = @driver.hold_key(text: "cmd+a", duration: 0)

    cmd = MacOS::Library::CoreGraphics::EventFlags.find("cmd")
    assert_equal [[:down, "a", cmd], [:up, "a", cmd]], @keyboard.calls
    assert result[:success]
  end

  def test_hold_key_releases_the_key_when_interrupted
    Kernel.stub(:sleep, ->(_) { raise Interrupt }) do
      assert_raises(Interrupt) { @driver.hold_key(text: "shift+a", duration: 5) }
    end

    assert_equal %i[down up], @keyboard.calls.map(&:first)
  end

  def test_scroll_posts_a_scroll_wheel_event
    posted = []
    MacOS::Library::CoreGraphics.stub(:CGEventPost, ->(tap, event) { posted << [tap, event] }) do
      result = @driver.scroll(amount: 3, direction: "down")
      assert_equal({ success: true, direction: "down", amount: 3 }, result)
    end

    assert_equal 1, posted.size
    assert_equal MacOS::Library::CoreGraphics::EventTapLocation::HID_EVENT_TAP, posted.first.first
  end
end
