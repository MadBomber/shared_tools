# frozen_string_literal: true

require "test_helper"

class TextFieldAreaSetToolTest < Minitest::Test
  def nokogiri_available?
    begin
      require 'nokogiri'
      true
    rescue LoadError
      false
    end
  end

  class MockDriver
    attr_reader :last_selector, :last_text

    def fill_in(selector:, text:)
      @last_selector = selector
      @last_text = text
      "Filled in #{selector} with #{text}"
    end
  end

  def setup
    @driver = MockDriver.new
    @tool = SharedTools::Tools::Browser::TextFieldAreaSetTool.new(driver: @driver)
  end

  def test_tool_name
    assert_equal 'browser_text_field_set', SharedTools::Tools::Browser::TextFieldAreaSetTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_fills_in_text_field
    skip "Nokogiri gem not installed" unless nokogiri_available?

    @tool.execute(selector: "#username", text: "john_doe")
    assert_equal "#username", @driver.last_selector
    assert_equal "john_doe", @driver.last_text
  end

  def test_fills_in_textarea
    skip "Nokogiri gem not installed" unless nokogiri_available?

    @tool.execute(selector: "textarea[name='description']", text: "Long text here")
    assert_equal "textarea[name='description']", @driver.last_selector
    assert_equal "Long text here", @driver.last_text
  end

  def test_handles_empty_text
    skip "Nokogiri gem not installed" unless nokogiri_available?

    @tool.execute(selector: "#field", text: "")
    assert_equal "#field", @driver.last_selector
    assert_equal "", @driver.last_text
  end

  def test_handles_special_characters
    skip "Nokogiri gem not installed" unless nokogiri_available?

    special_text = "Test@123!#$%"
    @tool.execute(selector: "#password", text: special_text)
    assert_equal "#password", @driver.last_selector
    assert_equal special_text, @driver.last_text
  end
end
