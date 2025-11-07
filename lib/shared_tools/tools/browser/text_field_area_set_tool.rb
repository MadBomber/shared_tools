# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      # @example
      #   browser = Watir::Browser.new(:chrome)
      #   tool = SharedTools::Tools::Browser::TextFieldSetTool.new(browser:)
      #   tool.execute(selector: "...", text: "...")
      class TextFieldAreaSetTool < ::RubyLLM::Tool
        def self.name = 'browser_text_field_set'

        description "A browser automation tool for clicking a specific link."

        params do
          string :selector, description: "The ID / name of the text field / area to interact with."
          string :text, description: "The text to set."
        end

        def initialize(driver: nil, logger: nil)
          @driver = driver || default_driver
          @logger = logger || RubyLLM.logger
        end

        # @param selector [String] The ID / name of the text field / text area to interact with.
        # @param text [String] The text to set.
        def execute(selector:, text:)
          @logger.info("#{self.class.name}##{__method__} selector=#{selector.inspect}")

          @driver.fill_in(selector:, text:)
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
