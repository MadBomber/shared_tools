# lib/shared_tools/tools/enabler.rb
# frozen_string_literal: true
# Part of an idea to reduce the number of tokens used when there
# are a large number tools available.  As part of the initial prompt
# send tool names, descriptions and parameters alone with instructions
# to call the enable tool with the tool name to use and a JSON
# formatted parameters.
#
# This could be something lie a tool dispatcher that can call the
# tool with the parameters and return the result.
#
# Maybe we have the DispatcherTool and a ToolBox tool where the ToolBox Tool
# returns to the LLM the list of tool names, parameters and descriptions.
# The DispatcherTool can then call the tool with the parameters and return the result.


require 'ruby_llm/tool'

module Tools
  # A tool for reading the contents of a file.
  class Enabler < RubyLLM::Tool
    attr_reader :agent

    description <<~DESCRIPTION
      Enables a tool based on the request.
    DESCRIPTION
    param :tool, desc: 'Tool name to enable'
    # param :params, desc: 'JSON formatted parameters'

    def initialize(agent)
      @agent = agent
    end

    def execute(tool:, params: '')
      agent.add_tool(tool)
      # TODO: call the tool with the params and return the result.
      { success: true }
    rescue StandardError => e
      { error: e.message }
    end
  end
end
