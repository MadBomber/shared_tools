# frozen_string_literal: true

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

        def wait_for_element(timeout: 10)
          return yield if defined?(RSpec) # Skip waiting in tests

          deadline = Time.now + timeout
          loop do
            element = yield
            return element if element && element_visible?(element)
            break if Time.now >= deadline
            sleep 0.2
          end
          nil
        end

        def element_visible?(element)
          return true unless element.respond_to?(:visible?)

          element.visible?
        end

        def log_element_timeout
          @logger.error("Element not found after timeout.")
        end
      end
    end
  end
end
