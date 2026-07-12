# frozen_string_literal: true

require_relative "helpers"

module SharedTools
  module Tools
    module Git
      # Read-only. Shows the working-tree status of the repo at repo_root
      # (current branch plus staged/unstaged/untracked changes).
      #
      # @example
      #   tool = SharedTools::Tools::Git::StatusTool.new
      #   tool.execute
      class StatusTool < ::RubyLLM::Tool
        include Helpers

        def self.name = 'git_status'

        description "Show the git working-tree status of the repository: current branch and " \
                    "staged, unstaged, and untracked changes. Read-only."

        # @param repo_root [String] optional, defaults to the current directory
        # @param logger [Logger] optional logger
        def initialize(repo_root: nil, logger: nil)
          @repo_root = repo_root || Dir.pwd
          @logger = logger || RubyLLM.logger
        end

        # @return [String, Hash]
        def execute
          @logger.info("#{self.class.name}#execute repo_root=#{@repo_root}")

          out, err, status = run_git("status", "--short", "--branch", repo_root: @repo_root)
          result = git_result(out, err, status)
          return result if result.is_a?(Hash)

          changes = result.each_line.reject { |line| line.start_with?("##") }
          changes.empty? ? "working tree clean" : result
        rescue => e
          @logger.error("#{self.class.name} failed: #{e.message}")
          { error: e.message }
        end
      end
    end
  end
end
