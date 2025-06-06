# frozen_string_literal: true

require "spec_helper"

RSpec.describe SharedTools do
  describe "logger functionality" do
    # it "provides automatic logger access to classes in the SharedTools namespace" do
    #   # Create a test class in the SharedTools namespace
    #   module SharedTools
    #     class TestClass
    #       include SharedTools

    #       def log_something
    #         logger.info("Test log message")
    #       end
    #     end
    #   end

    #   # The test class should have logger method automatically
    #   expect(SharedTools::TestClass.new).to respond_to(:logger)
    #   expect(SharedTools::TestClass).to respond_to(:logger)
    # end

    it "automatically injects logger into RubyLLM::Tool subclasses" do
      # Create a test RubyLLM::Tool subclass in the SharedTools namespace
      module SharedTools
        class TestTool < RubyLLM::Tool
          def test_logger_access
            logger.info("Test from RubyLLM tool")
          end
        end
      end

      # The tool class should have logger methods automatically injected
      expect(SharedTools::TestTool.new).to respond_to(:logger)
      expect(SharedTools::TestTool).to respond_to(:logger)

      # The logger should be the same instance as SharedTools.logger
      expect(SharedTools::TestTool.new.logger).to eq(SharedTools.logger)
      expect(SharedTools::TestTool.logger).to eq(SharedTools.logger)
    end

    it "allows configuration of the logger" do
      # Configure the logger with a StringIO to capture output
      output = StringIO.new
      SharedTools.configure_logger do |config|
        config.log_device = output
        config.level = Logger::DEBUG
      end

      # Log a message and check it was written to our StringIO
      SharedTools.logger.debug("Test debug message")
      expect(output.string).to include("Test debug message")
    end

    it "allows setting a custom logger" do
      # Create a custom logger
      custom_output = StringIO.new
      custom_logger = Logger.new(custom_output)
      
      # Save the original logger
      original_logger = SharedTools.logger
      
      # Set the custom logger
      SharedTools.logger = custom_logger
      
      # Verify the custom logger is being used
      expect(SharedTools.logger).to eq(custom_logger)
      
      # Test that the custom logger works
      SharedTools.logger.info("Custom logger test message")
      expect(custom_output.string).to include("Custom logger test message")
      
      # Restore the original logger
      SharedTools.logger = original_logger
    end
  end
end
