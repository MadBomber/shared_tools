# frozen_string_literal: true

require "test_helper"

class BrowserToolTest < Minitest::Test
  def nokogiri_available?
    begin
      require 'nokogiri'
      true
    rescue LoadError
      false
    end
  end

  class MockDriver
    attr_reader :last_url, :last_selector, :last_text

    def goto(url:)
      @last_url = url
      "Navigated to #{url}"
    end

    def html
      "<html><body><h1>Test</h1></body></html>"
    end

    def click(selector:)
      @last_selector = selector
      "Clicked #{selector}"
    end

    def fill_in(selector:, text:)
      @last_selector = selector
      @last_text = text
      "Filled in #{selector}"
    end

    def screenshot
      require 'tempfile'
      require 'base64'
      png_data = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")
      Tempfile.create(['screenshot', '.png']) do |file|
        file.binmode
        file.write(png_data)
        file.rewind
        yield file
      end
    end

    def close
      "Closed browser"
    end
  end

  def setup
    @driver = MockDriver.new
    @tool = SharedTools::Tools::BrowserTool.new(driver: @driver)
  end

  def test_tool_name
    assert_equal 'browser_tool', SharedTools::Tools::BrowserTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_has_all_action_constants
    assert_equal "visit", SharedTools::Tools::BrowserTool::Action::VISIT
    assert_equal "page_inspect", SharedTools::Tools::BrowserTool::Action::PAGE_INSPECT
    assert_equal "ui_inspect", SharedTools::Tools::BrowserTool::Action::UI_INSPECT
    assert_equal "selector_inspect", SharedTools::Tools::BrowserTool::Action::SELECTOR_INSPECT
    assert_equal "click", SharedTools::Tools::BrowserTool::Action::CLICK
    assert_equal "text_field_set", SharedTools::Tools::BrowserTool::Action::TEXT_FIELD_SET
    assert_equal "screenshot", SharedTools::Tools::BrowserTool::Action::SCREENSHOT
  end

  def test_visit_action
    @tool.execute(action: SharedTools::Tools::BrowserTool::Action::VISIT, url: "https://example.com")
    assert_equal "https://example.com", @driver.last_url
  end

  def test_page_inspect_action
    skip "Nokogiri gem not installed" unless nokogiri_available?
    result = @tool.execute(action: SharedTools::Tools::BrowserTool::Action::PAGE_INSPECT)
    assert_kind_of String, result
  end

  def test_page_inspect_with_full_html
    skip "Nokogiri gem not installed" unless nokogiri_available?
    result = @tool.execute(
      action: SharedTools::Tools::BrowserTool::Action::PAGE_INSPECT,
      full_html: true
    )
    assert_kind_of String, result
  end

  def test_ui_inspect_action
    skip "Nokogiri gem not installed" unless nokogiri_available?
    result = @tool.execute(
      action: SharedTools::Tools::BrowserTool::Action::UI_INSPECT,
      text_content: "Test"
    )
    assert_kind_of String, result
  end

  def test_selector_inspect_action
    skip "Nokogiri gem not installed" unless nokogiri_available?
    result = @tool.execute(
      action: SharedTools::Tools::BrowserTool::Action::SELECTOR_INSPECT,
      selector: "h1"
    )
    assert_kind_of String, result
  end

  def test_click_action
    @tool.execute(
      action: SharedTools::Tools::BrowserTool::Action::CLICK,
      selector: "button"
    )
    assert_equal "button", @driver.last_selector
  end

  def test_text_field_set_action
    @tool.execute(
      action: SharedTools::Tools::BrowserTool::Action::TEXT_FIELD_SET,
      selector: "#username",
      value: "john_doe"
    )
    assert_equal "#username", @driver.last_selector
    assert_equal "john_doe", @driver.last_text
  end

  def test_screenshot_action
    result = @tool.execute(action: SharedTools::Tools::BrowserTool::Action::SCREENSHOT)
    assert_kind_of String, result
    assert_match /^data:image\/png;base64,/, result
  end

  def test_cleanup_closes_driver
    @tool.cleanup!
    # Just verify it doesn't raise an error
    assert true
  end

  def test_raises_error_for_missing_required_params
    error = assert_raises(ArgumentError) do
      @tool.execute(action: SharedTools::Tools::BrowserTool::Action::VISIT)
    end
    assert_includes error.message, "url"
  end
end
