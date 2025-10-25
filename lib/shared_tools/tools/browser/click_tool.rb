# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      # @example
      #   browser = Watir::Browser.new(:chrome)
      #   tool = SharedTools::Tools::Browser::ClickTool.new(browser:)
      #   tool.execute(selector: "#some-id")
      #   tool.execute(selector: ".some-class")
      #   tool.execute(selector: "some text")
      #   tool.execute(selector: "//div[@role='button']")
      class ClickTool < ::RubyLLM::Tool
        def self.name = 'browser_click'

        description "A browser automation tool for clicking any clickable element."

        param :selector, desc: <<~TEXT
          A CSS selector to locate or interact with an element on the page:

           * 'form button[type="submit"]': selects a button with type submit
           * '.example': selects elements with the foo and bar classes
           * '#example': selects an element by ID
           * 'div#parent > span.child': selects span elements that are direct children of div elements
           * 'a[href="/login"]': selects an anchor tag with a specific href attribute
        TEXT

        def initialize(driver: nil, logger: nil)
          @driver = driver || default_driver
          @logger = logger || RubyLLM.logger
        end

        # @param selector [String] CSS selector, ID, text content, or other identifier for the element to click.
        def execute(selector:)
          @logger.info("#{self.class.name}##{__method__} selector=#{selector.inspect}")

          @driver.click(selector:)
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
