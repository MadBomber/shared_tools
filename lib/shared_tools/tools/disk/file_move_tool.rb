# frozen_string_literal: true

require_relative "local_driver"

module SharedTools
  module Tools
    module Disk
      # @example
      #   tool = SharedTools::Tools::Disk::FileMoveTool.new(root: "./project")
      #   tool.execute(
      #     path: "./README.txt",
      #     destination: "./README.md",
      #   )
      class FileMoveTool < ::RubyLLM::Tool
        def self.name = 'disk_file_move'

        description "Moves a file."

        param :path, desc: "a path (e.g. `./old.rb`)"
        param :destination, desc: "a path (e.g. `./new.rb`)"

        def initialize(driver: nil, logger: nil)
          @driver = driver || SharedTools::Tools::Disk::LocalDriver.new(root: Dir.pwd)
          @logger = logger || RubyLLM.logger
        end

        # @param path [String]
        # @param destination [String]
        #
        # @return [String]
        def execute(path:, destination:)
          @logger.info("#{self.class.name}#execute path=#{path.inspect} destination=#{destination.inspect}")
          @driver.file_move(path:, destination:)
        rescue SecurityError => e
          @logger.info("ERROR: #{e.message}")
          raise e
        end
      end
    end
  end
end
