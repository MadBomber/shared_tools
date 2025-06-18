# frozen_string_literal: true

require_relative '../shared_tools'

SharedTools.verify_gem :raix

Dir.glob(File.join(__dir__, "raix", "*.rb")).each do |file|
  require file
end
