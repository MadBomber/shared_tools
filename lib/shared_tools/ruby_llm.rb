# frozen_string_literal: true

require_relative '../shared_tools'

SharedTools.verify_gem :ruby_llm

Dir.glob(File.join(__dir__, "ruby_llm", "*.rb")).each do |file|
  require file
end
