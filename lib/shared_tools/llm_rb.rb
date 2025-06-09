# frozen_string_literal: true

# Entry point for loading all llm.rb tools
# Usage: require 'shared_tools/llm_rb'

module SharedTools::LlmRb
  SharedTools.verify_gem :llm_rb

  Dir.glob(File.join(__dir__, "llm_rb", "*.rb")).each do |file|
    require file
  end
end
