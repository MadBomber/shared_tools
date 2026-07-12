# frozen_string_literal: true
# Shim: require 'shared_tools/git_tool'
require 'shared_tools'
require 'shared_tools/tools/git'       # sub-tools (Git::StatusTool, Git::DiffTool, etc.)
require 'shared_tools/tools/git_tool'  # facade (GitTool)
