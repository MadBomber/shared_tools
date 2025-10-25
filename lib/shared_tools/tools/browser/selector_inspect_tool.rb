# frozen_string_literal: true

begin
  require "nokogiri"
rescue LoadError
  # Nokogiri is optional - will raise error when tool is used without it
end

module SharedTools
  module Tools
    module Browser
      # A browser automation tool for inspecting elements using CSS selectors.
      class SelectorInspectTool < ::RubyLLM::Tool
        def self.name = 'browser_selector_inspect'

        include InspectUtils

        description "A browser automation tool for finding and inspecting elements by CSS selector."

        param :selector, desc: "CSS selector to target specific elements"
        param :context_size, desc: "Number of parent elements to include for context"

        def initialize(driver: nil, logger: nil)
          @driver = driver || default_driver
          @logger = logger || RubyLLM.logger
        end

        def execute(selector:, context_size: 2)
          raise LoadError, "SelectorInspectTool requires the 'nokogiri' gem. Install it with: gem install nokogiri" unless defined?(Nokogiri)

          @logger.info("#{self.class.name}##{__method__}")

          doc = cleaned_document(html: @driver.html)
          target_elements = doc.css(selector)

          return "No elements found matching selector: #{selector}" if target_elements.empty?

          format_elements(target_elements, selector, context_size)
        end

      private

        def default_driver
          if defined?(Watir)
            WatirDriver.new(logger: @logger)
          else
            raise LoadError, "Browser tools require a driver. Either install the 'watir' gem or pass a driver: parameter"
          end
        end

        def format_elements(elements, selector, context_size)
          result = "Found #{elements.size} elements matching '#{selector}':\n\n"

          elements.each_with_index do |element, index|
            result += "--- Element #{index + 1} ---\n"
            result += Formatters::ElementFormatter.get_parent_context(element, context_size) if context_size.positive?
            result += "Element: #{element.to_html}\n\n"
          end

          result
        end
      end
    end
  end
end
