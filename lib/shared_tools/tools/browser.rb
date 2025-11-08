# frozen_string_literal: true

# Collection loader for all browser tools
# Usage: require 'shared_tools/tools/browser'

require 'shared_tools'

# Load base classes and utilities first (required by other components)
require_relative 'browser/base_driver'
require_relative 'browser/inspect_utils'

# Try to load watir for browser automation
begin
  require 'watir'
  require_relative 'browser/watir_driver'
rescue LoadError
  # Watir gem not installed, BrowserTools will require manual driver
end

# Load tools (order matters - utils loaded first)
require_relative 'browser/visit_tool'
require_relative 'browser/click_tool'
require_relative 'browser/inspect_tool'
require_relative 'browser/page_inspect_tool'
require_relative 'browser/page_screenshot_tool'
require_relative 'browser/selector_inspect_tool'
require_relative 'browser/text_field_area_set_tool'
