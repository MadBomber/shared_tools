# frozen_string_literal: true

require "spec_helper"

RSpec.describe "SharedTools::RunShellCommand version detection" do
  # Helper method to detect which version of RunShellCommand is loaded
  def detect_run_shell_command_version
    return :not_defined unless SharedTools.const_defined?(:RunShellCommand, false)
    
    run_shell_command = SharedTools::RunShellCommand
    
    if run_shell_command.is_a?(Class) && defined?(::RubyLLM::Tool) && run_shell_command < ::RubyLLM::Tool
      :ruby_llm
    elsif run_shell_command.respond_to?(:call) && run_shell_command.instance_variables.include?(:@description)
      :llm_rb
    else
      :unknown
    end
  end

  before(:each) do
    # Remove any existing RunShellCommand constant to start fresh
    SharedTools.send(:remove_const, :RunShellCommand) if SharedTools.const_defined?(:RunShellCommand, false)
    # Clear require cache to allow re-requiring
    $LOADED_FEATURES.reject! { |f| f.match(/shared_tools\/(ruby_llm|llm)/) }
  end

  after(:each) do
    # Clean up after each test
    SharedTools.send(:remove_const, :RunShellCommand) if SharedTools.const_defined?(:RunShellCommand, false)
  end

  describe "when ruby_llm gem is loaded" do
    it "loads RunShellCommand as a RubyLLM::Tool class" do
      skip "ruby_llm gem not available" unless defined?(::RubyLLM::Tool)
      
      # Load ruby_llm tools using the new require pattern
      require 'shared_tools/ruby_llm'

      expect(SharedTools.const_defined?(:RunShellCommand, false)).to be true
      run_shell_command = SharedTools::RunShellCommand
      
      expect(run_shell_command).to be_a(Class)
      expect(run_shell_command < ::RubyLLM::Tool).to be true
      expect(run_shell_command.instance_methods).to include(:execute)
      expect(detect_run_shell_command_version).to eq(:ruby_llm)
    end
  end

  describe "when llm.rb gem is loaded" do
    it "loads RunShellCommand as an LLM function object" do
      skip "llm.rb gem not available" unless defined?(::LLM)
      
      # Load specific tool using new pattern
      require 'shared_tools/llm/run_shell_command'

      expect(SharedTools.const_defined?(:RunShellCommand, false)).to be true
      run_shell_command = SharedTools::RunShellCommand
      
      expect(run_shell_command).not_to be_a(Class)
      expect(run_shell_command).to respond_to(:call)
      expect(run_shell_command.instance_variables).to include(:@description)
      expect(detect_run_shell_command_version).to eq(:llm_rb)
    end
  end

  describe "version detection across gem scenarios" do
    it "demonstrates the difference between the two implementations" do
      # This test demonstrates what happens when different gems are loaded
      # We can only run this if we have the appropriate gems available
      
      if defined?(::RubyLLM::Tool)
        # Test ruby_llm version
        require 'shared_tools/ruby_llm'
        expect(detect_run_shell_command_version).to eq(:ruby_llm)
        ruby_llm_class = SharedTools::RunShellCommand
        
        expect(ruby_llm_class).to be_a(Class)
        expect(ruby_llm_class < ::RubyLLM::Tool).to be true
        
        # Clean up for potential next test
        SharedTools.send(:remove_const, :RunShellCommand) if SharedTools.const_defined?(:RunShellCommand, false)
      end
      
      if defined?(::LLM)
        # Test llm.rb version
        require 'shared_tools/llm/run_shell_command'
        expect(detect_run_shell_command_version).to eq(:llm_rb)
        llm_rb_function = SharedTools::RunShellCommand
        
        expect(llm_rb_function).not_to be_a(Class)
        expect(llm_rb_function).to respond_to(:call)
      end
      
      skip "Neither ruby_llm nor llm.rb gems are available" unless defined?(::RubyLLM::Tool) || defined?(::LLM)
    end
  end
end