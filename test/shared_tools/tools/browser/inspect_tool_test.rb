# frozen_string_literal: true

require "test_helper"

class InspectToolTest < Minitest::Test
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
            <button>Submit</button>
            <a href="/login">Login</a>
            <div class="container">
              <span>Hello World</span>
            </div>
          </body>
        </html>
      HTML
    end
  end

  def setup
    @driver = MockDriver.new
    @tool = SharedTools::Tools::Browser::InspectTool.new(driver: @driver)
  end

  def test_tool_name
    assert_equal 'browser_inspect', SharedTools::Tools::Browser::InspectTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_finds_elements_by_text
    skip "Nokogiri gem not installed" unless nokogiri_available?

    result = @tool.execute(text_content: "Submit")
    assert_kind_of String, result
    refute_equal "No elements found containing text: Submit", result
  end

  def test_returns_message_when_no_elements_found
    skip "Nokogiri gem not installed" unless nokogiri_available?

    result = @tool.execute(text_content: "NonexistentText")
    assert_equal "No elements found containing text: NonexistentText", result
  end

  def test_accepts_selector_parameter
    skip "Nokogiri gem not installed" unless nokogiri_available?

    result = @tool.execute(text_content: "Hello", selector: "div.container")
    assert_kind_of String, result
  end

  def test_accepts_context_size_parameter
    skip "Nokogiri gem not installed" unless nokogiri_available?

    result = @tool.execute(text_content: "Submit", context_size: 3)
    assert_kind_of String, result
  end
end
