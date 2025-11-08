# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "base64"

class PageScreenshotToolTest < Minitest::Test
  def nokogiri_available?
    begin
      require 'nokogiri'
      true
    rescue LoadError
      false
    end
  end

  class MockDriver
    def screenshot
      # Create a minimal PNG file (1x1 transparent pixel)
      png_data = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==")

      Tempfile.create(['screenshot', '.png']) do |file|
        file.binmode
        file.write(png_data)
        file.rewind
        yield file
      end
    end
  end

  def setup
    @driver = MockDriver.new
    @tool = SharedTools::Tools::Browser::PageScreenshotTool.new(driver: @driver)
  end

  def test_tool_name
    assert_equal 'browser_page_screenshot', SharedTools::Tools::Browser::PageScreenshotTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_returns_base64_encoded_screenshot
    skip "Nokogiri gem not installed" unless nokogiri_available?

    result = @tool.execute
    assert_kind_of String, result
    assert_match /^data:image\/png;base64,/, result
  end

  def test_screenshot_is_valid_base64
    skip "Nokogiri gem not installed" unless nokogiri_available?

    result = @tool.execute
    base64_data = result.sub(/^data:image\/png;base64,/, '')

    # Should successfully decode without raising an error
    decoded = Base64.strict_decode64(base64_data)
    assert decoded.length > 0
  end
end
