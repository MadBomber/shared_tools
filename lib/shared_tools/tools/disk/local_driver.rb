# frozen_string_literal: true

require_relative "base_driver"

module SharedTools
  module Tools
    module Disk
      # A driver for interacting with a disk via various operations
      class LocalDriver < BaseDriver
        # @raise [SecurityError]
        #
        # @param path [String]
        def directory_create(path:)
          FileUtils.mkdir_p(resolve!(path:))
        end

        # @param path [String]
        def directory_delete(path:)
          FileUtils.rmdir(resolve!(path:))
        end

        # @param path [String] optional
        def directory_list(path: ".")
          Dir.chdir(resolve!(path:)) do
            Dir.glob("**/*").map { |path| summarize(path:) }.join("\n")
          end
        end

        # @param path [String]
        # @param destination [String]
        def directory_move(path:, destination:)
          FileUtils.mv(resolve!(path:), resolve!(path: destination))
        end

        # @param path [String]
        def file_create(path:)
          path = resolve!(path:)
          FileUtils.touch(path) unless File.exist?(path)
        end

        # @param path [String]
        def file_delete(path:)
          File.delete(resolve!(path:))
        end

        # @param path [String]
        # @param destination [String]
        def file_move(path:, destination:)
          FileUtils.mv(resolve!(path:), resolve!(path: destination))
        end

        # @param path [String]
        #
        # @return [String]
        def file_read(path:)
          File.read(resolve!(path:))
        end

        # @param old_text [String]
        # @param new_text [String]
        # @param path [String]
        def file_replace(old_text:, new_text:, path:)
          path = resolve!(path:)
          contents = File.read(path)
          text = contents.gsub(old_text, new_text)
          File.write(path, text)
        end

        # @param path [String]
        # @param text [String]
        def file_write(path:, text:)
          File.write(resolve!(path:), text)
        end

      protected

        # @param path [String]
        #
        # @raise [SecurityError]
        #
        # @return Pathname
        def resolve!(path:)
          @root.join(path).tap do |resolved|
            relative = resolved.ascend.any? { |ancestor| ancestor.eql?(@root) }
            raise SecurityError, "unknown path=#{resolved}" unless relative
          end
        end
      end
    end
  end
end
