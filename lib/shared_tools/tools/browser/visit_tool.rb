# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      # @example
      #   driver = Selenium::WebDriver.for :chrome
      #   tool = SharedTools::Tools::Browser::VisitTool.new(driver:)
      #   tool.execute(to: "https://news.ycombinator.com")
      class VisitTool < ::RubyLLM::Tool
        def self.name = 'browser_visit'

        description "A browser automation tool for navigating to a specific URL."

        param :url, desc: "A URL (e.g. https://news.ycombinator.com)."

        def initialize(driver: nil, logger: nil)
          @driver = driver || default_driver
          @logger = logger || RubyLLM.logger
        end

        # @param url [String] A URL (e.g. https://news.ycombinator.com).
        def execute(url:)
          @logger.info("#{self.class.name}##{__method__} url=#{url.inspect}")

          @driver.goto(url:)
        end

      private

        def default_driver
          if defined?(Watir)
            WatirDriver.new(logger: @logger)
          else
            raise LoadError, "Browser tools require a driver. Either install the 'watir' gem or pass a driver: parameter"
          end
        end
      end
    end
  end
end
