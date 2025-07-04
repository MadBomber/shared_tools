# frozen_string_literal: true

require 'spec_helper'
require 'shared_tools/ruby_llm/mcp'

RSpec.describe 'MCP module loading' do
  describe 'requiring shared_tools/ruby_llm/mcp' do
    it 'loads all MCP client classes' do
      # These classes should be available after requiring the mcp module
      expect(defined?(McpClient)).to be_truthy
      expect(defined?(GithubMcpServer)).to be_truthy
      expect(defined?(Imcp)).to be_truthy
    end

    it 'loads the base McpClient class' do
      expect(McpClient).to be_a(Class)
    end

    it 'loads GithubMcpServer as a subclass of McpClient' do
      expect(GithubMcpServer).to be < McpClient
    end

    it 'loads Imcp as a subclass of McpClient' do
      expect(Imcp).to be < McpClient
    end
  end

  describe 'individual file loading' do
    it 'allows loading individual MCP clients' do
      # Test that we can load individual files without errors
      expect { require 'shared_tools/ruby_llm/mcp/mcp_client' }.not_to raise_error
      expect { require 'shared_tools/ruby_llm/mcp/github_mcp_server' }.not_to raise_error
      expect { require 'shared_tools/ruby_llm/mcp/imcp' }.not_to raise_error
    end
  end
end