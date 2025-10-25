# frozen_string_literal: true

require "open3"

module SharedTools
  module Tools
    module Docker
      # @example
      #   class ExampleTool s::Disk::BaseTool
      #     description "..."
      #   end
      class BaseTool 
        # @example
        #   raise CaptureError.new(text: "an unknown error occurred", status: Process::Status.new(0))
        class CaptureError < StandardError
          # !@attribute [rw] text
          #   @return [String]
          attr_accessor :text

          # @!attribute [rw] status
          #   @return [Process::Status]
          attr_accessor :status

          # @param text [String]
          # @param status [Process::Status]
          def initialize(text:, status:)
            super("[STATUS=#{status.exitstatus}] #{text}")
            @text = text
            @status = status
          end
        end

        # @param root [Pathname]
        # @param logger [IO] optional
        def initialize(root:, logger: Logger.new(IO::NULL))
          super()
          @root = root
          @logger = logger
        end

      protected

        # @raise [CaptureError]
        #
        # @return [String]
        def capture!(...)
          text, status = Open3.capture2e(...)

          raise CaptureError.new(text:, status:) unless status.success?

          text
        end
      end
    end
  end
end
