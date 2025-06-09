# frozen_string_literal: true

require "spec_helper"
require "shared_tools/ruby_llm/ruby_eval"
require "stringio"

RSpec.describe SharedTools::RubyEval do
  let(:tool) { described_class.new }

  describe "logger integration" do
    it "has logger methods available" do
      expect(tool).to respond_to(:logger)
    end

    it "logger is functional" do
      expect(tool.logger).to respond_to(:info)
      expect(tool.logger).to respond_to(:debug)
      expect(tool.logger).to respond_to(:error)
    end
  end

  describe "#execute" do
    before do
      # Mock user input to always say "yes" for test execution
      allow_any_instance_of(Object).to receive(:gets).and_return("y\n")
    end

    context "with valid Ruby code" do
      it "executes simple expressions and returns the result" do
        result = tool.execute(code: "2 + 2")
        
        expect(result[:success]).to be true
        expect(result[:result]).to eq(4)
        expect(result[:display]).to eq("4")
      end

      it "executes code with output and returns both output and result" do
        result = tool.execute(code: "puts 'Hello'; 42")
        
        expect(result[:success]).to be true
        expect(result[:result]).to eq(42)
        expect(result[:output]).to eq("Hello\n")
        expect(result[:display]).to eq("Hello\n\n=> 42")
      end

      it "handles code that only produces output" do
        result = tool.execute(code: "puts 'Hello World'")
        
        expect(result[:success]).to be true
        expect(result[:result]).to be_nil
        expect(result[:output]).to eq("Hello World\n")
        expect(result[:display]).to eq("Hello World\n")
      end

      it "handles complex expressions" do
        code = "[1, 2, 3].map { |x| x * 2 }.sum"
        result = tool.execute(code: code)
        
        expect(result[:success]).to be true
        expect(result[:result]).to eq(12)
        expect(result[:display]).to eq("12")
      end
    end

    context "with invalid Ruby code" do
      it "returns an error for syntax errors" do
        result = tool.execute(code: "def foo(; end")
        
        expect(result[:success]).to be false
        expect(result).to have_key(:error)
        expect(result[:error]).to include("syntax error")
      end

      it "returns an error for runtime errors" do
        result = tool.execute(code: "1 / 0")
        
        expect(result[:success]).to be false
        expect(result).to have_key(:error)
        expect(result[:error]).to include("divided by 0")
      end

      it "includes backtrace information for errors" do
        result = tool.execute(code: "raise 'Test error'")
        
        expect(result[:success]).to be false
        expect(result).to have_key(:error)
        expect(result).to have_key(:backtrace)
        expect(result[:backtrace]).to be_an(Array)
      end
    end

    context "with empty code" do
      it "returns an error" do
        result = tool.execute(code: "")
        
        expect(result).to have_key(:error)
        expect(result[:error]).to eq("Ruby code cannot be empty")
      end

      it "returns an error for whitespace-only code" do
        result = tool.execute(code: "   \n\t  ")
        
        expect(result).to have_key(:error)
        expect(result[:error]).to eq("Ruby code cannot be empty")
      end
    end

    context "when user declines execution" do
      it "returns an error when user says no" do
        allow_any_instance_of(Object).to receive(:gets).and_return("n\n")
        
        result = tool.execute(code: "puts 'Hello'")
        
        expect(result).to have_key(:error)
        expect(result[:error]).to eq("User declined to execute the Ruby code")
      end
    end
  end
end