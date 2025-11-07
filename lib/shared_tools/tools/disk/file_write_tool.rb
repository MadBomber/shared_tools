# frozen_string_literal: true

require_relative "local_driver"

module SharedTools
  module Tools
    module Disk
      # @example
      #    tool = SharedTools::Tools::Disk::FileWriteTool.new(root: "./project")
      #    tool.execute(path: "./README.md", text: "Hello World")
      class FileWriteTool < ::RubyLLM::Tool
        def self.name = 'disk_file_write'

        description "Writes the contents of a file."

        params do
          string :path, description: "a path for the file (e.g. `./main.rb`)"
          string :text, description: "the text to write to the file (e.g. `puts 'Hello World'`)"
        end

        def initialize(driver: nil, logger: nil)
          @driver = driver || SharedTools::Tools::Disk::LocalDriver.new(root: Dir.pwd)
          @logger = logger || RubyLLM.logger
        end

        # @param path [String]
        # @param text [String]
        #
        # @return [String]
        def execute(path:, text:)
          @logger.info("#{self.class.name}#execute path=#{path}")
          @driver.file_write(path:, text:)
        rescue SecurityError => e
          @logger.error("ERROR: #{e.message}")
          raise e
        end
      end
    end
  end
end
