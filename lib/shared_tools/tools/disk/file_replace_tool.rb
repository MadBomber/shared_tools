# frozen_string_literal: true

require_relative "local_driver"

module SharedTools
  module Tools
    module Disk
      # @example
      #   tool = SharedTools::Tools::Disk::FileReadTool.new(root: "./project")
      #   tool.execute(
      #     old_text: 'puts "ABC"',
      #     new_text: 'puts "DEF"',
      #     path: "README.md"
      #   )
      class FileReplaceTool < ::RubyLLM::Tool
        def self.name = 'disk_file_replace'

        description "Replaces a specific string in a file (old_text => new_text)."

        params do
          string :old_text, description: "the old text (e.g. `puts 'ABC'`)"
          string :new_text, description: "the new text (e.g. `puts 'DEF'`)"
          string :path, description: "a path (e.g. `./main.rb`)"
        end

        def initialize(driver: nil, logger: nil)
          @driver = driver || SharedTools::Tools::Disk::LocalDriver.new(root: Dir.pwd)
          @logger = logger || RubyLLM.logger
        end

        # @param path [String]
        # @param old_text [String]
        # @param new_text [String]
        def execute(old_text:, new_text:, path:)
          @logger.info %(#{self.class.name}#execute old_text="#{old_text}" new_text="#{new_text}" path="#{path}")
          @driver.file_replace(old_text:, new_text:, path:)
        rescue SecurityError => e
          @logger.error(e.message)
          raise e
        end
      end
    end
  end
end
