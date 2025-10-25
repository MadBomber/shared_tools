# frozen_string_literal: true

# Collection loader for all browser tools
# Usage: require 'shared_tools/tools/browser'

require 'shared_tools'

require_relative 'browser/visit_tool'
require_relative 'browser/click_tool'
require_relative 'browser/inspect_tool'
require_relative 'browser/page_inspect_tool'
require_relative 'browser/page_screenshot_tool'
require_relative 'browser/selector_inspect_tool'
require_relative 'browser/text_field_area_set_tool'
