# frozen_string_literal: true

require_relative "helpers"

module SharedTools
  module Tools
    module Git
      # Read-only. Shows recent commit history for the repo at repo_root.
      #
      # @example
      #   tool = SharedTools::Tools::Git::LogTool.new
      #   tool.execute(count: 10)
      class LogTool < ::RubyLLM::Tool
        include Helpers

        DEFAULT_COUNT = 20
        MAX_COUNT     = 200
        FORMAT        = "%h %ad %an: %s"

        def self.name = 'git_log'

        description "Show recent git commit history for the repository (hash, date, author, " \
                    "subject). Optionally limit the count or scope to a path. Read-only."

        params do
          integer :count, description: "Number of commits to show (default #{DEFAULT_COUNT}, max #{MAX_COUNT}).", required: false
          string  :path,  description: "Limit history to commits touching this path, relative to the repo root. Optional.", required: false
        end

        # @param repo_root [String] optional, defaults to the current directory
        # @param logger [Logger] optional logger
        def initialize(repo_root: nil, logger: nil)
          @repo_root = repo_root || Dir.pwd
          @logger = logger || RubyLLM.logger
        end

        # @param count [Integer]
        # @param path [String, nil]
        #
        # @return [String, Hash]
        def execute(count: DEFAULT_COUNT, path: nil)
          @logger.info("#{self.class.name}#execute count=#{count} path=#{path.inspect}")

          n = count.to_i
          n = DEFAULT_COUNT if n <= 0
          n = MAX_COUNT if n > MAX_COUNT

          rel = repo_relative(path, repo_root: @repo_root)
          args = ["log", "--max-count=#{n}", "--date=short", "--pretty=format:#{FORMAT}"]
          args += ["--", rel] if rel

          out, err, status = run_git(*args, repo_root: @repo_root)
          result = git_result(out, err, status)
          if result.is_a?(Hash)
            return "no commits" if result[:error].to_s.match?(/does not have any commits yet|bad default revision/i)

            return result
          end

          result.strip.empty? ? "no commits" : result
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
