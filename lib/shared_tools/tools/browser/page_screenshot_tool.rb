# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      # A browser automation tool for taking screenshots of the current page.
      # Saves the screenshot to a file and returns the path — avoids injecting
      # large base64 blobs into the conversation context.
      class PageScreenshotTool < ::RubyLLM::Tool
        def self.name = 'browser_page_screenshot'

        description "Take a screenshot of the current browser page and save it to a file."

        params do
          string :path, required: false,
                        description: "File path to save the screenshot (e.g. 'screenshot.png'). " \
                                     "Defaults to a timestamped name in the current directory."
        end

        def initialize(driver: nil, logger: nil)
          @driver = driver || default_driver
          @logger = logger || RubyLLM.logger
        end

        def execute(path: nil)
          @logger.info("#{self.class.name}##{__method__}")

          save_path = path || "screenshot_#{Time.now.strftime('%Y%m%d_%H%M%S')}.png"

          @driver.screenshot do |file|
            File.binwrite(save_path, file.read)
          end

          { status: :ok, saved_to: File.expand_path(save_path) }
        end

      private

        def default_driver
          if defined?(Ferrum)
            FerrumDriver.new(logger: @logger)
          elsif defined?(Watir)
            WatirDriver.new(logger: @logger)
          else
            raise LoadError, "Browser tools require a driver. Install the 'ferrum' gem or pass a driver: parameter"
          end
        end
      end
    end
  end
end
