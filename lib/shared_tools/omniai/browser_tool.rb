# frozen_string_literal: true
# See: https://ksylvest.com/posts/2025-06-06/exploring-common-ai-patterns-with-ruby

require "watir"

# NOTE: This tool has a logger parameter in its constructor.  It
#       is used to log messages to the console or a file rather than
#       the default logger object injected into the BrowserTool class
#       by the enclosing SharedTools module.

module SharedTools
  class BrowserTool < OmniAI::Tool
    module Action
      HTML = "html"
      GOTO = "goto"
      CLICK = "click"
    end

    ACTIONS = [
      Action::HTML,
      Action::GOTO,
      Action::CLICK,
    ]

    description <<~TEXT
                  A chrome browser that can be used to goto sites, click elements, and capture HTML.
                TEXT

    parameter :action, :string, enum: ACTIONS, description: <<~TEXT
                                  An action to be performed:
                                  * `#{Action::GOTO}`: manually navigate to a specific URL
                                  * `#{Action::HTML}`: retrieve the full HTML of the page
                                  * `#{Action::CLICK}`: click an element using a selector (e.g. '.btn', '#submit', etc)
                                TEXT

    parameter :url, :string, description: <<~TEXT
                               e.g. 'https://example.com/some/page'

                               Required for the following actions:
                               * `#{Action::GOTO}`
                             TEXT

    parameter :selector, :string, description: <<~TEXT
                                    e.g. 'button#submit', '.link', '#main > a', etc.

                                    Required for the following actions:
                                    * `#{Action::CLICK}`
                                  TEXT

    required %i[action]

    # @param logger [Logger]
    def initialize(logger: Logger.new($stdout))
      super()
      @browser = ::Watir::Browser.new
      @logger = logger
    end

    # @param action [String]
    # @param selector [String] optional
    # @param url [String] optional
    def execute(action:, url: nil, selector: nil)
      case action
      when Action::GOTO then goto(url:)
      when Action::HTML then html
      when Action::CLICK then click(selector:)
      end
    rescue StandardError => error
      { status: :error, message: error.message }
    end

    private

    # @param url [String]
    def goto(url:)
      @logger.info("goto url=#{url.inspect}")

      raise ArgumentError, "goto requires url" unless url

      @browser.goto(url)

      return { status: :ok }
    end

    # @return selector [String]
    def click(selector:)
      @logger.info("click selector=#{selector.inspect}")

      raise ArgumentError, "click requires selector" unless selector

      @browser.element(css: selector).click

      return { status: :ok }
    end

    # @return [String]
    def html
      @logger.info("html")

      @browser.html
    end
  end
end
