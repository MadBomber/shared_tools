# frozen_string_literal: true

require_relative "local_driver"

module SharedTools
  module Tools
    module Disk
      # @example
      #   tool = SharedTools::Tools::Disk::FileDeleteTool.new(root: "./project")
      #   tool.execute(path: "./README.md")
      class FileDeleteTool < ::RubyLLM::Tool
        def self.name = 'disk_file_delete'

        description "Deletes a file."

        params do
          string :path, description: "a path to the file (e.g. `./README.md`)"
        end

        def initialize(driver: nil, logger: nil)
          @driver = driver || SharedTools::Tools::Disk::LocalDriver.new(root: Dir.pwd)
          @logger = logger || RubyLLM.logger
        end

        # @param path [String]
        #
        # @raise [SecurityError]
        #
        # @return [String]
        def execute(path:)
          @logger.info("#{self.class.name}#execute path=#{path.inspect}")
          @driver.file_delete(path:)
        rescue SecurityError => e
          @logger.error(e.message)
          raise e
        end
      end
    end
  end
end
