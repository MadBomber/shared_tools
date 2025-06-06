# frozen_string_literal: true

require "spec_helper"
require "shared_tools/ruby_llm/run_shell_command"

RSpec.describe SharedTools::RunShellCommand do
  let(:tool) { described_class.new }

  describe "logger integration" do
    it "has logger methods automatically injected" do
      expect(tool).to respond_to(:logger)
      expect(described_class).to respond_to(:logger)
    end

    it "uses SharedTools logger instance" do
      expect(tool.logger).to eq(SharedTools.logger)
      expect(described_class.logger).to eq(SharedTools.logger)
    end
  end

  describe "#execute" do
    before do
      # Mock puts and gets to avoid interactive input during tests
      allow(tool).to receive(:puts)
      allow(tool).to receive(:print)
      allow(tool).to receive(:gets).and_return("n")
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
        allow(tool).to receive(:gets).and_return("n")
      end

      it "returns an error when user says no" do
        result = tool.execute(command: "echo hello")
        
        expect(result).to be_a(Hash)
        expect(result).to have_key(:error)
        expect(result[:error]).to include("User declined to execute")
      end
    end

    context "when user approves execution" do
      before do
        allow(tool).to receive(:gets).and_return("y")
      end

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
        allow(tool).to receive(:gets).and_return("Y")
        
        result = tool.execute(command: "echo test")
        
        expect(result).to have_key(:stdout)
      end

      it "rejects 'N' as decline" do
        allow(tool).to receive(:gets).and_return("N")
        
        result = tool.execute(command: "echo test")
        
        expect(result).to have_key(:error)
        expect(result[:error]).to include("User declined")
      end

      it "rejects random input as decline" do
        allow(tool).to receive(:gets).and_return("maybe")
        
        result = tool.execute(command: "echo test")
        
        expect(result).to have_key(:error)
        expect(result[:error]).to include("User declined")
      end
    end
  end
end