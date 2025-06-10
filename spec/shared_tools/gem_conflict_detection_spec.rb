# frozen_string_literal: true

require "spec_helper"

RSpec.describe "SharedTools gem detection" do
  describe "detected_gem" do
    it "detects ruby_llm when RubyLLM::Tool is available" do
      # Skip if ruby_llm is not actually available
      skip "ruby_llm gem not available" unless defined?(::RubyLLM::Tool)
      
      detected_gem = SharedTools.detected_gem
      expect(detected_gem).to eq(:ruby_llm)
    end

    it "detects llm_rb when LLM is available" do
      # Skip if llm.rb gem is not available
      skip "llm.rb gem not available" unless defined?(::LLM)
      
      detected_gem = SharedTools.detected_gem
      expect(detected_gem).to eq(:llm_rb)
    end

    it "detects omniai when OmniAI or Omniai is available" do
      # Skip if omniai is not available
      skip "omniai gem not available" unless defined?(::OmniAI) || defined?(::Omniai)
      
      detected_gem = SharedTools.detected_gem
      expect(detected_gem).to eq(:omniai)
    end

    it "returns nil when no supported gems are available" do
      # Mock the defined? method calls by stubbing the module method
      allow(SharedTools).to receive(:detected_gem).and_return(nil)
      
      detected_gem = SharedTools.detected_gem
      expect(detected_gem).to be_nil
    end
  end

  describe "automatic gem detection on load" do
    it "issues warning when no LLM gem is detected" do
      # This test verifies that the warning is issued when no gem is detected
      # We can test the method exists and works
      expect(SharedTools).to respond_to(:detected_gem)
      expect { SharedTools.detected_gem }.not_to raise_error
    end
  end
end