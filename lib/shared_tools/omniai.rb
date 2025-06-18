# frozen_string_literal: true

require_relative '../shared_tools'

SharedTools.verify_gem :omniai

Dir.glob(File.join(__dir__, "omniai", "*.rb")).each do |file|
  require file
end
