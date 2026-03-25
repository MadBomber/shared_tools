# frozen_string_literal: true

# Collection loader for all browser tools
# Usage: require 'shared_tools/tools/browser'

require 'shared_tools'

# Load base classes and utilities first (required by other components)
require_relative 'browser/base_driver'
require_relative 'browser/inspect_utils'

# Load formatters (used by inspect_tool and related components)
require_relative 'browser/formatters/action_formatter'
require_relative 'browser/formatters/data_entry_formatter'
require_relative 'browser/formatters/element_formatter'
require_relative 'browser/formatters/input_formatter'

# Load elements helpers (used by inspect_tool)
require_relative 'browser/elements/element_grouper'
require_relative 'browser/elements/nearby_element_detector'

# Load page_inspect helpers (used by page_inspect_tool)
require_relative 'browser/page_inspect/button_summarizer'
require_relative 'browser/page_inspect/form_summarizer'
require_relative 'browser/page_inspect/html_summarizer'
require_relative 'browser/page_inspect/link_summarizer'

# Load selector_generator and its sub-modules (used by click_tool and related)
require_relative 'browser/selector_generator/base_selectors'
require_relative 'browser/selector_generator/contextual_selectors'
require_relative 'browser/selector_generator'

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
