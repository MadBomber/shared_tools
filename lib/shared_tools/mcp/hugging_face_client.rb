# frozen_string_literal: true

# shared_tools/mcp/hugging_face_client.rb
#
# Hugging Face MCP Server — local binary over stdio
#
# Provides access to the Hugging Face Hub: search and inspect models,
# datasets, and Spaces; read model cards; run inference; browse
# trending repositories.
#
# Prerequisites:
#   - The hf-mcp-server binary on PATH. Install it with
#     SharedTools::MCP::HuggingFace.install_packages! (Homebrew/apt/dnf) or by hand.
#   - A Hugging Face user access token (free)
#     Create one at https://huggingface.co/settings/tokens
#
# Configuration:
#   export HF_TOKEN=hf_your_access_token_here
#
# Usage:
#   require 'shared_tools/mcp/hugging_face_client'
#   chat  = RubyLLM.chat.with_mcp(SharedTools::MCP::HuggingFace)
#   robot = RobotLab.build(name: "ml", mcp: [SharedTools::MCP::HuggingFace])
#
# Requires ruby_llm >= 2.1 (built-in RubyLLM::MCP). Nothing starts until the
# server's tools are first requested.

require_relative "client_support"

module SharedTools
  module MCP
    class HuggingFace < ::RubyLLM::MCP
      extend ClientSupport

      description "Hugging Face Hub: search models, datasets, Spaces, and papers"

      requires_envars   "HF_TOKEN"
      requires_packages "hf-mcp-server"

      command "hf-mcp-server"
      env "TRANSPORT"        => "stdio",
          "DEFAULT_HF_TOKEN" => env_from("HF_TOKEN")
    end
  end
end
