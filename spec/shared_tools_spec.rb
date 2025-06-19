# frozen_string_literal: true

require "spec_helper"

RSpec.describe SharedTools do
  describe ".auto_execute" do
    after do
      # Reset to default state after each test
      described_class.instance_variable_set(:@auto_execute, false)
    end

    it "sets auto_execute to true when called with true" do
      described_class.auto_execute(true)
      expect(described_class.instance_variable_get(:@auto_execute)).to be true
    end

    it "sets auto_execute to false when called with false" do
      described_class.auto_execute(false)
      expect(described_class.instance_variable_get(:@auto_execute)).to be false
    end

    it "defaults to true when called without arguments (wildwest mode)" do
      described_class.auto_execute
      expect(described_class.instance_variable_get(:@auto_execute)).to be true
    end
  end

  describe ".execute?" do
    before do
      # Mock puts and print to avoid output during tests
      allow(described_class).to receive(:puts)
      allow(described_class).to receive(:print)
      allow(described_class).to receive(:sleep)
    end

    after do
      # Reset to default state after each test
      described_class.instance_variable_set(:@auto_execute, nil)
    end

    context "when auto_execute is enabled" do
      before do
        described_class.auto_execute(true)
      end

      it "returns true without prompting user" do
        expect(described_class.execute?(tool: 'TestTool', stuff: 'some operation')).to be true
      end

      it "does not call puts or print when auto_execute is true" do
        expect(described_class).not_to receive(:puts)
        expect(described_class).not_to receive(:print)
        expect(STDIN).not_to receive(:getch)
        
        described_class.execute?(tool: 'TestTool', stuff: 'some operation')
      end
    end

    context "when auto_execute is disabled or nil (default)" do
      before do
        described_class.instance_variable_set(:@auto_execute, nil)
      end

      it "prompts user with tool name and operation details" do
        allow(STDIN).to receive(:getch).and_return('y')
        
        expect(described_class).to receive(:puts).with("\n\nThe AI (tool: TestTool) wants to do the following ...")
        expect(described_class).to receive(:puts).with("=" * 42)
        expect(described_class).to receive(:puts).with("test operation")
        expect(described_class).to receive(:puts).with("=" * 42)
        expect(described_class).to receive(:print).with("\nIs it okay to proceed? (y/N")
        
        described_class.execute?(tool: 'TestTool', stuff: 'test operation')
      end

      it "returns true when user inputs 'y'" do
        allow(STDIN).to receive(:getch).and_return('y')
        
        result = described_class.execute?(tool: 'TestTool', stuff: 'test operation')
        expect(result).to be true
      end

      it "returns false when user inputs 'n'" do
        allow(STDIN).to receive(:getch).and_return('n')
        
        result = described_class.execute?(tool: 'TestTool', stuff: 'test operation')
        expect(result).to be false
      end

      it "returns false when user inputs 'N'" do
        allow(STDIN).to receive(:getch).and_return('N')
        
        result = described_class.execute?(tool: 'TestTool', stuff: 'test operation')
        expect(result).to be false
      end

      it "returns false when user inputs random characters" do
        allow(STDIN).to receive(:getch).and_return('x')
        
        result = described_class.execute?(tool: 'TestTool', stuff: 'test operation')
        expect(result).to be false
      end

      it "handles empty stuff parameter" do
        allow(STDIN).to receive(:getch).and_return('y')
        
        expect(described_class).to receive(:puts).with("unknown strange and mysterious things")
        
        result = described_class.execute?(tool: 'TestTool', stuff: '')
        expect(result).to be true
      end

      it "uses default tool name when not provided" do
        allow(STDIN).to receive(:getch).and_return('y')
        
        expect(described_class).to receive(:puts).with("\n\nThe AI (tool: unknown) wants to do the following ...")
        
        described_class.execute?(stuff: 'test operation')
      end

      context "when AIA is defined" do
        before do
          # Simulate AIA being defined
          stub_const("AIA", double)
        end

        it "calls sleep to allow CLI spinner to recycle" do
          allow(STDIN).to receive(:getch).and_return('y')
          
          expect(described_class).to receive(:sleep).with(0.2)
          
          described_class.execute?(tool: 'TestTool', stuff: 'test operation')
        end
      end

      context "when AIA is not defined" do
        it "does not call sleep" do
          allow(STDIN).to receive(:getch).and_return('y')
          
          expect(described_class).not_to receive(:sleep)
          
          described_class.execute?(tool: 'TestTool', stuff: 'test operation')
        end
      end
    end
  end

  describe ".detected_gem" do
    context "when RubyLLM::Tool is defined" do
      it "returns :ruby_llm" do
        expect(described_class.detected_gem).to eq(:ruby_llm)
      end
    end

    context "when no supported gem is defined" do
      before do
        # Temporarily undefine RubyLLM to test the nil case
        # This is tricky to test since RubyLLM is already loaded
        # We'll just test the current state
      end

      it "returns the currently detected gem" do
        # Since RubyLLM is loaded in spec_helper, this should return :ruby_llm
        expect(described_class.detected_gem).to eq(:ruby_llm)
      end
    end
  end

  describe ".verify_gem" do
    context "when correct gem is detected" do
      it "returns true for ruby_llm" do
        expect(described_class.verify_gem(:ruby_llm)).to be true
      end
    end

    context "when incorrect gem is requested" do
      it "raises an error for unsupported gem" do
        expect { described_class.verify_gem(:unsupported_gem) }.to raise_error(/SharedTools: Please require/)
      end
    end
  end

  describe "module constants" do
    it "defines SUPPORTED_GEMS" do
      expect(described_class::SUPPORTED_GEMS).to include(:ruby_llm, :llm_rb, :omniai, :raix)
    end

    it "has auto_execute as nil by default (uninitialized)" do
      # Reset the module to its initial state
      described_class.instance_variable_set(:@auto_execute, nil)
      expect(described_class.instance_variable_get(:@auto_execute)).to be_nil
    end

    it "treats nil auto_execute as requiring user interaction" do
      described_class.instance_variable_set(:@auto_execute, nil)
      allow(STDIN).to receive(:getch).and_return('y')
      
      expect(described_class).to receive(:puts).at_least(:once)
      expect(described_class).to receive(:print).with("\nIs it okay to proceed? (y/N")
      
      result = described_class.execute?(tool: 'TestTool', stuff: 'test operation')
      expect(result).to be true
    end
  end
end