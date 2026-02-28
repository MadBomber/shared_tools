# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  module Tools
    # A tool for controller a browser.
    class BrowserTool < ::RubyLLM::Tool
      def self.name = 'browser_tool' 
      module Action
        VISIT = "visit"
        PAGE_INSPECT = "page_inspect"
        UI_INSPECT = "ui_inspect"
        SELECTOR_INSPECT = "selector_inspect"
        CLICK = "click"
        TEXT_FIELD_SET = "text_field_set"
        SCREENSHOT = "screenshot"
      end

      ACTIONS = [
        Action::VISIT,
        Action::PAGE_INSPECT,
        Action::UI_INSPECT,
        Action::SELECTOR_INSPECT,
        Action::CLICK,
        Action::TEXT_FIELD_SET,
        Action::SCREENSHOT,
      ].freeze

      description <<~TEXT
        Automates a web browser to perform various actions like visiting web pages, clicking elements, etc:

        1. `#{Action::VISIT}` - Navigate to a website
          Required: "action": "visit", "url": "[website URL]"

        2. `#{Action::PAGE_INSPECT} - Get page HTML or summary
          Required: "action": "page_inspect"
          Optional: "full_html": true/false (get full HTML vs summary, default: summary)

        3. `#{Action::UI_INSPECT}` - Find elements by text content
          Required: "action": "ui_inspect", "text_content": "[text to search for]"
          Optional:
          - "selector": "[CSS selector]" (search within specific container)
          - "context_size": [number] (parent elements to show, default: 2)

        4. `#{Action::SELECTOR_INSPECT} - Find elements by CSS selector
          Required: "action": "selector_inspect", "selector": "[CSS selector]"
          Optional: "context_size": [number] (parent elements to show, default: 2)

        5. `#{Action::CLICK}` - Click an element by CSS selector
          Required: "action": "click", "selector": "[CSS selector]"

        8. `#{Action::TEXT_FIELD_SET}` - Enter text in input fields/text areas
          Required: "action": "text_field_set", "selector": "[field CSS selector]", "value": "[text to enter]"

        9. `#{Action::SCREENSHOT}` - Take a screenshot of the page or specific element
          Required: "action": "screenshot"

        ## Examples:

        Visit a website
          {"action": "#{Action::VISIT}", "url": "https://example.com"}
        Get page summary
          {"action": "#{Action::PAGE_INSPECT}"}
        Get full page HTML
          {"action": "#{Action::PAGE_INSPECT}", "full_html": true}
        Find elements containing text
          {"action": "#{Action::UI_INSPECT}", "text_content": "Submit"}
        Find elements with context
          {"action": "#{Action::UI_INSPECT}", "text_content": "Login", "context_size": 3}
        Find elements by CSS selector
          {"action": "#{Action::SELECTOR_INSPECT}", "selector": ".button"}
        Find selector with context
          {"action": "#{Action::SELECTOR_INSPECT}", "selector": "h1", "context_size": 2}
        Click a button by CSS selector
          {"action": "#{Action::CLICK}", "selector": "button[type='Submit']"}
        Click a link by CSS Selector
          {"action": "#{Action::CLICK}", "selector": "a[href='/login']"}
        Click an element by CSS selector
          {"action": "#{Action::CLICK}", "selector": "div.panel > span.toggle"}
        Click an element by CSS selector:
          {"action": "#{Action::CLICK}", "selector": "[role='listitem']"}
        Set text in an input field
          {"action": "#{Action::TEXT_FIELD_SET}", "selector": "#search", "value": "search query"}
        Take a full page screenshot
          {"action": "#{Action::SCREENSHOT}"}
      TEXT

      params do
        string :action, description: <<~TEXT.strip
          The browser action to perform. Options:
          * `#{Action::VISIT}`: Navigate to a website
          * `#{Action::PAGE_INSPECT}`: Get full HTML or summarized page information
          * `#{Action::UI_INSPECT}`: Find elements containing specific text
          * `#{Action::SELECTOR_INSPECT}`: Find elements matching CSS selectors
          * `#{Action::CLICK}`: Click an element by CSS selector
          * `#{Action::TEXT_FIELD_SET}`: Enter text in input fields or text areas
          * `#{Action::SCREENSHOT}`: Take a screenshot of the current page
        TEXT

        string :url, description: <<~TEXT.strip, required: false
          The URL to visit. Required for the following actions:
          * `#{Action::VISIT}`
        TEXT

        string :selector, description: <<~TEXT.strip, required: false
          A CSS selector to locate an element:

            * 'form button[type="submit"]': selects a button with type submit
            * '.example': selects elements with the foo and bar classes
            * '#example': selects an element by ID
            * 'div#parent > span.child': selects span elements that are direct children of div elements
            * 'a[href="/login"]': selects an anchor tag with a specific href attribute
            * 'button[aria-label="Close"]': selects an element by ARIA label

          Required for the following actions:
          * `#{Action::CLICK}`
          * `#{Action::TEXT_FIELD_SET}`
          * `#{Action::SELECTOR_INSPECT}`

          Optional for the following actions:
          * `#{Action::UI_INSPECT}` (search within specific container)
        TEXT

        string :value, description: <<~TEXT.strip, required: false
          The value to set in the text field. Required for the following actions:
          * `#{Action::TEXT_FIELD_SET}`
        TEXT

        integer :context_size, description: <<~TEXT.strip, required: false
          Number of parent elements to include in inspect results (default: 2). Optional for the following actions:
          * `#{Action::UI_INSPECT}`
          * `#{Action::SELECTOR_INSPECT}`
        TEXT

        boolean :full_html, description: <<~TEXT.strip, required: false
          Return the full HTML of the page instead of a summary. Optional for the following actions:
          * `#{Action::PAGE_INSPECT}`
        TEXT

        string :text_content, description: <<~TEXT.strip, required: false
          Search for elements containing this text. Required for the following actions:
          * `#{Action::UI_INSPECT}`
        TEXT
      end


      # @param logger [Logger] optional logger
      # @param driver [SharedTools::Tools::Browser::BaseDriver] optional, will attempt to create WatirDriver when execute is called
      def initialize(logger: nil, driver: nil)
        @logger = logger || RubyLLM.logger
        @driver = driver  # Defer default_driver to execute time to support RubyLLM tool discovery
      end

      # Set driver after instantiation (useful when tool is discovered by RubyLLM)
      attr_writer :driver

      # Reports whether this tool can function.
      # Returns true when a driver was injected or the watir gem is loaded.
      def available?
        !!@driver || defined?(Watir)
      end

      def cleanup!
        @driver.close
      end

      # @param action [String]
      # @param url [String, nil]
      # @param selector [String, nil] e.g. "button[type='submit']", "div#parent > span.child", etc
      # @param value [String, nil]
      # @param context_size [Integer]
      # @param full_html [Boolean]
      # @param text_content [String, nil]
      #
      # @return [String]
      def execute(action:, url: nil, selector: nil, value: nil, context_size: 2, full_html: false, text_content: nil)
        # Lazily resolve driver at execute time
        @driver ||= default_driver

        case action.to_s.downcase
        when Action::VISIT
          require_param!(:url, url)
          visit_tool.execute(url:)
        when Action::PAGE_INSPECT
          if full_html
            page_inspect_tool.execute
          else
            page_inspect_tool.execute(summarize: true)
          end
        when Action::UI_INSPECT
          require_param!(:text_content, text_content)
          inspect_tool.execute(text_content:, selector:, context_size:)
        when Action::SELECTOR_INSPECT
          require_param!(:selector, selector)
          selector_inspect_tool.execute(selector:, context_size:)
        when Action::CLICK
          require_param!(:selector, selector)
          click_tool.execute(selector:)
        when Action::TEXT_FIELD_SET
          require_param!(:selector, selector)
          require_param!(:value, value)
          text_field_area_set_tool.execute(selector:, text: value)
        when Action::SCREENSHOT
          page_screenshot_tool.execute
        else
          { error: "Unsupported action: #{action}. Supported actions are: #{ACTIONS.join(', ')}" }
        end
      end

    private

      # @param name [Symbol]
      # @param value [Object]
      #
      # @raise [ArgumentError]
      # @return [void]
      def require_param!(name, value)
        raise ArgumentError, "#{name} param is required for this action" if value.nil?
      end

      # @return [Browser::VisitTool]
      def visit_tool
        Browser::VisitTool.new(driver: @driver, logger: @logger)
      end

      # @return [Browser::PageInspectTool]
      def page_inspect_tool
        Browser::PageInspectTool.new(driver: @driver, logger: @logger)
      end

      # @return [Browser::UIInspectTool]
      def inspect_tool
        Browser::InspectTool.new(driver: @driver, logger: @logger)
      end

      # @return [Browser::SelectorInspectTool]
      def selector_inspect_tool
        Browser::SelectorInspectTool.new(driver: @driver, logger: @logger)
      end

      # @return [Browser::ClickTool]
      def click_tool
        Browser::ClickTool.new(driver: @driver, logger: @logger)
      end

      # @return [Browser::TextFieldAreaSetTool]
      def text_field_area_set_tool
        Browser::TextFieldAreaSetTool.new(driver: @driver, logger: @logger)
      end

      # @return [Browser::PageScreenshotTool]
      def page_screenshot_tool
        Browser::PageScreenshotTool.new(driver: @driver, logger: @logger)
      end

      # @return [Browser::BaseDriver]
      def default_driver
        if defined?(Watir)
          Browser::WatirDriver.new(logger: @logger)
        else
          raise LoadError, "BrowserTool requires a driver. Either install the 'watir' gem or pass a driver: parameter"
        end
      end
    end
  end
end
