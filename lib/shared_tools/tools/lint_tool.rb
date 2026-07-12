# frozen_string_literal: true

require_relative "../../shared_tools"
require_relative "toolchain_helpers"

module SharedTools
  module Tools
    # Runs RuboCop or Standard over a project. Offenses are a normal result,
    # not a tool error. With autocorrect, the linter rewrites files in place,
    # so this requires user authorization (see SharedTools.execute?) even
    # without autocorrect, since it executes an external command.
    #
    # @example
    #   tool = SharedTools::Tools::LintTool.new(root: "./my-project")
    #   tool.execute
    #   tool.execute(path: "lib/foo.rb", autocorrect: true)
    class LintTool < ::RubyLLM::Tool
      include ToolchainHelpers

      LINTERS = %w[rubocop standard].freeze
      DEFAULT_TIMEOUT = 120

      def self.name = 'lint'

      description "Lint a project with RuboCop or Standard. Auto-detects (Standard if .standard.yml " \
                  "is present, else RuboCop) or set linter explicitly. Optionally scope to a path and " \
                  "apply safe autocorrections. Uses `bundle exec` when a Gemfile exists."

      params do
        string  :path,        description: "Limit linting to this path, relative to root. Optional.", required: false
        string  :linter,      description: "Force the linter: rubocop or standard. Default: auto-detect.", required: false
        boolean :autocorrect, description: "Apply safe autocorrections, rewriting files in place. Default false.", required: false
      end

      # @param root [String] optional, defaults to the current directory
      # @param logger [Logger] optional logger
      def initialize(root: nil, logger: nil)
        @root = root || Dir.pwd
        @logger = logger || RubyLLM.logger
      end

      # @param path [String, nil]
      # @param linter [String, nil]
      # @param autocorrect [Boolean]
      #
      # @return [String, Hash]
      def execute(path: nil, linter: nil, autocorrect: false)
        @logger.info("#{self.class.name}#execute path=#{path.inspect} linter=#{linter.inspect} autocorrect=#{autocorrect}")

        tool = (linter || detect_linter).to_s
        return { error: "unknown linter: #{tool} (use #{LINTERS.join(', ')})" } unless LINTERS.include?(tool)

        rel = jail_relative(path)

        allowed = SharedTools.execute?(tool: self.class.to_s, stuff: "Lint#{autocorrect ? ' with autocorrect' : ''}: #{tool}#{rel ? " #{rel}" : ''}")
        unless allowed
          @logger.warn("User declined to lint")
          return { error: "User declined to lint" }
        end

        out, err, status = run_in_project(build_args(tool, rel, autocorrect), use_bundle: true, timeout: DEFAULT_TIMEOUT)
        toolchain_output(out, err, status,
                         pass_label: "LINT CLEAN",
                         fail_label: autocorrect ? "LINT: offenses found (autocorrected where possible)" : "LINT: offenses found",
                         timeout: DEFAULT_TIMEOUT)
      rescue SecurityError => e
        @logger.error("#{self.class.name} path denied: #{e.message}")
        { error: e.message }
      rescue CommandMissing => e
        @logger.error("#{self.class.name}: #{e.message} is not available")
        { error: "#{e.message} is not available (is it in the bundle / installed?)" }
      end

      private

      def detect_linter
        File.exist?(File.join(@root, ".standard.yml")) ? "standard" : "rubocop"
      end

      def build_args(tool, rel, autocorrect)
        if tool == "standard"
          args = ["standardrb"]
          args << "--fix" if autocorrect
        else
          args = ["rubocop", "--no-color"]
          args << "--autocorrect" if autocorrect
        end
        args << rel if rel
        args
      end
    end
  end
end
