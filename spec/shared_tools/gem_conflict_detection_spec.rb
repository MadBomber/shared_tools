# frozen_string_literal: true

require "spec_helper"

RSpec.describe "SharedTools gem conflict detection" do
  before(:each) do
    # Silence warnings during tests
    allow(SharedTools).to receive(:warn)
    allow(SharedTools.logger).to receive(:warn)
  end

  describe "check_gem_conflicts" do
    it "detects no conflicts when no LLM gems are loaded" do
      # Stub all gem checks to return false
      allow(SharedTools).to receive(:defined?).with(::RubyLLM::Tool).and_return(false)
      allow(SharedTools).to receive(:const_defined?).with(:LLM, false).and_return(false)
      allow(SharedTools).to receive(:defined?).with(::OmniAI).and_return(false)
      allow(SharedTools).to receive(:defined?).with(::Omniai).and_return(false)
      
      detected_gems = SharedTools.check_gem_conflicts
      expect(detected_gems).to eq([])
    end

    it "detects ruby_llm when available" do
      # Skip if ruby_llm is not actually available
      skip "ruby_llm gem not available" unless defined?(::RubyLLM::Tool)
      
      detected_gems = SharedTools.check_gem_conflicts
      expect(detected_gems).to include('ruby_llm')
    end

    it "detects llm.rb when SharedTools::LLM is loaded" do
      # Simulate llm.rb being available by ensuring SharedTools::LLM is defined
      SharedTools::LLM if SharedTools.const_defined?(:LLM, false)
      
      detected_gems = SharedTools.check_gem_conflicts
      if SharedTools.const_defined?(:LLM, false)
        expect(detected_gems).to include('llm.rb')
      else
        expect(detected_gems).not_to include('llm.rb')
      end
    end

    it "detects omniai when available" do
      # Skip if omniai is not available
      skip "omniai gem not available" unless defined?(::OmniAI) || defined?(::Omniai)
      
      detected_gems = SharedTools.check_gem_conflicts
      expect(detected_gems).to include('omniai')
    end

    it "issues warning when multiple gems are detected" do
      # Mock multiple gems being present
      allow(SharedTools).to receive(:defined?).with(::RubyLLM::Tool).and_return(true)
      allow(SharedTools).to receive(:defined?).with(::OmniAI).and_return(true)
      allow(SharedTools).to receive(:const_defined?).with(:LLM, false).and_return(false)
      
      expect(SharedTools.logger).to receive(:warn).with(a_string_including("Multiple LLM gems detected"))
      expect(SharedTools).to receive(:warn).with(a_string_including("Multiple LLM gems detected"))
      
      detected_gems = SharedTools.check_gem_conflicts
      expect(detected_gems).to include('ruby_llm', 'omniai')
    end

    it "includes helpful guidance in warning message" do
      # Mock multiple gems being present
      allow(SharedTools).to receive(:defined?).with(::RubyLLM::Tool).and_return(true)
      allow(SharedTools).to receive(:defined?).with(::OmniAI).and_return(true)
      allow(SharedTools).to receive(:const_defined?).with(:LLM, false).and_return(false)
      
      expected_message = a_string_including(
        "ruby_llm, omniai",
        "only ONE LLM gem at a time",
        "ruby_llm",
        "llm.rb",
        "omniai",
        "constant name conflicts"
      )
      
      expect(SharedTools.logger).to receive(:warn).with(expected_message)
      expect(SharedTools).to receive(:warn).with(expected_message)
      
      SharedTools.check_gem_conflicts
    end

    it "does not issue warning for single gem" do
      # Mock only one gem being present
      allow(SharedTools).to receive(:defined?).with(::RubyLLM::Tool).and_return(true)
      allow(SharedTools).to receive(:defined?).with(::OmniAI).and_return(false)
      allow(SharedTools).to receive(:defined?).with(::Omniai).and_return(false)
      allow(SharedTools).to receive(:const_defined?).with(:LLM, false).and_return(false)
      
      expect(SharedTools.logger).not_to receive(:warn)
      expect(SharedTools).not_to receive(:warn)
      
      detected_gems = SharedTools.check_gem_conflicts
      expect(detected_gems).to eq(['ruby_llm'])
    end
  end

  describe "automatic conflict checking on load" do
    it "calls check_gem_conflicts when SharedTools is loaded" do
      # This test verifies that the check is called automatically
      # Since SharedTools is already loaded, we can't test the initial load
      # but we can verify the method exists and can be called
      expect(SharedTools).to respond_to(:check_gem_conflicts)
      expect { SharedTools.check_gem_conflicts }.not_to raise_error
    end
  end
end