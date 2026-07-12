# frozen_string_literal: true

require_relative "../../shared_tools"
require_relative "../process_registry"

module SharedTools
  module Tools
    # Returns the output a background process has produced since the last
    # read, plus its current status (running, or exited with a code). Reads
    # are incremental, so polling in a loop streams the process's output
    # without repeats. Read-only.
    #
    # @example
    #   tool = SharedTools::Tools::ProcessOutputTool.new
    #   tool.execute(id: "proc_1")
    class ProcessOutputTool < ::RubyLLM::Tool
      def self.name = 'process_output'

      description "Read new stdout/stderr from a background process (started with process_start) " \
                  "since the last read, along with its status and exit code if it has finished. Poll " \
                  "this to follow a process's output."

      params do
        string :id, description: "The process id returned by process_start (e.g. 'proc_1')."
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

        data = proc.read_new
        format_output(proc, data)
      end

      private

      def format_output(proc, data)
        body = +"#{proc.id} (#{proc.name}): #{proc.status}"
        body << " (exit #{proc.exit_code})" if proc.status == :exited && proc.exit_code
        body << "\n"

        if data[:out].empty? && data[:err].empty?
          body << "(no new output)"
          return body
        end

        unless data[:out].empty?
          body << "\n--- stdout#{data[:out_dropped] ? ' (earlier output dropped)' : ''} ---\n"
          body << data[:out]
        end
        unless data[:err].empty?
          body << "\n--- stderr#{data[:err_dropped] ? ' (earlier output dropped)' : ''} ---\n"
          body << data[:err]
        end
        body
      end
    end
  end
end
