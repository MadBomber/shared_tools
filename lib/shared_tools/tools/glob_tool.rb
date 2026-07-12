# frozen_string_literal: true

require 'pathname'
require_relative '../../shared_tools'

module SharedTools
  module Tools
    # Finds files matching a glob pattern within a directory and returns
    # their paths relative to the glob base, sorted. Each hit is re-checked
    # against the base so a symlinked match that points outside it is
    # dropped. Read-only, in-process — no authorization prompt required.
    #
    # @example
    #   tool = SharedTools::Tools::GlobTool.new
    #   tool.execute(pattern: "**/*.rb")
    #   tool.execute(pattern: "*.rb", base: "app/models")
    class GlobTool < ::RubyLLM::Tool
      MAX_RESULTS = 1_000

      def self.name = 'glob'

      description "Find files matching a glob pattern within a directory (e.g. '**/*.rb', " \
                  "'app/models/*.rb'). Returns matching paths, sorted, relative to base."

      params do
        string :pattern, description: "Glob pattern such as '**/*.rb', evaluated relative to base."
        string :base,    description: "Directory to glob from. Defaults to the current directory.", required: false
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param pattern [String]
      # @param base [String]
      #
      # @return [String, Hash]
      def execute(pattern:, base: ".")
        @logger.info("#{self.class.name}#execute pattern=#{pattern.inspect} base=#{base.inspect}")

        return { error: "pattern must be provided" } if pattern.to_s.empty?
        return { error: "pattern may not contain '..'" } if pattern.include?("..")

        return { error: "not a directory: #{base}" } unless File.directory?(File.expand_path(base))

        root = File.realpath(File.expand_path(base))

        base_pn = Pathname.new(root)
        results = Dir.glob(File.join(root, pattern), File::FNM_PATHNAME).sort.filter_map do |match|
          in_base?(root, match) ? Pathname.new(match).relative_path_from(base_pn).to_s : nil
        end

        capped = results.first(MAX_RESULTS)
        body = +"#{results.size} match#{results.size == 1 ? '' : 'es'}"
        body << " (showing first #{MAX_RESULTS})" if results.size > MAX_RESULTS
        body << " for #{pattern}:\n"
        capped.each { |rel| body << rel << "\n" }
        body
      rescue => e
        @logger.error("#{self.class.name} failed: #{e.message}")
        { error: e.message }
      end

      private

      def in_base?(root, match)
        real = File.realpath(match)
        (real == root || real.start_with?(root + File::SEPARATOR)) && File.exist?(match)
      rescue Errno::ENOENT
        false
      end
    end
  end
end
