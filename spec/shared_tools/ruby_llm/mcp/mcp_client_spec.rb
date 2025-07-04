# frozen_string_literal: true

require 'spec_helper'
require 'shared_tools/ruby_llm/mcp/mcp_client'

RSpec.describe McpClient do
  let(:mock_client) { double('MockMcpClient', disconnect: nil) }
  let(:test_client_class) do
    mock = mock_client
    Class.new(McpClient) do
      define_singleton_method(:name) { 'TestMcpClient' }

      private

      define_singleton_method(:create_client) { mock }
    end
  end

  describe '.connect' do
    it 'creates and returns a client' do
      client = test_client_class.connect
      expect(client).not_to be_nil
      expect(test_client_class.client).to eq(client)
    end

    it 'returns existing client if already connected' do
      client1 = test_client_class.connect
      client2 = test_client_class.connect
      expect(client1).to eq(client2)
    end
  end

  describe '.disconnect' do
    it 'disconnects the client and clears the reference' do
      client = test_client_class.connect
      expect(client).to receive(:disconnect)
      
      test_client_class.disconnect
      expect(test_client_class.client).to be_nil
    end

    it 'handles nil client gracefully' do
      test_client_class.disconnect
      expect(test_client_class.client).to be_nil
    end

    it 'handles client without disconnect method' do
      allow(test_client_class).to receive(:create_client).and_return(double('Client'))
      test_client_class.connect
      
      expect { test_client_class.disconnect }.not_to raise_error
      expect(test_client_class.client).to be_nil
    end
  end

  describe '.connected?' do
    it 'returns false when no client is connected' do
      expect(test_client_class.connected?).to be false
    end

    it 'returns true when client is connected' do
      test_client_class.connect
      expect(test_client_class.connected?).to be true
    end

    it 'returns false after disconnect' do
      test_client_class.connect
      test_client_class.disconnect
      expect(test_client_class.connected?).to be false
    end
  end

  describe '.create_client' do
    it 'raises NotImplementedError in base class' do
      expect { McpClient.send(:create_client) }.to raise_error(NotImplementedError, 'Subclasses must implement create_client method')
    end
  end

  describe 'class variable isolation' do
    let(:another_mock_client) { double('AnotherMockMcpClient', disconnect: nil) }
    let(:another_client_class) do
      mock = another_mock_client
      Class.new(McpClient) do
        define_singleton_method(:name) { 'AnotherTestMcpClient' }

        private

        define_singleton_method(:create_client) { mock }
      end
    end

    it 'maintains separate client instances for different subclasses' do
      client1 = test_client_class.connect
      client2 = another_client_class.connect
      
      expect(client1).not_to eq(client2)
      expect(test_client_class.client).to eq(client1)
      expect(another_client_class.client).to eq(client2)
    end
  end
end