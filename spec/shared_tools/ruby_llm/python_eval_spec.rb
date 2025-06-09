# frozen_string_literal: true

require "spec_helper"
require "shared_tools/ruby_llm/python_eval"

RSpec.describe SharedTools::PythonEval do
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

    context "with valid Python code" do
      it "executes simple Python expressions and returns the result" do
        result = tool.execute(code: "2 + 2")
        
        expect(result[:success]).to be true
        expect(result[:result]).to eq(4)
        expect(result[:display]).to eq("4")
      end

      it "executes Python code with output and returns both output and result" do
        result = tool.execute(code: "print('Hello'); 42")
        
        expect(result[:success]).to be true
        expect(result[:result]).to eq(42)
        expect(result[:output]).to eq("Hello\n")
        expect(result[:display]).to eq("Hello\n\n=> 42")
      end

      it "handles Python code that only produces output" do
        result = tool.execute(code: "print('Hello World')")
        
        expect(result[:success]).to be true
        expect(result[:result]).to be_nil
        expect(result[:output]).to eq("Hello World\n")
        expect(result[:display]).to eq("Hello World\n")
      end

      it "handles Python list operations" do
        code = "[x * 2 for x in [1, 2, 3]]"
        result = tool.execute(code: code)
        
        expect(result[:success]).to be true
        expect(result[:result]).to eq([2, 4, 6])
        expect(result[:display]).to eq("[2, 4, 6]")
      end

      it "handles Python dictionary operations" do
        code = "{'name': 'test', 'value': 42}"
        result = tool.execute(code: code)
        
        expect(result[:success]).to be true
        expect(result[:result]).to be_a(Hash)
        expect(result[:result]["name"]).to eq("test")
        expect(result[:result]["value"]).to eq(42)
      end

      it "handles importing Python modules" do
        code = "import math; math.sqrt(16)"
        result = tool.execute(code: code)
        
        expect(result[:success]).to be true
        expect(result[:result]).to eq(4.0)
      end
    end

    context "with invalid Python code" do
      it "returns an error for Python syntax errors" do
        result = tool.execute(code: "def foo(:")
        
        expect(result[:success]).to be false
        expect(result).to have_key(:error)
        expect(result[:error]).to include("syntax") if result[:error]
      end

      it "returns an error for Python runtime errors" do
        result = tool.execute(code: "1 / 0")
        
        expect(result[:success]).to be false
        expect(result).to have_key(:error)
        expect(result[:error]).to include("division by zero") if result[:error]
      end

      it "includes Python error type information for errors" do
        result = tool.execute(code: "raise ValueError('Test error')")
        
        expect(result[:success]).to be false
        expect(result).to have_key(:error)
        expect(result).to have_key(:error_type)
      end
    end

    context "with empty code" do
      it "returns an error" do
        result = tool.execute(code: "")
        
        expect(result).to have_key(:error)
        expect(result[:error]).to eq("Python code cannot be empty")
      end

      it "returns an error for whitespace-only code" do
        result = tool.execute(code: "   \n\t  ")
        
        expect(result).to have_key(:error)
        expect(result[:error]).to eq("Python code cannot be empty")
      end
    end

    context "when user declines execution" do
      it "returns an error when user says no" do
        allow_any_instance_of(Object).to receive(:gets).and_return("n\n")
        
        result = tool.execute(code: "print('Hello')")
        
        expect(result).to have_key(:error)
        expect(result[:error]).to eq("User declined to execute the Python code")
      end
    end
  end

  describe "private methods" do
    let(:tool_instance) { described_class.new }
    
    it "creates Python wrapper with base64 encoding" do
      wrapper = tool_instance.send(:create_python_wrapper, "print('hello')")
      expect(wrapper).to include("base64.b64decode")
      expect(wrapper).to include("import json")
    end

    it "handles complex code with base64 encoding" do
      complex_code = "def foo():\n    print('test '''quotes''')\n    return 42\nfoo()"
      wrapper = tool_instance.send(:create_python_wrapper, complex_code)
      expect(wrapper).to include("base64.b64decode")
    end
  end
end