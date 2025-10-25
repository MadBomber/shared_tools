# frozen_string_literal: true

require "test_helper"

class PageInspectToolTest < Minitest::Test
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
          <head><title>Test Page</title></head>
          <body>
            <h1>Welcome</h1>
            <button>Click Me</button>
            <form>
              <input type="text" name="username">
              <input type="submit" value="Submit">
            </form>
          </body>
        </html>
      HTML
    end
  end

  def setup
    @driver = MockDriver.new
    @tool = SharedTools::Tools::Browser::PageInspectTool.new(driver: @driver)
  end

  def test_tool_name
    assert_equal 'browser_page_inspect', SharedTools::Tools::Browser::PageInspectTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_returns_full_html_by_default
    skip "Nokogiri gem not installed" unless nokogiri_available?

    result = @tool.execute
    assert_kind_of String, result
    assert_includes result, "<html>"
    assert_includes result, "</html>"
  end

  def test_returns_summary_when_requested
    skip "Nokogiri gem not installed" unless nokogiri_available?

    result = @tool.execute(summarize: true)
    assert_kind_of String, result
    # Summary should be different from full HTML
    # It should be a formatted summary of interactive elements
  end

  def test_full_html_contains_page_content
    skip "Nokogiri gem not installed" unless nokogiri_available?

    result = @tool.execute
    assert_includes result, "Welcome"
    assert_includes result, "Click Me"
  end
end
