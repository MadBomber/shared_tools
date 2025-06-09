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
  end

  after(:each) do
    # Clean up after each test
    SharedTools.send(:remove_const, :RunShellCommand) if SharedTools.const_defined?(:RunShellCommand, false)
  end

  describe "when ruby_llm gem is loaded" do
    before { require 'ruby_llm' }
    
    it "loads RunShellCommand as a RubyLLM::Tool class" do
      SharedTools.load_ruby_llm_tools

      expect(SharedTools.const_defined?(:RunShellCommand, false)).to be true
      run_shell_command = SharedTools::RunShellCommand
      
      expect(run_shell_command).to be_a(Class)
      expect(run_shell_command < ::RubyLLM::Tool).to be true
      expect(run_shell_command.instance_methods).to include(:execute)
      expect(detect_run_shell_command_version).to eq(:ruby_llm)
    end
  end

  describe "when llm.rb gem is loaded" do
    before { require 'llm' }
    
    it "loads RunShellCommand as an LLM function object" do
      SharedTools::LLM # Trigger autoloading

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
      # Ensure both gems are loaded
      require 'ruby_llm'
      require 'llm'
      
      # Test ruby_llm version
      SharedTools.load_ruby_llm_tools
      expect(detect_run_shell_command_version).to eq(:ruby_llm)
      ruby_llm_version = SharedTools::RunShellCommand
      
      # Clear and test llm.rb version
      SharedTools.send(:remove_const, :RunShellCommand)
      SharedTools::LLM # Trigger autoloading
      expect(detect_run_shell_command_version).to eq(:llm_rb)
      llm_rb_version = SharedTools::RunShellCommand
      
      # Verify they are different types
      expect(ruby_llm_version.class).not_to eq(llm_rb_version.class)
      expect(ruby_llm_version).to be_a(Class)
      expect(llm_rb_version).not_to be_a(Class)
    end
  end
end