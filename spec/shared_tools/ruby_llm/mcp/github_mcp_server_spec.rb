# frozen_string_literal: true

require 'spec_helper'
require 'shared_tools/ruby_llm/mcp/github_mcp_server'

RSpec.describe GithubMcpServer do
  after do
    # Clean up any existing client instance
    GithubMcpServer.instance_variable_set(:@client, nil)
  end

  describe 'inheritance' do
    it 'inherits from McpClient' do
      expect(GithubMcpServer.superclass).to eq(McpClient)
    end
  end

  describe 'client creation' do
    let(:mock_client) { double('RubyLLM::MCP::Client', disconnect: nil) }

    before do
      allow(RubyLLM::MCP).to receive(:client).and_return(mock_client)
      allow(ENV).to receive(:fetch).with('GITHUB_PERSONAL_ACCESS_TOKEN').and_return('fake_token')
    end

    it 'creates a client with correct configuration' do
      expect(RubyLLM::MCP).to receive(:client).with(
        name: "github-mcp-server",
        transport_type: :stdio,
        config: {
          command: "/opt/homebrew/bin/github-mcp-server",
          args: %w[stdio],
          env: { "GITHUB_PERSONAL_ACCESS_TOKEN" => "fake_token" }
        }
      )

      GithubMcpServer.connect
    end

    it 'stores the client in the class variable' do
      client = GithubMcpServer.connect
      expect(GithubMcpServer.client).to eq(client)
    end

    it 'returns the same client on subsequent calls' do
      client1 = GithubMcpServer.connect
      client2 = GithubMcpServer.connect
      expect(client1).to eq(client2)
    end
  end

  describe 'environment variable handling' do
    it 'raises error when GITHUB_PERSONAL_ACCESS_TOKEN is not set' do
      allow(ENV).to receive(:fetch).with('GITHUB_PERSONAL_ACCESS_TOKEN').and_raise(KeyError)
      
      expect { GithubMcpServer.connect }.to raise_error(KeyError)
    end
  end

  describe 'disconnect' do
    let(:mock_client) { double('RubyLLM::MCP::Client', disconnect: nil) }

    before do
      allow(RubyLLM::MCP).to receive(:client).and_return(mock_client)
      allow(ENV).to receive(:fetch).with('GITHUB_PERSONAL_ACCESS_TOKEN').and_return('fake_token')
    end

    it 'disconnects the client' do
      GithubMcpServer.connect
      expect(mock_client).to receive(:disconnect)
      
      GithubMcpServer.disconnect
      expect(GithubMcpServer.client).to be_nil
    end
  end

  describe 'connection status' do
    let(:mock_client) { double('RubyLLM::MCP::Client', disconnect: nil) }

    before do
      allow(RubyLLM::MCP).to receive(:client).and_return(mock_client)
      allow(ENV).to receive(:fetch).with('GITHUB_PERSONAL_ACCESS_TOKEN').and_return('fake_token')
    end

    it 'reports not connected initially' do
      expect(GithubMcpServer.connected?).to be false
    end

    it 'reports connected after connect' do
      GithubMcpServer.connect
      expect(GithubMcpServer.connected?).to be true
    end

    it 'reports not connected after disconnect' do
      GithubMcpServer.connect
      GithubMcpServer.disconnect
      expect(GithubMcpServer.connected?).to be false
    end
  end
end