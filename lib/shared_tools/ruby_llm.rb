# frozen_string_literal: true

# Entry point for loading all ruby_llm tools
# Usage: require 'shared_tools/ruby_llm'

module SharedTools::RubyLLM
  SharedTools.verify_gem :ruby_llm

  Dir.glob(File.join(__dir__, "ruby_llm", "*.rb")).each do |file|
    require file
  end
end
