# frozen_string_literal: true

# Collection loader for all disk tools
# Usage: require 'shared_tools/tools/disk'

require 'shared_tools'

require_relative 'disk/file_read_tool'
require_relative 'disk/file_write_tool'
require_relative 'disk/file_create_tool'
require_relative 'disk/file_delete_tool'
require_relative 'disk/file_move_tool'
require_relative 'disk/file_replace_tool'
require_relative 'disk/directory_list_tool'
require_relative 'disk/directory_create_tool'
require_relative 'disk/directory_delete_tool'
require_relative 'disk/directory_move_tool'
