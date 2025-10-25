# frozen_string_literal: true

require_relative "local_driver"

module SharedTools
  module Tools
    module Disk
      # @example
      #   tool = SharedTools::Tools::Disk::DirectoryMoveTool.new(root: "./project")
      #   tool.execute(path: "./foo", destination: "./bar")
      class DirectoryMoveTool < ::RubyLLM::Tool
        def self.name = 'disk_directory_move'

        description "Moves a directory from one location to another."

        param :path, desc: "a path (e.g. `./old`)"
        param :destination, desc: "a path (e.g. `./new`)"

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
          @driver.directory_move(path:, destination:)
        rescue SecurityError => e
          @logger.error(e.message)
          raise e
        end
      end
    end
  end
end
