# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      # @example
      #   driver = SharedTools::Tools::Browser::WatirDriver.new
      #   driver.visit("https://example.com")
      #   driver.click(id: "submit-button")
      class WatirDriver < BaseDriver
        def initialize(logger: Logger.new(IO::NULL), browser: Watir::Browser.new(:chrome))
          super(logger:)
          @browser = browser
        end

        def close
          @browser.close
        end

        # @return [String]
        def url
          @browser.url
        end

        # @return [String]
        def title
          @browser.title
        end

        # @return [String]
        def html
          @browser.html
        end

        # @param url [String]
        def goto(url:)
          @browser.goto(url)

          { status: :ok }
        end

        # @yield [file]
        # @yieldparam file [File]
        def screenshot
          tempfile = Tempfile.new(["screenshot", ".png"])
          @browser.screenshot.save(tempfile.path)

          yield File.open(tempfile.path, "rb")
        ensure
          tempfile&.close
          tempfile&.unlink
        end

        # @param selector [String]
        # @param text [String]
        #
        # @return [Hash]
        def fill_in(selector:, text:)
          element = find_field(selector)

          return { status: :error, message: "unknown selector=#{selector.inspect}" } if element.nil?

          element.set(text)

          { status: :ok }
        end

        # @param selector [String] e.g. "button[type='submit']", "div#parent > span.child", etc
        #
        # @return [Hash]
        def click(selector:)
          element = find_element(selector)

          return { status: :error, message: "unknown selector=#{selector.inspect}" } if element.nil?

          element.click

          { status: :ok }
        end

      protected

        def wait_for_element(&)
          Watir::Wait.until(timeout: TIMEOUT, &)
        rescue Watir::Wait::TimeoutError
          nil
        end

        # @param selector [String]
        #
        # @return [Watir::Input, Watir::TextArea, nil]
        def find_field(selector)
          wait_for_element { find_input_by(css: selector) || find_textarea_by(css: selector) }
        end

        # @param selector [Hash] A hash with one of the following
        #
        # @return [Watir::Element, nil]
        def find_element(selector)
          wait_for_element { find_element_by(css: selector) }
        end

        def find_element_by(selector)
          element = @browser.element(selector)
          return unless element.respond_to?(:exists?)

          element if element.exists?
        end

        # @param selector [Hash]
        #
        # @return [Watir::TextArea, nil]
        def find_textarea_by(selector)
          element = @browser.textarea(selector)
          return unless element

          element if element.exists?
        end

        # @param selector [Hash]
        #
        # @return [Watir::Input, nil]
        def find_input_by(selector)
          element = @browser.input(selector)
          return unless element

          element if element.exists?
        end
      end
    end
  end
end
