# frozen_string_literal: true

# Entry point for loading all omniai tools
# Usage: require 'shared_tools/omniai'

module SharedTools::OmniAI
  SharedTools.verify_gem :omniai

  Dir.glob(File.join(__dir__, "omniai", "*.rb")).each do |file|
    require file
  end
end
