# frozen_string_literal: true

require_relative "../../shared_tools"
require_relative "toolchain_helpers"

module SharedTools
  module Tools
    # Runs Bundler operations in a project. The mutating sibling of the
    # read-only GemTool. install/update/add reach the network and change the
    # project's gems, so this requires user authorization (see
    # SharedTools.execute?).
    #
    # @example
    #   tool = SharedTools::Tools::BundleTool.new(root: "./my-project")
    #   tool.execute(action: "install")
    #   tool.execute(action: "add", gem: "rack")
    class BundleTool < ::RubyLLM::Tool
      include ToolchainHelpers

      ACTIONS = %w[install update outdated check lock add].freeze
      NAME_RE = /\A[A-Za-z0-9_.-]+\z/
      DEFAULT_TIMEOUT = 180

      def self.name = 'bundle'

      description "Run Bundler in a project. Actions: install, update, outdated, check, lock, add. " \
                  "For 'add' provide a gem name; for 'update' a gem name is optional (omit to update " \
                  "all). Requires a Gemfile."

      params do
        string :action, description: "One of: install, update, outdated, check, lock, add."
        string :gem,    description: "Gem name — required for 'add', optional for 'update'.", required: false
      end

      # @param root [String] optional, defaults to the current directory
      # @param logger [Logger] optional logger
      def initialize(root: nil, logger: nil)
        @root = root || Dir.pwd
        @logger = logger || RubyLLM.logger
      end

      # @param action [String]
      # @param gem [String, nil]
      #
      # @return [String, Hash]
      def execute(action:, gem: nil)
        @logger.info("#{self.class.name}#execute action=#{action} gem=#{gem.inspect}")

        act = action.to_s.strip.downcase
        return { error: "unknown action: #{act} (use #{ACTIONS.join(', ')})" } unless ACTIONS.include?(act)
        return { error: "a Gemfile is required (none at #{@root})" } unless gemfile?

        args = build_args(act, gem)
        return args if args.is_a?(Hash) # validation error

        allowed = SharedTools.execute?(tool: self.class.to_s, stuff: args.join(" "))
        unless allowed
          @logger.warn("User declined to run #{args.join(' ')}")
          return { error: "User declined to run #{args.join(' ')}" }
        end

        out, err, status = run_in_project(args, use_bundle: false, timeout: DEFAULT_TIMEOUT)
        toolchain_output(out, err, status,
                         pass_label: "bundle #{act}: ok",
                         fail_label: "bundle #{act}: failed",
                         timeout: DEFAULT_TIMEOUT)
      rescue CommandMissing
        @logger.error("#{self.class.name}: bundler is not available")
        { error: "bundler is not available (gem install bundler)" }
      end

      private

      def build_args(act, gem_name)
        case act
        when "add"
          name = gem_name.to_s.strip
          return { error: "'add' requires a valid gem name" } unless name.match?(NAME_RE)

          ["bundle", "add", name]
        when "update"
          name = gem_name.to_s.strip
          if name.empty?
            ["bundle", "update"]
          else
            return { error: "invalid gem name: #{name.inspect}" } unless name.match?(NAME_RE)

            ["bundle", "update", name]
          end
        else
          ["bundle", act]
        end
      end
    end
  end
end
