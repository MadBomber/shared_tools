# frozen_string_literal: true

require_relative "../../shared_tools"
require_relative "toolchain_helpers"

module SharedTools
  module Tools
    # Runs a Ruby project's test suite (RSpec or Minitest) from root and
    # returns the output with a pass/fail headline. A failing suite is a
    # normal result (the caller needs to see it), not a tool error. Requires
    # user authorization (see SharedTools.execute?) since it executes an
    # external command.
    #
    # @example
    #   tool = SharedTools::Tools::RunTestsTool.new(root: "./my-project")
    #   tool.execute
    #   tool.execute(path: "spec/models/user_spec.rb")
    class RunTestsTool < ::RubyLLM::Tool
      include ToolchainHelpers

      FRAMEWORKS = %w[rspec minitest].freeze
      DEFAULT_TIMEOUT = 180

      def self.name = 'run_tests'

      description "Run a Ruby project's test suite from root and report results. Auto-detects RSpec " \
                  "(spec/ or .rspec) or Minitest (test/ via rake), or set framework explicitly. " \
                  "Optionally scope to a path. Uses `bundle exec` when a Gemfile exists."

      params do
        string :path,      description: "Limit the run to this spec/test file or directory, relative to root. Optional.", required: false
        string :framework, description: "Force the framework: rspec or minitest. Default: auto-detect.", required: false
      end

      # @param root [String] optional, defaults to the current directory
      # @param logger [Logger] optional logger
      def initialize(root: nil, logger: nil)
        @root = root || Dir.pwd
        @logger = logger || RubyLLM.logger
      end

      # @param path [String, nil]
      # @param framework [String, nil]
      #
      # @return [String, Hash]
      def execute(path: nil, framework: nil)
        @logger.info("#{self.class.name}#execute path=#{path.inspect} framework=#{framework.inspect}")

        fw = (framework || detect_framework).to_s
        return { error: "could not detect a test framework (no spec/ or test/); set framework" } if fw.empty?
        return { error: "unknown framework: #{fw} (use #{FRAMEWORKS.join(', ')})" } unless FRAMEWORKS.include?(fw)

        rel = jail_relative(path)

        allowed = SharedTools.execute?(tool: self.class.to_s, stuff: "Run #{fw} tests#{rel ? " (#{rel})" : ''}")
        unless allowed
          @logger.warn("User declined to run tests")
          return { error: "User declined to run tests" }
        end

        out, err, status = fw == "rspec" ? run_rspec(rel) : run_minitest(rel)
        toolchain_output(out, err, status,
                         pass_label: summarize(out, err, "TESTS PASSED"),
                         fail_label: summarize(out, err, "TESTS FAILED"),
                         timeout: DEFAULT_TIMEOUT)
      rescue SecurityError => e
        @logger.error("#{self.class.name} path denied: #{e.message}")
        { error: e.message }
      rescue CommandMissing => e
        @logger.error("#{self.class.name}: #{e.message} is not available")
        { error: "#{e.message} is not available (is it in the bundle / installed?)" }
      end

      private

      def detect_framework
        return "rspec" if File.directory?(File.join(@root, "spec")) || File.exist?(File.join(@root, ".rspec"))
        return "minitest" if File.directory?(File.join(@root, "test"))

        ""
      end

      def run_rspec(rel)
        args = ["rspec"]
        args << rel if rel
        run_in_project(args, use_bundle: true, timeout: DEFAULT_TIMEOUT)
      end

      def run_minitest(rel)
        args = ["rake", "test"]
        args << "TEST=#{rel}" if rel
        run_in_project(args, use_bundle: true, timeout: DEFAULT_TIMEOUT)
      end

      # Pull the framework's summary line into the headline when present.
      def summarize(out, err, label)
        text = "#{out}\n#{err}"
        if (m = text.match(/(\d+) examples?, (\d+) failures?(?:, (\d+) errors?)?/))
          "#{label} (#{m[0]})"
        elsif (m = text.match(/(\d+) runs?, \d+ assertions?, (\d+) failures?, (\d+) errors?/))
          "#{label} (#{m[0]})"
        else
          label
        end
      end
    end
  end
end
