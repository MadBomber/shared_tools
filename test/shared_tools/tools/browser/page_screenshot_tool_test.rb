# frozen_string_literal: true

require "test_helper"
require "tempfile"
require "tmpdir"

class PageScreenshotToolTest < Minitest::Test
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

  def test_returns_saved_path_hash
    result = @tool.execute
    assert_kind_of Hash, result
    assert_equal :ok, result[:status]
    assert result[:saved_to]
    assert_match(/\.png$/, result[:saved_to])
  end

  def test_screenshot_file_exists_after_capture
    result = @tool.execute
    assert File.exist?(result[:saved_to])
  ensure
    File.delete(result[:saved_to]) if result && result[:saved_to] && File.exist?(result[:saved_to])
  end

  def test_custom_path_is_used
    custom_path = File.join(Dir.tmpdir, "custom_test_#{Time.now.to_i}.png")
    result = @tool.execute(path: custom_path)
    assert_equal File.expand_path(custom_path), result[:saved_to]
  ensure
    File.delete(custom_path) if File.exist?(custom_path)
  end
end
