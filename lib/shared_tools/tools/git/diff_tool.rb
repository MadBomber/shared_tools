# frozen_string_literal: true

require_relative "helpers"

module SharedTools
  module Tools
    module Git
      # Read-only. Shows a unified diff of the repo at repo_root. External
      # diff drivers and textconv filters are disabled so a malicious repo
      # can't turn a diff into command execution.
      #
      # @example
      #   tool = SharedTools::Tools::Git::DiffTool.new
      #   tool.execute
      #   tool.execute(staged: true, path: "lib/foo.rb")
      class DiffTool < ::RubyLLM::Tool
        include Helpers

        def self.name = 'git_diff'

        description "Show a unified git diff for the repository. By default shows unstaged " \
                    "changes; set staged to show what's staged. Optionally scope to a path or diff " \
                    "against a ref. Read-only."

        params do
          boolean :staged, description: "Show staged changes (git diff --cached) instead of unstaged. Default false.", required: false
          string  :path,   description: "Limit the diff to this path, relative to the repo root. Optional.", required: false
          string  :ref,    description: "Diff against this commit/branch/tag instead of the index. Optional.", required: false
        end

        # @param repo_root [String] optional, defaults to the current directory
        # @param logger [Logger] optional logger
        def initialize(repo_root: nil, logger: nil)
          @repo_root = repo_root || Dir.pwd
          @logger = logger || RubyLLM.logger
        end

        # @param staged [Boolean]
        # @param path [String, nil]
        # @param ref [String, nil]
        #
        # @return [String, Hash]
        def execute(staged: false, path: nil, ref: nil)
          @logger.info("#{self.class.name}#execute staged=#{staged} path=#{path.inspect} ref=#{ref.inspect}")

          return { error: "invalid ref: #{ref.inspect}" } if ref && !valid_ref?(ref)

          rel = repo_relative(path, repo_root: @repo_root)
          args = ["diff", "--no-ext-diff", "--no-textconv", "--stat", "--patch"]
          args << "--cached" if staged
          args << ref if ref
          args += ["--", rel] if rel

          out, err, status = run_git(*args, repo_root: @repo_root)
          result = git_result(out, err, status)
          return result if result.is_a?(Hash)

          result.strip.empty? ? "no changes" : result
        rescue SecurityError => e
          @logger.error("#{self.class.name} path denied: #{e.message}")
          { error: e.message }
        rescue => e
          @logger.error("#{self.class.name} failed: #{e.message}")
          { error: e.message }
        end
      end
    end
  end
end
