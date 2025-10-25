# frozen_string_literal: true

require_relative '../shared_tools'

# This excludes the sub-directories and mcp.rb
Dir.glob(File.join(__dir__, "ruby_llm", "*.rb"))
   .reject { |f| File.basename(f) == 'mcp.rb' }
   .each do |file|
  require file
end
