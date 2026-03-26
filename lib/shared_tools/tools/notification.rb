# frozen_string_literal: true

# Collection loader for notification tools
# Usage: require 'shared_tools/tools/notification'

require 'shared_tools'

require_relative 'notification/base_driver'
require_relative 'notification/mac_driver'
require_relative 'notification/linux_driver'
require_relative 'notification/null_driver'
require_relative 'notification_tool'
