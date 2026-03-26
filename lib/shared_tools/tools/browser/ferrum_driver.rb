# frozen_string_literal: true

require 'tempfile'

module SharedTools
  module Tools
    module Browser
      # A browser driver backed by Ferrum (Chrome DevTools Protocol).
      # No chromedriver binary required — Ferrum talks directly to Chrome.
      #
      # @example
      #   driver = SharedTools::Tools::Browser::FerrumDriver.new
      #   driver.goto(url: "https://example.com")
      #   driver.click(selector: "a.some-link")
      #   driver.close
      class FerrumDriver < BaseDriver
        # @param logger [Logger]
        # @param network_idle_timeout [Numeric] seconds to wait for network idle after navigation
        # @param ferrum_options [Hash] additional options passed directly to Ferrum::Browser
        def initialize(logger: Logger.new(IO::NULL), network_idle_timeout: 5, **ferrum_options)
          super(logger:)
          @network_idle_timeout = network_idle_timeout
          options = {
            headless: true,
            timeout: TIMEOUT,
            browser_options: { 'disable-blink-features' => 'AutomationControlled' }
          }.merge(ferrum_options)
          @browser = Ferrum::Browser.new(**options)
        end

        def close
          @browser.quit
        end

        # @return [String]
        def url
          @browser.current_url
        end

        # @return [String]
        def title
          @browser.title
        end

        # @return [String]
        def html
          @browser.evaluate('document.documentElement.outerHTML')
        end

        # @param url [String]
        # @return [Hash]
        def goto(url:)
          @browser.go_to(url)
          wait_for_network_idle
          { status: :ok }
        end

        # @yield [file]
        # @yieldparam file [File]
        def screenshot
          tempfile = Tempfile.new(['screenshot', '.png'])
          @browser.screenshot(path: tempfile.path)
          yield File.open(tempfile.path, 'rb')
        ensure
          tempfile&.close
          tempfile&.unlink
        end

        # @param selector [String] CSS selector for an input or textarea
        # @param text [String]
        # @return [Hash]
        def fill_in(selector:, text:)
          element = wait_for_element { @browser.at_css(selector) }
          return { status: :error, message: "unknown selector=#{selector.inspect}" } if element.nil?

          element.evaluate("this.value = #{text.to_json}")
          element.evaluate("this.dispatchEvent(new Event('input', {bubbles: true}))")
          element.evaluate("this.dispatchEvent(new Event('change', {bubbles: true}))")
          { status: :ok }
        rescue => e
          { status: :error, message: e.message }
        end

        # @param selector [String] CSS selector
        # @return [Hash]
        def click(selector:)
          element = wait_for_element { @browser.at_css(selector) }
          return { status: :error, message: "unknown selector=#{selector.inspect}" } if element.nil?

          element.click
          { status: :ok }
        rescue => e
          { status: :error, message: e.message }
        end

      private

        # Wait until there are no pending network requests (JS-rendered pages).
        # Falls back silently if Ferrum raises a timeout.
        def wait_for_network_idle
          @browser.network.wait_for_idle(duration: 0.3, timeout: @network_idle_timeout)
        rescue Ferrum::TimeoutError
          # Some requests never settle; accept whatever state the page is in.
        end

        def wait_for_element
          deadline = Time.now + TIMEOUT
          loop do
            result = yield
            return result if result
            break if Time.now >= deadline
            sleep 0.2
          end
          nil
        end
      end
    end
  end
end
