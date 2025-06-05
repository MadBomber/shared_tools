# frozen_string_literal: true

require "spec_helper"

RSpec.describe SharedTools do
  describe "logger functionality" do
    it "provides automatic logger access to classes in the SharedTools namespace" do
      # Create a test class in the SharedTools namespace
      module SharedTools
        class TestClass
          def log_something
            logger.info("Test log message")
          end
        end
      end

      # The test class should have logger method automatically
      expect(SharedTools::TestClass.new).to respond_to(:logger)
      expect(SharedTools::TestClass).to respond_to(:logger)
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
  end
end
