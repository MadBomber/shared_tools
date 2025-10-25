# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      # A base driver intended to be overridden by specific browser drivers (e.g. waitir).
      class BaseDriver
        TIMEOUT = Integer(ENV.fetch("OMNIAI_BROWSER_TIMEOUT", 10))

        # @param logger [Logger]
        def initialize(logger: Logger.new(IO::NULL))
          @logger = logger
        end

        def close
          raise NotImplementedError, "#{self.class.name}#{__method__} undefined"
        end

        # @return [String]
        def url
          raise NotImplementedError, "#{self.class.name}#{__method__} undefined"
        end

        # @return [String]
        def title
          raise NotImplementedError, "#{self.class.name}#{__method__} undefined"
        end

        # @return [String]
        def html
          raise NotImplementedError, "#{self.class.name}#{__method__} undefined"
        end

        # @yield [file]
        # @yieldparam file [File]
        def screenshot
          raise NotImplementedError, "#{self.class.name}#{__method__} undefined"
        end

        # @param url [String]
        #
        # @return [Hash]
        def goto(url:)
          raise NotImplementedError, "#{self.class.name}#{__method__} undefined"
        end

        # @param selector [String]
        # @param text [String]
        #
        # @return [Hash]
        def fill_in(selector:, text:)
          raise NotImplementedError, "#{self.class.name}#{__method__} undefined"
        end

        # @param selector [String] e.g. "button[type='submit']", "div#parent > span.child", etc
        #
        # @return [Hash]
        def click(selector:)
          raise NotImplementedError, "#{self.class.name}#{__method__} undefined"
        end
      end
    end
  end
end
