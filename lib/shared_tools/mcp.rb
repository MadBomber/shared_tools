# lib/shared_tools/mcp.rb
#
# MCP (Model Context Protocol) support for SharedTools using ruby_llm-mcp gem >= 0.7.0
#
# This module provides integration with various MCP servers, allowing Ruby applications
# to connect to external services and tools through the Model Context Protocol.
#
# @see https://github.com/patvice/ruby_llm-mcp RubyLLM MCP documentation
# @see https://www.rubyllm-mcp.com Official documentation
#
# Usage:
#   require 'shared_tools/mcp/imcp'              # Load iMCP client
#   require 'shared_tools/mcp/github_mcp_server' # Load GitHub client
#   require 'shared_tools/mcp/tavily_mcp_server' # Load Tavily client
#
# Requirements:
#   - ruby_llm-mcp >= 0.7.0
#   - RubyLLM >= 1.9.0
#
# Version 0.7.0 Changes:
#   - Complex parameter support is now enabled by default
#   - Requires RubyLLM 1.9+
#   - support_complex_parameters! method is deprecated
#
