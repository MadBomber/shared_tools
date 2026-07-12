# frozen_string_literal: true

require_relative "helpers"

module SharedTools
  module Tools
    module Git
      # Read-only. Lists the branches of the repo at repo_root, with the
      # current branch marked and each branch's latest commit. Does not
      # create, switch, or delete branches (see Git::CheckoutTool).
      #
      # @example
      #   tool = SharedTools::Tools::Git::BranchTool.new
      #   tool.execute(all: true)
      class BranchTool < ::RubyLLM::Tool
        include Helpers

        def self.name = 'git_branch'

        description "List the branches of the repository, with the current branch marked (*) and " \
                    "each branch's tip commit. Set all true to include remote-tracking branches. Read-only."

        params do
          boolean :all, description: "Include remote-tracking branches. Default false (local only).", required: false
        end

        # @param repo_root [String] optional, defaults to the current directory
        # @param logger [Logger] optional logger
        def initialize(repo_root: nil, logger: nil)
          @repo_root = repo_root || Dir.pwd
          @logger = logger || RubyLLM.logger
        end

        # @param all [Boolean]
        #
        # @return [String, Hash]
        def execute(all: false)
          @logger.info("#{self.class.name}#execute all=#{all}")

          args = ["branch", "--no-color", "-vv"]
          args << "-a" if all

          out, err, status = run_git(*args, repo_root: @repo_root)
          result = git_result(out, err, status)
          return result if result.is_a?(Hash)

          result.strip.empty? ? "no branches yet (no commits?)" : result
        rescue => e
          @logger.error("#{self.class.name} failed: #{e.message}")
          { error: e.message }
        end
      end
    end
  end
end
