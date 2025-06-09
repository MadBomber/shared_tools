# frozen_string_literal: true

require "zeitwerk"

# Setup Zeitwerk autoloader for the gem
loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  'llm' => 'LLM',
  'ruby_llm' => 'RubyLLM',
  'pdf' => 'PDF',
  'api' => 'API'
)
# Ignore files that don't follow autoloading conventions
loader.ignore("#{__dir__}/shared_tools/version.rb")
loader.ignore("#{__dir__}/shared_tools/ruby_llm")
loader.setup

# Manually require the version file since it doesn't follow namespace conventions
require_relative "shared_tools/version"

# Manually require the core functionality to ensure logger methods are available
require_relative "shared_tools/core"

module SharedTools
  class << self
    # Method to manually load RubyLLM tools when needed
    def load_ruby_llm_tools
      return if @ruby_llm_tools_loaded
      
      # Only load if RubyLLM is available
      if defined?(::RubyLLM::Tool)
        Dir.glob(File.join(File.dirname(__FILE__), "shared_tools", "ruby_llm", "*.rb")).each do |file|
          require file
        end
        @ruby_llm_tools_loaded = true
      end
    end

    # Hook to automatically inject logger into RubyLLM::Tool subclasses
    def const_added(const_name)
      const = const_get(const_name)

      if const.is_a?(Class) && defined?(::RubyLLM::Tool) && const < ::RubyLLM::Tool
        const.class_eval do
          def logger
            SharedTools.logger
          end

          def self.logger
            SharedTools.logger
          end
        end
      end
    end
  end
end
