# frozen_string_literal: true

require_relative '../shared_tools'

SharedTools.verify_gem :llm_rb

Dir.glob(File.join(__dir__, "llm_rb", "*.rb")).each do |file|
  require file
end
