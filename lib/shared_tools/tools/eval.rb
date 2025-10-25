# frozen_string_literal: true

# Collection loader for all eval tools
# Usage: require 'shared_tools/tools/eval'

require 'shared_tools'

require_relative 'eval/python_eval_tool'
require_relative 'eval/ruby_eval_tool'
require_relative 'eval/shell_eval_tool'
