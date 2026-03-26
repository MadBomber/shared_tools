# shared_tools/mcp/hugging_face_client.rb
#
# Hugging Face MCP Server Client — requires brew installation
#
# Provides access to the Hugging Face Hub: search and inspect models,
# datasets, and Spaces; read model cards; run inference; browse
# trending repositories.
#
# Prerequisites:
#   - Homebrew (https://brew.sh)
#   - A Hugging Face user access token (free)
#     Create one at https://huggingface.co/settings/tokens
#   The hf-mcp-server binary is installed automatically via brew if missing.
#
# Configuration:
#   export HF_TOKEN=hf_your_access_token_here
#
# Usage:
#   require 'shared_tools/mcp/hugging_face_client'
#   client = RubyLLM::MCP.clients["hugging-face"]
#   chat = RubyLLM.chat.with_tools(*client.tools)
#
# Compatible with ruby_llm-mcp >= 0.7.0

require_relative "../utilities"

SharedTools.verify_envars("HF_TOKEN")
SharedTools.package_install("hf-mcp-server")

require "ruby_llm/mcp"

RubyLLM::MCP.add_client(
  name: "hugging-face",
  transport_type: :stdio,
  config: {
    command: "hf-mcp-server",
    args:    [],
    env:     {
      "TRANSPORT"        => "stdio",
      "DEFAULT_HF_TOKEN" => ENV.fetch("HF_TOKEN", ""),
    },
  },
)
