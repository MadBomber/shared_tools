# frozen_string_literal: true

SharedTools.verify_gem :ruby_llm

Dir.glob(File.join(__dir__, "ruby_llm", "*.rb")).each do |file|
  require file
end
