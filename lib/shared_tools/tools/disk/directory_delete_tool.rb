# frozen_string_literal: true

require_relative "local_driver"

module SharedTools
  module Tools
    module Disk
      # @example
      #   tool = SharedTools::Tools::Disk::DirectoryDeleteTool.new(root: "./project")
      #   tool.execute(path: "./foo/bar")
      class DirectoryDeleteTool < ::RubyLLM::Tool
        def self.name = 'disk_directory_delete'

        description "Deletes a directory."

        param :path, desc: "a path to the directory (e.g. `./foo/bar`)"

        def initialize(driver: nil, logger: nil)
          @driver = driver || SharedTools::Tools::Disk::LocalDriver.new(root: Dir.pwd)
          @logger = logger || RubyLLM.logger
        end

        # @param path [String]
        #
        # @return [String]
        def execute(path:)
          @logger.info("#{self.class.name}#execute path=#{path.inspect}")

          @driver.directory_delete(path:)
        rescue SecurityError => e
          @logger.error(e.message)
          raise e
        end
      end
    end
  end
end
