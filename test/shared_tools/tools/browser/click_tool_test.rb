# frozen_string_literal: true

require "test_helper"

class ClickToolTest < Minitest::Test
  def nokogiri_available?
    begin
      require 'nokogiri'
      true
    rescue LoadError
      false
    end
  end

  class MockDriver
    attr_reader :last_selector

    def click(selector:)
      @last_selector = selector
      "Clicked #{selector}"
    end
  end

  def setup
    @driver = MockDriver.new
    @tool = SharedTools::Tools::Browser::ClickTool.new(driver: @driver)
  end

  def test_tool_name
    assert_equal 'browser_click', SharedTools::Tools::Browser::ClickTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_clicks_element_by_css_selector
    skip "Nokogiri gem not installed" unless nokogiri_available?

    @tool.execute(selector: "button[type='submit']")
    assert_equal "button[type='submit']", @driver.last_selector
  end

  def test_clicks_element_by_id
    skip "Nokogiri gem not installed" unless nokogiri_available?

    @tool.execute(selector: "#my-button")
    assert_equal "#my-button", @driver.last_selector
  end

  def test_clicks_element_by_class
    skip "Nokogiri gem not installed" unless nokogiri_available?

    @tool.execute(selector: ".btn-primary")
    assert_equal ".btn-primary", @driver.last_selector
  end

  def test_clicks_complex_selector
    skip "Nokogiri gem not installed" unless nokogiri_available?

    @tool.execute(selector: "div#parent > span.child")
    assert_equal "div#parent > span.child", @driver.last_selector
  end
end
