# frozen_string_literal: true

SharedTools.verify_gem :omniai

Dir.glob(File.join(__dir__, "omniai", "*.rb")).each do |file|
  require file
end
