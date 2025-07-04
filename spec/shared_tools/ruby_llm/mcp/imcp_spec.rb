# frozen_string_literal: true

require 'spec_helper'
require 'shared_tools/ruby_llm/mcp/imcp'

RSpec.describe Imcp do
  after do
    # Clean up any existing client instance
    Imcp.instance_variable_set(:@client, nil)
  end

  describe 'inheritance' do
    it 'inherits from McpClient' do
      expect(Imcp.superclass).to eq(McpClient)
    end
  end

  describe 'client creation' do
    let(:mock_client) { double('RubyLLM::MCP::Client', disconnect: nil) }

    before do
      allow(RubyLLM::MCP).to receive(:client).and_return(mock_client)
    end

    it 'creates a client with correct configuration' do
      expect(RubyLLM::MCP).to receive(:client).with(
        name: "imcp-server",
        transport_type: :stdio,
        config: {
          command: "/Applications/iMCP.app/Contents/MacOS/imcp-server 2> /dev/null"
        }
      )

      Imcp.connect
    end

    it 'stores the client in the class variable' do
      client = Imcp.connect
      expect(Imcp.client).to eq(client)
    end

    it 'returns the same client on subsequent calls' do
      client1 = Imcp.connect
      client2 = Imcp.connect
      expect(client1).to eq(client2)
    end
  end

  describe 'disconnect' do
    let(:mock_client) { double('RubyLLM::MCP::Client', disconnect: nil) }

    before do
      allow(RubyLLM::MCP).to receive(:client).and_return(mock_client)
    end

    it 'disconnects the client' do
      Imcp.connect
      expect(mock_client).to receive(:disconnect)
      
      Imcp.disconnect
      expect(Imcp.client).to be_nil
    end
  end

  describe 'connection status' do
    let(:mock_client) { double('RubyLLM::MCP::Client', disconnect: nil) }

    before do
      allow(RubyLLM::MCP).to receive(:client).and_return(mock_client)
    end

    it 'reports not connected initially' do
      expect(Imcp.connected?).to be false
    end

    it 'reports connected after connect' do
      Imcp.connect
      expect(Imcp.connected?).to be true
    end

    it 'reports not connected after disconnect' do
      Imcp.connect
      Imcp.disconnect
      expect(Imcp.connected?).to be false
    end
  end

  describe 'command configuration' do
    it 'includes stderr redirection to silence noisy output' do
      allow(RubyLLM::MCP).to receive(:client) do |args|
        expect(args[:config][:command]).to include('2> /dev/null')
        double('Client', disconnect: nil)
      end

      Imcp.connect
    end
  end
end