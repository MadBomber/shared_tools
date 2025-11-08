# frozen_string_literal: true

require_relative "local_driver"

module SharedTools
  module Tools
    module Disk
      # @example
      #   tool = SharedTools::Tools::Disk::SummaryTool.new(root: "./project")
      #   tool.execute
      class DirectoryListTool < ::RubyLLM::Tool
        def self.name = 'disk_directory_list'

        description "Summarizes the contents (files and directories) of a directory."

        params do
          string :path, description: "a path to the directory (e.g. `./foo/bar`)", required: false
        end

        def initialize(driver: nil, logger: nil)
          @driver = driver || SharedTools::Tools::Disk::LocalDriver.new(root: Dir.pwd)
          @logger = logger || RubyLLM.logger
        end

        # @return [String]
        def execute(path: ".")
          @logger.info("#{self.class.name}#execute")

          @driver.directory_list(path:)
        rescue SecurityError => e
          @logger.error(e.message)
          raise e
        end
      end
    end
  end
end
