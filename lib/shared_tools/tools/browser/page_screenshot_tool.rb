# frozen_string_literal: true

require "base64"

module SharedTools
  module Tools
    module Browser
      # A browser automation tool for taking screenshots of the current page.
      class PageScreenshotTool < ::RubyLLM::Tool
        def self.name = 'browser_page_screenshot'

        description "A browser automation tool for taking screenshots of the current page."

        def initialize(driver: nil, logger: nil)
          @driver = driver || default_driver
          @logger = logger || RubyLLM.logger
        end

        def execute
          @logger.info("#{self.class.name}##{__method__}")

          @driver.screenshot do |file|
            "data:image/png;base64,#{Base64.strict_encode64(file.read)}"
          end
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
