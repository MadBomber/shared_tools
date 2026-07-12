# frozen_string_literal: true

require_relative "helpers"

module SharedTools
  module Tools
    module Git
      # Mutating. Switches branches or creates a new branch in the repo at
      # repo_root; can change the working tree. The ref is validated (no
      # leading dash, ref-safe characters only) so it can't smuggle git
      # options. Requires user authorization (see SharedTools.execute?).
      #
      # @example
      #   tool = SharedTools::Tools::Git::CheckoutTool.new
      #   tool.execute(ref: "main")
      #   tool.execute(ref: "feature/x", create: true)
      class CheckoutTool < ::RubyLLM::Tool
        include Helpers

        def self.name = 'git_checkout'

        description "Switch to a branch/commit in the repository, or create a new branch with " \
                    "create: true. Note this can change the working tree."

        params do
          string  :ref,    description: "Branch, tag, or commit to switch to (or the new branch name when create is true)."
          boolean :create, description: "Create a new branch named ref before switching to it (git checkout -b). Default false.", required: false
        end

        # @param repo_root [String] optional, defaults to the current directory
        # @param logger [Logger] optional logger
        def initialize(repo_root: nil, logger: nil)
          @repo_root = repo_root || Dir.pwd
          @logger = logger || RubyLLM.logger
        end

        # @param ref [String]
        # @param create [Boolean]
        #
        # @return [String, Hash]
        def execute(ref:, create: false)
          @logger.info("#{self.class.name}#execute ref=#{ref.inspect} create=#{create}")

          return { error: "invalid ref: #{ref.inspect}" } unless valid_ref?(ref)

          args = ["checkout"]
          args << "-b" if create
          args << ref

          allowed = SharedTools.execute?(tool: self.class.to_s, stuff: args.join(" "))
          unless allowed
            @logger.warn("User declined to checkout #{ref}")
            return { error: "User declined to checkout #{ref}" }
          end

          out, err, status = run_git(*args, repo_root: @repo_root)
          result = git_result(out, err, status)
          return result if result.is_a?(Hash)

          # git prints checkout feedback to stderr on success.
          [out, err].map(&:strip).reject(&:empty?).join("\n")
        rescue => e
          @logger.error("#{self.class.name} failed: #{e.message}")
          { error: e.message }
        end
      end
    end
  end
end
