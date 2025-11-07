# frozen_string_literal: true

begin
  require "nokogiri"
rescue LoadError
  # Nokogiri is optional - will raise error when tool is used without it
end

module SharedTools
  module Tools
    module Browser
      # A browser automation tool for finding UI elements by their text content.
      class InspectTool < ::RubyLLM::Tool
        def self.name = 'browser_inspect'

        include InspectUtils

        description "A browser automation tool for finding UI elements by their text content."

        params do
          string :text_content, description: "Search for elements containing this text"
          string :selector, description: "Optional CSS selector to further filter results", required: false
          integer :context_size, description: "Number of parent elements to include for context", required: false
        end

        def initialize(driver: nil, logger: nil)
          @driver = driver || default_driver
          @logger = logger || RubyLLM.logger
        end

        def execute(text_content:, selector: nil, context_size: 2)
          raise LoadError, "InspectTool requires the 'nokogiri' gem. Install it with: gem install nokogiri" unless defined?(Nokogiri)

          @logger.info("#{self.class.name}##{__method__}")

          html = @driver.html

          @logger.info("#{self.class.name}##{__method__} html=#{html}")

          doc = cleaned_document(html: @driver.html)
          find_elements_by_text(doc, text_content, context_size, selector)
        end

      private

        def default_driver
          if defined?(Watir)
            WatirDriver.new(logger: @logger)
          else
            raise LoadError, "Browser tools require a driver. Either install the 'watir' gem or pass a driver: parameter"
          end
        end

        def find_elements_by_text(doc, text, context_size, additional_selector = nil)
          elements = get_elements_matching_text(doc, text, additional_selector)

          return "No elements found containing text: #{text}" if elements.empty?

          adjusted_context_size = additional_selector ? 0 : context_size

          Formatters::ElementFormatter.format_matching_elements(elements, text, adjusted_context_size)
        end

        def get_elements_matching_text(doc, text, additional_selector)
          text_downcase = text.downcase

          elements = find_elements_with_matching_text(doc, text_downcase)

          elements = add_elements_from_matching_labels(doc, text_downcase, elements)

          unless additional_selector && !additional_selector.empty?
            elements = Elements::NearbyElementDetector.add_nearby_interactive_elements(elements)
          end

          apply_additional_selector(doc, elements, additional_selector)
        end

        def apply_additional_selector(doc, elements, additional_selector)
          return elements.uniq unless additional_selector && !additional_selector.empty?

          css_matches = doc.css(additional_selector)
          elements.select { |el| css_matches.include?(el) }.uniq
        end
      end
    end
  end
end
