# frozen_string_literal: true

require "watir"

module SharedTools
  module Tools
    module Browser
      # @example
      #   class SeleniumTool < BaseTool
      #     # ...
      #   end
      class BaseTool 
        # @param logger [Logger]
        # @param driver [BaseDriver]
        def initialize(driver:, logger: Logger.new(IO::NULL))
          super()
          @driver = driver
          @logger = logger
        end

      protected

        def wait_for_element
          return yield if defined?(RSpec) # Skip waiting in tests

          Watir::Wait.until(timeout: 10) do
            element = yield
            element if element && element_visible?(element)
          end
        rescue Watir::Wait::TimeoutError
          log_element_timeout
          nil
        end

        def element_visible?(element)
          return true unless element.respond_to?(:visible?)

          element.visible?
        end

        def log_element_timeout
          return unless @browser.respond_to?(:elements)

          visible_elements = @browser.elements.select(&:visible?).map(&:text).compact.first(10)
          @logger.error("Element not found after 10s. Sample visible elements: #{visible_elements}")
        end
      end
    end
  end
end
