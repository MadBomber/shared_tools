# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  module Tools
    # A tool for interacting with files and directories. Be careful using as it can perform actions on your computer!
    #
    # @example
    #   disk = SharedTools::Tools::DiskTool.new
    #   disk.execute(action: SharedTools::Tools::DiskTool::Action::FILE_CREATE, path: "./demo.rb")
    #   disk.execute(action: SharedTools::Tools::DiskTool::Action::FILE_WRITE, path: "./demo.rb", text: "puts 'Hello'")
    #   disk.execute(action: SharedTools::Tools::DiskTool::Action::FILE_READ, path: "./demo.rb")
    #   disk.execute(action: SharedTools::Tools::DiskTool::Action::FILE_DELETE, path: "./demo.rb")
    class DiskTool < ::RubyLLM::Tool
      def self.name = 'disk_tool' 
      description <<~TEXT
        A tool for interacting with a system. It is able to list, create, delete, move and modify directories and files.
      TEXT

      module Action
        DIRECTORY_CREATE = "directory_create"
        DIRECTORY_DELETE = "directory_delete"
        DIRECTORY_MOVE = "directory_move"
        DIRECTORY_LIST = "directory_list"
        FILE_CREATE = "file_create"
        FILE_DELETE = "file_delete"
        FILE_MOVE = "file_move"
        FILE_READ = "file_read"
        FILE_WRITE = "file_write"
        FILE_REPLACE = "file_replace"
      end

      ACTIONS = [
        Action::DIRECTORY_CREATE,
        Action::DIRECTORY_DELETE,
        Action::DIRECTORY_MOVE,
        Action::DIRECTORY_LIST,
        Action::FILE_CREATE,
        Action::FILE_DELETE,
        Action::FILE_MOVE,
        Action::FILE_READ,
        Action::FILE_WRITE,
        Action::FILE_REPLACE,
      ].freeze

      params do
        string :action, description: <<~TEXT.strip
          Options:
          * `#{Action::DIRECTORY_CREATE}`: creates a directory at a specific `path`
          * `#{Action::DIRECTORY_DELETE}`: deletes a directory at a specific `path`
          * `#{Action::DIRECTORY_MOVE}`: moves a directory from `path` to (`to`)
          * `#{Action::DIRECTORY_LIST}`: lists the contents of a directory at a specific `path` (use '.' for root)
          * `#{Action::FILE_CREATE}`: creates a file at a specific `path`
          * `#{Action::FILE_DELETE}`: deletes a file at a specific `path`
          * `#{Action::FILE_MOVE}`: moves a file from `path` to another
          * `#{Action::FILE_READ}`: reads the contents of a file at a specific path
          * `#{Action::FILE_WRITE}`: writes the contents of a file at a specific path
          * `#{Action::FILE_REPLACE}`: replaces the contents of a file at a specific path
        TEXT

        string :path, description: <<~TEXT.strip
          A file or directory path that is required for the following actions:
          * `#{Action::DIRECTORY_CREATE}`
          * `#{Action::DIRECTORY_DELETE}`
          * `#{Action::DIRECTORY_MOVE}`
          * `#{Action::DIRECTORY_LIST}`
          * `#{Action::FILE_DELETE}`
          * `#{Action::FILE_READ}`
          * `#{Action::FILE_WRITE}`
          * `#{Action::FILE_REPLACE}`
        TEXT

        string :destination, description: <<~TEXT.strip, required: false
          A file or directory path that is required for the following actions:
          * `#{Action::DIRECTORY_MOVE}`
          * `#{Action::FILE_MOVE}`
        TEXT

        string :text, description: <<~TEXT.strip, required: false
          The text to be written to a file for the `#{Action::FILE_WRITE}` action.
        TEXT

        string :old_text, description: <<~TEXT.strip, required: false
          The old text to be replaced in a file for the `#{Action::FILE_REPLACE}` action.
        TEXT

        string :new_text, description: <<~TEXT.strip, required: false
          The new text to replace in a few file for the `#{Action::FILE_REPLACE}` action.
        TEXT
      end


      # @param driver [SharedTools::Tools::Disk::BaseDriver] optional, defaults to LocalDriver with current directory
      # @param logger [Logger] optional logger
      def initialize(driver: nil, logger: nil)
        @driver = driver || Disk::LocalDriver.new(root: Dir.pwd)
        @logger = logger || RubyLLM.logger
      end

      # @param action [String]
      # @param path [String]
      # @param destination [String] optional
      # @param old_text [String] optional
      # @param new_text [String] optional
      # @param text [String] optional
      def execute(action:, path:, destination: nil, old_text: nil, new_text: nil, text: nil)
        @logger.info({
          action:,
          path:,
          destination:,
          old_text:,
          new_text:,
          text:,
        }.compact.map { |key, value| "#{key}=#{value.inspect}" }.join(" "))

        case action
        when Action::DIRECTORY_CREATE then @driver.directory_create(path:)
        when Action::DIRECTORY_DELETE then @driver.directory_delete(path:)
        when Action::DIRECTORY_MOVE then @driver.directory_move(path:, destination:)
        when Action::DIRECTORY_LIST then @driver.directory_list(path:)
        when Action::FILE_CREATE then @driver.file_create(path:)
        when Action::FILE_DELETE then @driver.file_delete(path:)
        when Action::FILE_MOVE then @driver.file_move(path:, destination:)
        when Action::FILE_READ then @driver.file_read(path:)
        when Action::FILE_WRITE then @driver.file_write(path:, text:)
        when Action::FILE_REPLACE then @driver.file_replace(old_text:, new_text:, path:)
        end
      end
    end
  end
end
