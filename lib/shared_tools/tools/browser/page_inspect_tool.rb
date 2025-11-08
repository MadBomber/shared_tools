# frozen_string_literal: true

begin
  require "nokogiri"
rescue LoadError
  # Nokogiri is optional - will raise error when tool is used without it
end

module SharedTools
  module Tools
    module Browser
      # A browser automation tool for viewing the full HTML of the page.
      class PageInspectTool < ::RubyLLM::Tool
        def self.name = 'browser_page_inspect'

        include InspectUtils

        description "A browser automation tool for viewing the full HTML of the current page."

        params do
          boolean :summarize, description: "If true, returns a summary instead of full HTML", required: false
        end

        def initialize(driver: nil, logger: nil)
          @driver = driver || default_driver
          @logger = logger || RubyLLM.logger
        end

        def execute(summarize: false)
          raise LoadError, "PageInspectTool requires the 'nokogiri' gem. Install it with: gem install nokogiri" unless defined?(Nokogiri)

          @logger.info("#{self.class.name}##{__method__}")

          doc = cleaned_document(html: @driver.html)

          if summarize
            PageInspect::HtmlSummarizer.summarize_interactive_elements(doc)
          else
            doc.to_html
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
