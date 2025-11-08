# frozen_string_literal: true

require "test_helper"

class VisitToolTest < Minitest::Test
  def nokogiri_available?
    begin
      require 'nokogiri'
      true
    rescue LoadError
      false
    end
  end

  class MockDriver
    attr_reader :last_url

    def goto(url:)
      @last_url = url
      "Navigated to #{url}"
    end
  end

  def setup
    @driver = MockDriver.new
    @tool = SharedTools::Tools::Browser::VisitTool.new(driver: @driver)
  end

  def test_tool_name
    assert_equal 'browser_visit', SharedTools::Tools::Browser::VisitTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_visits_url_successfully
    skip "Nokogiri gem not installed" unless nokogiri_available?

    url = "https://example.com"
    @tool.execute(url: url)
    assert_equal url, @driver.last_url
  end

  def test_visits_different_urls
    skip "Nokogiri gem not installed" unless nokogiri_available?

    @tool.execute(url: "https://first.com")
    assert_equal "https://first.com", @driver.last_url

    @tool.execute(url: "https://second.com")
    assert_equal "https://second.com", @driver.last_url
  end

  def test_raises_error_without_driver_when_watir_not_loaded
    # When Watir is not loaded, creating a tool without a driver should raise LoadError
    assert_raises(LoadError) do
      SharedTools::Tools::Browser::VisitTool.new
    end
  end
end
