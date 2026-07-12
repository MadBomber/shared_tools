# frozen_string_literal: true

require_relative "../../shared_tools"
require_relative "../process_registry"

module SharedTools
  module Tools
    # Lists the background processes started this run (with ProcessStartTool):
    # id, status, pid, age, and command — so a caller can rediscover ids and
    # see what's still running. Read-only.
    #
    # @example
    #   tool = SharedTools::Tools::ProcessListTool.new
    #   tool.execute
    class ProcessListTool < ::RubyLLM::Tool
      def self.name = 'process_list'

      description "List background processes (started with process_start): id, status, pid, age, and " \
                  "command. Read-only."

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @return [String]
      def execute
        @logger.info("#{self.class.name}#execute")

        procs = SharedTools::ProcessRegistry.all
        return "no background processes" if procs.empty?

        lines = procs.map do |proc|
          status = proc.status == :exited ? "exited(#{proc.exit_code})" : "running"
          "#{proc.id}  #{status.ljust(12)}  pid=#{proc.pid}  age=#{proc.age.round}s  #{proc.name}  #{proc.argv.inspect}"
        end
        (["#{procs.size} process#{procs.size == 1 ? '' : 'es'}:"] + lines).join("\n")
      end
    end
  end
end
