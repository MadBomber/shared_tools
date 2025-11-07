# frozen_string_literal: true

require "open3"

module SharedTools
  module Tools
    module Docker
      # @example
      #   tool = SharedTools::Tools::Docker::ComposeRunTool.new
      #   tool.execute(service: "app", command: "rspec", args: ["spec/main_spec.rb"])
      class ComposeRunTool < ::RubyLLM::Tool
        def self.name = 'docker_compose_run'

        description "Runs a command via Docker with arguments on the project (e.g. `rspec spec/main_spec.rb`)."

        params do
          string :service, description: "The service to run the command on (e.g. `app`).", required: false
          string :command, description: "The command to run (e.g. `rspec`)."
          array :args, description: "The arguments for the command.", required: false
        end

        # @example
        #   class ExampleTool < ::RubyLLM::Tool
        #     # ...
        #   end
        class CaptureError < StandardError
          attr_accessor :text
          attr_accessor :status

          # @param text [String]
          # @param status [Process::Status]
          def initialize(text:, status:)
            super("[STATUS=#{status.exitstatus}] #{text}")
            @text = text
            @status = status
          end
        end

        # @param root [String, Pathname] optional, defaults to current directory
        # @param logger [Logger] optional logger
        def initialize(root: nil, logger: nil)
          @root = root || Dir.pwd
          @logger = logger || RubyLLM.logger
        end

        # @param service [String]
        # @param command [String]
        # @param args [Array<String>]
        #
        # @return [String]
        def execute(command:, service: "app", args: [])
          @logger.info(%(#{self.class.name}#execute service="#{service}" command="#{command}" args=#{args.inspect}))

          Dir.chdir(@root) do
            capture!("docker", "compose", "run", "--build", "--rm", service, command, *args)
          rescue CaptureError => e
            @logger.info("ERROR: #{e.message}")
            return "ERROR: #{e.message}"
          end
        end

      private

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
