# frozen_string_literal: true

require_relative "../../shared_tools"
require_relative "../process_registry"

module SharedTools
  module Tools
    # Stops a background process: SIGTERM to its process group, escalating
    # to SIGKILL if it doesn't exit, then returns any final output. Always
    # available, with no authorization prompt, so a runaway process can
    # always be stopped. Removes the process from the registry.
    #
    # @example
    #   tool = SharedTools::Tools::ProcessKillTool.new
    #   tool.execute(id: "proc_1")
    class ProcessKillTool < ::RubyLLM::Tool
      def self.name = 'process_kill'

      description "Stop a background process (started with process_start) and return any final " \
                  "output. Terminates the whole process group, escalating to SIGKILL if needed."

      params do
        string :id, description: "The process id to kill (e.g. 'proc_1')."
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param id [String]
      #
      # @return [String, Hash]
      def execute(id:)
        @logger.info("#{self.class.name}#execute id=#{id.inspect}")

        proc = SharedTools::ProcessRegistry.get(id)
        return { error: "no such process: #{id}" } unless proc

        was_running = proc.running?
        proc.kill
        final = proc.read_new
        SharedTools::ProcessRegistry.delete(id)

        body = +"#{id} #{was_running ? 'terminated' : 'was already exited'}"
        body << " (exit #{proc.exit_code})" if proc.exit_code
        unless final[:out].empty? && final[:err].empty?
          body << "\n--- final stdout ---\n#{final[:out]}" unless final[:out].empty?
          body << "\n--- final stderr ---\n#{final[:err]}" unless final[:err].empty?
        end
        body
      end
    end
  end
end
