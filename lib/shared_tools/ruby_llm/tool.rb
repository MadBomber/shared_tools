# frozen_string_literal: true

module SharedTools
  module RubyLlm
    # Base class for all Ruby LLM tools
    class Tool
      # Class-level storage for tool parameters
      class << self
        attr_accessor :tool_description, :tool_params
        
        # Define the tool description
        def description(desc)
          self.tool_description = desc
        end
        
        # Define a parameter for the tool
        def param(name, desc:, required: true)
          self.tool_params ||= {}
          self.tool_params[name] = { description: desc, required: required }
        end
      end
      
      # Initialize tool_params if not already set
      self.tool_params ||= {}
    end
  end
end
