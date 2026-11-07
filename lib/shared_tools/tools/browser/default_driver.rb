# frozen_string_literal: true

module SharedTools
  module Tools
    module Browser
      # Picks the browser driver used when a tool is built without a driver:.
      # Ferrum is preferred; Watir is the fallback. The gems are required on
      # demand, because eager loading (SharedTools.load_all_tools) never loads
      # tools/browser.rb, which is the only other place that requires them.
      module DefaultDriver
        module_function

        # @return [Class, nil] FerrumDriver, WatirDriver, or nil when neither gem loads
        def driver_class
          if gem_loaded?("ferrum") then FerrumDriver
          elsif gem_loaded?("watir") then WatirDriver
          end
        end

        # @param logger [Logger]
        # @raise [LoadError] when neither ferrum nor watir is installed
        # @return [BaseDriver]
        def build(logger:)
          klass = driver_class
          raise LoadError, "Browser tools require a driver. Install the 'ferrum' gem (or 'watir') or pass a driver: parameter" unless klass

          klass.new(logger:)
        end

        # @param name [String] gem require path
        # @return [Boolean]
        def gem_loaded?(name)
          require name
          true
        rescue LoadError
          false
        end
      end
    end
  end
end
