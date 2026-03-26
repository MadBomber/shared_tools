# frozen_string_literal: true
# Shim: require 'shared_tools/database_tool'
# Note: database.rb already loads database_tool.rb
require 'shared_tools'
require 'shared_tools/tools/database'  # drivers + DatabaseTool facade
