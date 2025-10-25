# frozen_string_literal: true


module SharedTools
  module Tools
    module Disk
      # @example
      #   tool = SharedTools::Tools::Disk::FileReadTool.new
      #   tool.execute(path: "./README.md") # => "..."
      class FileReadTool < ::RubyLLM::Tool
        def self.name = 'disk_file_read'

        description "Reads the contents of a file."

        param :path, desc: "a path (e.g. `./main.rb`)"

        # @param driver [SharedTools::Tools::Disk::BaseDriver] optional, defaults to LocalDriver with current directory
        # @param logger [Logger] optional logger
        def initialize(driver: nil, logger: nil)
          @driver = driver || LocalDriver.new(root: Dir.pwd)
          @logger = logger || RubyLLM.logger
        end

        # @param path [String]
        #
        # @return [String]
        def execute(path:)
          @logger.info("#{self.class.name}#execute path=#{path}")
          @driver.file_read(path:)
        rescue StandardError => e
          @logger.error(e.message)
          raise e
        end
      end
    end
  end
end
