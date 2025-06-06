# frozen_string_literal: true

require "shared_tools/version"

module SharedTools
  class << self
    def included(base)
      base.extend(ClassMethods)

      if base.is_a?(Class)
        base.class_eval do
          include InstanceMethods
        end
      else
        base.module_eval do
          def self.included(sub_base)
            sub_base.include(SharedTools)
          end
        end
      end
    end

    def extended(object)
      object.extend(ClassMethods)
    end

    # Hook to automatically inject logger into RubyLLM::Tool subclasses
    def const_added(const_name)
      const = const_get(const_name)
      
      if const.is_a?(Class) && defined?(RubyLLM::Tool) && const < RubyLLM::Tool
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

require "shared_tools/core"
