# frozen_string_literal: true

require "test_helper"

class NotificationToolTest < Minitest::Test
  # Minimal in-process driver for testing — no shell commands executed
  class StubDriver
    attr_reader :last_call

    def notify(message:, title: nil, subtitle: nil, sound: nil)
      @last_call = { action: :notify, message:, title:, subtitle:, sound: }
      { success: true, action: 'notify' }
    end

    def alert(message:, title: nil, buttons: ['OK'], default_button: nil)
      @last_call = { action: :alert, message:, title:, buttons:, default_button: }
      { success: true, button: buttons.first }
    end

    def speak(text:, voice: nil, rate: nil)
      @last_call = { action: :speak, text:, voice:, rate: }
      { success: true, action: 'speak' }
    end
  end

  class FailDriver
    def notify(**) = { success: false, error: 'test failure' }
    def alert(**)  = { success: false, error: 'test failure' }
    def speak(**)  = { success: false, error: 'test failure' }
  end

  def setup
    @driver = StubDriver.new
    @tool   = SharedTools::Tools::NotificationTool.new(driver: @driver)
  end

  # Tool metadata
  def test_tool_name
    assert_equal 'notification_tool', SharedTools::Tools::NotificationTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  # notify action
  def test_notify_returns_success
    result = @tool.execute(action: 'notify', message: 'Hello')
    assert result[:success]
  end

  def test_notify_passes_message_to_driver
    @tool.execute(action: 'notify', message: 'Build done', title: 'CI')
    assert_equal 'Build done', @driver.last_call[:message]
    assert_equal 'CI',         @driver.last_call[:title]
  end

  def test_notify_passes_subtitle_and_sound
    @tool.execute(action: 'notify', message: 'msg', subtitle: 'sub', sound: 'Glass')
    assert_equal 'sub',   @driver.last_call[:subtitle]
    assert_equal 'Glass', @driver.last_call[:sound]
  end

  def test_notify_missing_message_returns_error
    result = @tool.execute(action: 'notify', message: nil)
    refute result[:success]
    assert result[:error]
  end

  def test_notify_blank_message_returns_error
    result = @tool.execute(action: 'notify', message: '   ')
    refute result[:success]
    assert result[:error]
  end

  # alert action
  def test_alert_returns_success_with_button
    result = @tool.execute(action: 'alert', message: 'Continue?')
    assert result[:success]
    assert result[:button]
  end

  def test_alert_returns_first_button_by_default
    result = @tool.execute(action: 'alert', message: 'Sure?', buttons: ['Yes', 'No'])
    assert_equal 'Yes', result[:button]
  end

  def test_alert_defaults_buttons_to_ok
    @tool.execute(action: 'alert', message: 'OK?')
    assert_equal ['OK'], @driver.last_call[:buttons]
  end

  def test_alert_passes_title_and_default_button
    @tool.execute(action: 'alert', message: 'msg', title: 'Confirm', default_button: 'Yes')
    assert_equal 'Confirm', @driver.last_call[:title]
    assert_equal 'Yes',     @driver.last_call[:default_button]
  end

  def test_alert_missing_message_returns_error
    result = @tool.execute(action: 'alert', message: nil)
    refute result[:success]
    assert result[:error]
  end

  # speak action
  def test_speak_returns_success
    result = @tool.execute(action: 'speak', message: 'Hello world')
    assert result[:success]
  end

  def test_speak_passes_text_to_driver
    @tool.execute(action: 'speak', message: 'Task complete')
    assert_equal 'Task complete', @driver.last_call[:text]
  end

  def test_speak_passes_voice_and_rate
    @tool.execute(action: 'speak', message: 'Hi', voice: 'Samantha', rate: 180)
    assert_equal 'Samantha', @driver.last_call[:voice]
    assert_equal 180,        @driver.last_call[:rate]
  end

  def test_speak_missing_message_returns_error
    result = @tool.execute(action: 'speak', message: nil)
    refute result[:success]
    assert result[:error]
  end

  # unknown action
  def test_unknown_action_returns_error
    result = @tool.execute(action: 'explode', message: 'boom')
    refute result[:success]
    assert result[:error]
    assert_includes result[:error], 'Unknown action'
  end

  # response shape
  def test_result_always_has_success_key
    result = @tool.execute(action: 'notify', message: 'hi')
    assert result.key?(:success)
  end

  # driver failure propagates
  def test_driver_failure_propagates
    tool   = SharedTools::Tools::NotificationTool.new(driver: FailDriver.new)
    result = tool.execute(action: 'notify', message: 'hi')
    refute result[:success]
    assert result[:error]
  end

  # NullDriver
  def test_null_driver_returns_failure_for_notify
    null = SharedTools::Tools::Notification::NullDriver.new
    result = null.notify(message: 'hi')
    refute result[:success]
    assert_includes result[:error], 'not supported'
  end

  def test_null_driver_returns_failure_for_alert
    null = SharedTools::Tools::Notification::NullDriver.new
    result = null.alert(message: 'hi')
    refute result[:success]
  end

  def test_null_driver_returns_failure_for_speak
    null = SharedTools::Tools::Notification::NullDriver.new
    result = null.speak(text: 'hi')
    refute result[:success]
  end
end
