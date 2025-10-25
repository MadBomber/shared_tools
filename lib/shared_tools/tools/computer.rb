# frozen_string_literal: true

# Collection loader for computer tools
# Usage: require 'shared_tools/tools/computer'

require 'shared_tools'

# Load driver base class
require_relative 'computer/base_driver'

# Try to load platform-specific dependencies and drivers
begin
  if RUBY_PLATFORM.include?('darwin')
    require 'macos'
    require_relative 'computer/mac_driver'
  end
rescue LoadError
  # MacOS gem not installed, ComputerTool will require manual driver
end

require_relative 'computer_tool'
