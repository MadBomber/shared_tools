# frozen_string_literal: true

require_relative "../../shared_tools"
require_relative "toolchain_helpers"

module SharedTools
  module Tools
    # Runs a Python project's tests (pytest or unittest) from root and
    # returns the output with a pass/fail headline. A failing suite is a
    # normal result, not a tool error. Runs in the project environment, so a
    # virtualenv/installed deps resolve as they would in a shell. Requires
    # user authorization (see SharedTools.execute?) since it executes an
    # external command.
    #
    # @example
    #   tool = SharedTools::Tools::PythonTestsTool.new(root: "./my-project")
    #   tool.execute
    #   tool.execute(path: "tests/test_models.py", framework: "unittest")
    class PythonTestsTool < ::RubyLLM::Tool
      include ToolchainHelpers

      FRAMEWORKS = %w[pytest unittest].freeze
      DEFAULT_TIMEOUT = 180

      def self.name = 'python_tests'

      description "Run a Python project's test suite from root and report results. Uses pytest by " \
                  "default, or unittest (python -m unittest discover) when framework is unittest. " \
                  "Optionally scope to a path."

      params do
        string :path,      description: "Limit the run to this test file or directory, relative to root. Optional.", required: false
        string :framework, description: "pytest (default) or unittest.", required: false
      end

      # @param root [String] optional, defaults to the current directory
      # @param logger [Logger] optional logger
      def initialize(root: nil, logger: nil)
        @root = root || Dir.pwd
        @logger = logger || RubyLLM.logger
      end

      # @param path [String, nil]
      # @param framework [String]
      #
      # @return [String, Hash]
      def execute(path: nil, framework: "pytest")
        @logger.info("#{self.class.name}#execute path=#{path.inspect} framework=#{framework}")

        fw = framework.to_s.strip.downcase
        fw = "pytest" if fw.empty?
        return { error: "unknown framework: #{fw} (use #{FRAMEWORKS.join(', ')})" } unless FRAMEWORKS.include?(fw)

        rel = jail_relative(path)

        allowed = SharedTools.execute?(tool: self.class.to_s, stuff: "Run #{fw} tests#{rel ? " (#{rel})" : ''}")
        unless allowed
          @logger.warn("User declined to run tests")
          return { error: "User declined to run tests" }
        end

        out, err, status = run_in_project(args_for(fw, rel), use_bundle: false, timeout: DEFAULT_TIMEOUT)
        toolchain_output(out, err, status,
                         pass_label: summarize(out, err, "TESTS PASSED"),
                         fail_label: summarize(out, err, "TESTS FAILED"),
                         timeout: DEFAULT_TIMEOUT)
      rescue SecurityError => e
        @logger.error("#{self.class.name} path denied: #{e.message}")
        { error: e.message }
      rescue CommandMissing => e
        @logger.error("#{self.class.name}: #{e.message} is not available")
        { error: "#{e.message} is not available (is it installed in the project env?)" }
      end

      private

      def args_for(framework, rel)
        if framework == "unittest"
          args = ["python3", "-m", "unittest", "discover"]
          args += ["-s", rel] if rel
        else
          args = ["pytest"]
          args << rel if rel
        end
        args
      end

      # Surface pytest's or unittest's summary in the headline.
      def summarize(out, err, label)
        text = "#{out}\n#{err}"
        counts = %w[passed failed error skipped].filter_map do |word|
          m = text.match(/(\d+) #{word}/)
          "#{m[1]} #{word}" if m
        end
        return "#{label} (#{counts.join(', ')})" unless counts.empty?

        if (m = text.match(/Ran (\d+) tests?.*?(OK|FAILED)/m))
          return "#{label} (ran #{m[1]}, #{m[2]})"
        end

        label
      end
    end
  end
end
