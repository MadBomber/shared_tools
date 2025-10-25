# frozen_string_literal: true

module SharedTools
  module Tools
    module Disk
      # @example
      #   class ExampleTool < SharedTools::Tools::Disk::BaseTool
      #     description "..."
      #   end
      class BaseTool
        # @param driver [SharedTools::Tools::Disk::BaseDriver] A driver for interacting with the disk.
        # @param logger [IO] An optional logger for debugging executed commands.
        def initialize(driver:, logger: Logger.new(IO::NULL))
          @driver = driver
          @logger = logger
        end
      end
    end
  end
end
