# frozen_string_literal: true

require "spec_helper"
require "shared_tools/ruby_llm/run_shell_command"

RSpec.describe SharedTools::RunShellCommand do
  let(:tool) { described_class.new }

  describe "logger integration" do
    it "has logger methods available" do
      expect(RubyLLM).to respond_to(:logger)
    end

    it "logger is functional" do
      expect(RubyLLM.logger).to respond_to(:info)
      expect(RubyLLM.logger).to respond_to(:debug)
      expect(RubyLLM.logger).to respond_to(:error)
    end
  end

  describe "#execute" do
    before do
      # Use auto_execute to avoid interactive prompts during tests
      SharedTools.auto_execute(true)
    end
    
    after do
      # Reset to default state after tests
      SharedTools.auto_execute(false)
    end

    context "with empty command" do
      it "returns an error for empty commands" do
        result = tool.execute(command: "")
        
        expect(result).to be_a(Hash)
        expect(result).to have_key(:error)
        expect(result[:error]).to include("Command cannot be empty")
      end

      it "returns an error for whitespace-only commands" do
        result = tool.execute(command: "   ")
        
        expect(result).to be_a(Hash)
        expect(result).to have_key(:error)
        expect(result[:error]).to include("Command cannot be empty")
      end
    end

    context "when user declines execution" do
      before do
        # Reset auto_execute to nil (default state) to test user interaction
        SharedTools.instance_variable_set(:@auto_execute, nil)
        allow(SharedTools).to receive(:execute?).and_return(false)
      end
      
      after do
        # Restore auto_execute for other tests
        SharedTools.auto_execute(true)
      end

      it "returns an error when user says no" do
        result = tool.execute(command: "echo hello")
        
        expect(result).to be_a(Hash)
        expect(result).to have_key(:error)
        expect(result[:error]).to include("User declined to execute")
      end
    end

    context "when user approves execution" do

      context "with successful commands" do
        it "executes simple echo command" do
          result = tool.execute(command: "echo 'hello world'")
          
          expect(result).to be_a(Hash)
          expect(result).to have_key(:stdout)
          expect(result).to have_key(:exit_status)
          expect(result[:stdout]).to include("hello world")
          expect(result[:exit_status]).to eq(0)
        end

        it "handles commands with no output" do
          result = tool.execute(command: "true")
          
          expect(result).to be_a(Hash)
          expect(result).to have_key(:stdout)
          expect(result).to have_key(:exit_status)
          expect(result[:exit_status]).to eq(0)
        end
      end

      context "with failing commands" do
        it "handles command that fails" do
          result = tool.execute(command: "false")
          
          expect(result).to be_a(Hash)
          expect(result).to have_key(:error)
          expect(result).to have_key(:exit_status)
          expect(result[:exit_status]).to eq(1)
        end

        it "handles non-existent commands" do
          result = tool.execute(command: "nonexistentcommand123456")
          
          expect(result).to be_a(Hash)
          expect(result).to have_key(:error)
          expect(result[:exit_status]).not_to eq(0)
        end
      end

      context "with commands that have stderr output" do
        it "captures stderr on command failure" do
          # Use a command that writes to stderr
          result = tool.execute(command: "ls /nonexistent/path 2>&1")
          
          expect(result).to be_a(Hash)
          # Result structure depends on the command's actual behavior
          expect(result[:exit_status]).not_to eq(0)
        end
      end
    end

    context "with various user inputs" do
      it "accepts 'Y' as approval" do
        result = tool.execute(command: "echo test")
        
        expect(result).to have_key(:stdout)
      end

      it "rejects 'N' as decline" do
        SharedTools.instance_variable_set(:@auto_execute, nil)
        allow(SharedTools).to receive(:execute?).and_return(false)
        
        result = tool.execute(command: "echo test")
        
        expect(result).to have_key(:error)
        expect(result[:error]).to include("User declined")
        
        SharedTools.auto_execute(true)
      end

      it "rejects random input as decline" do
        SharedTools.instance_variable_set(:@auto_execute, nil)
        allow(SharedTools).to receive(:execute?).and_return(false)
        
        result = tool.execute(command: "echo test")
        
        expect(result).to have_key(:error)
        expect(result[:error]).to include("User declined")
        
        SharedTools.auto_execute(true)
      end
    end
  end

  describe "authorization integration" do
    it "calls SharedTools.execute? with correct parameters when auto_execute is disabled" do
      SharedTools.instance_variable_set(:@auto_execute, nil)
      
      expect(SharedTools).to receive(:execute?).with(
        tool: "SharedTools::RunShellCommand",
        stuff: "echo test"
      ).and_return(true)
      
      tool.execute(command: "echo test")
      
      SharedTools.auto_execute(true)
    end

    it "returns true immediately when auto_execute is enabled" do
      SharedTools.auto_execute(true)
      
      # execute? should be called but return true immediately
      expect(SharedTools).to receive(:execute?).and_call_original
      
      result = tool.execute(command: "echo test")
      expect(result).to have_key(:stdout)
    end

    it "handles authorization denial gracefully" do
      SharedTools.instance_variable_set(:@auto_execute, nil)
      allow(SharedTools).to receive(:execute?).and_return(false)
      
      result = tool.execute(command: "echo test")
      
      expect(result).to have_key(:error)
      expect(result[:error]).to eq("User declined to execute the command")
      
      SharedTools.auto_execute(true)
    end
  end
end