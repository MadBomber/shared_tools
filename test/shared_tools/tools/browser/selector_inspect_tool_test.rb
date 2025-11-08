# frozen_string_literal: true

require "test_helper"

class SelectorInspectToolTest < Minitest::Test
  def nokogiri_available?
    begin
      require 'nokogiri'
      true
    rescue LoadError
      false
    end
  end

  class MockDriver
    def html
      <<~HTML
        <html>
          <body>
            <div id="header">
              <h1>Title</h1>
            </div>
            <div class="content">
              <button class="btn-primary">Submit</button>
              <button class="btn-secondary">Cancel</button>
            </div>
            <form id="login-form">
              <input type="text" name="username">
            </form>
          </body>
        </html>
      HTML
    end
  end

  def setup
    @driver = MockDriver.new
    @tool = SharedTools::Tools::Browser::SelectorInspectTool.new(driver: @driver)
  end

  def test_tool_name
    assert_equal 'browser_selector_inspect', SharedTools::Tools::Browser::SelectorInspectTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_finds_elements_by_css_selector
    skip "Nokogiri gem not installed" unless nokogiri_available?

    result = @tool.execute(selector: "button")
    assert_kind_of String, result
    assert_includes result, "Found 2 elements"
  end

  def test_finds_element_by_id
    skip "Nokogiri gem not installed" unless nokogiri_available?

    result = @tool.execute(selector: "#header")
    assert_kind_of String, result
    assert_includes result, "Found 1 elements"
  end

  def test_finds_elements_by_class
    skip "Nokogiri gem not installed" unless nokogiri_available?

    result = @tool.execute(selector: ".btn-primary")
    assert_kind_of String, result
    assert_includes result, "Found 1 elements"
  end

  def test_returns_message_when_no_elements_found
    skip "Nokogiri gem not installed" unless nokogiri_available?

    result = @tool.execute(selector: ".nonexistent")
    assert_equal "No elements found matching selector: .nonexistent", result
  end

  def test_accepts_context_size_parameter
    skip "Nokogiri gem not installed" unless nokogiri_available?

    result = @tool.execute(selector: "h1", context_size: 1)
    assert_kind_of String, result
  end

  def test_context_size_zero_works
    skip "Nokogiri gem not installed" unless nokogiri_available?

    result = @tool.execute(selector: "button", context_size: 0)
    assert_kind_of String, result
  end
end
