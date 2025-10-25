# frozen_string_literal: true


module SharedTools
  module Tools
    module Disk
      # @example
      #   tool = SharedTools::Tools::Disk::FileCreateTool.new(root: "./project")
      #   tool.execute(path: "./README.md")
      class FileCreateTool < ::RubyLLM::Tool
        def self.name = 'disk_file_create'

        description "Creates a file."

        param :path, desc: "a path to the file (e.g. `./README.md`)"

        def initialize(driver: nil, logger: nil)
          @driver = driver || LocalDriver.new(root: Dir.pwd)
          @logger = logger || RubyLLM.logger
        end

        # @param path [String]
        #
        # @return [String]
        def execute(path:)
          @logger.info("#{self.class.name}#execute path=#{path.inspect}")
          @driver.file_create(path:)
        rescue SecurityError => e
          @logger.error(e.message)
          raise e
        end
      end
    end
  end
end
