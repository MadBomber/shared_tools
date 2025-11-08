# frozen_string_literal: true

require "pathname"

module SharedTools
  module Tools
    module Disk
      # A driver for interacting with a disk via various operations
      class BaseDriver
        # @param root [String]
        def initialize(root:)
          @root = Pathname(root)
        end

        # @param path [String]
        def directory_create(path:)
          raise NotImplementedError, "#{self.class}#{__method__} undefined"
        end

        # @param path [String]
        def directroy_delete(path:)
          raise NotImplementedError, "#{self.class}#{__method__} undefined"
        end

        # @param path [String]
        # @param destination [String]
        def directory_move(path:, destination:)
          raise NotImplementedError, "#{self.class}#{__method__} undefined"
        end

        # @param path [String]
        def file_create(path:)
          raise NotImplementedError, "#{self.class}#{__method__} undefined"
        end

        # @param path [String]
        def file_delete(path:)
          raise NotImplementedError, "#{self.class}#{__method__} undefined"
        end

        # @param path [String]
        # @param destination [String]
        def file_move(path:, destination:)
          raise NotImplementedError, "#{self.class}#{__method__} undefined"
        end

        # @param path [String]
        # @return [String]
        def file_read(path:)
          raise NotImplementedError, "#{self.class}#{__method__} undefined"
        end

        # @param old_text [String]
        # @param new_text [String]
        # @param path [String]
        def file_replace(old_text:, new_text:, path:)
          raise NotImplementedError, "#{self.class}#{__method__} undefined"
        end

        # @param path [String]
        # @param text [String]
        def file_write(path:, text:)
          raise NotImplementedError, "#{self.class}#{__method__} undefined"
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

        # @param path [String]
        def summarize(path:)
          if File.directory?(path)
            "📁 ./#{path}/"
          else
            "📄 ./#{path} (#{File.size(path)} bytes)"
          end
        end
      end
    end
  end
end
