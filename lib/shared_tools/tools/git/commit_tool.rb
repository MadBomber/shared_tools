# frozen_string_literal: true

require_relative "helpers"

module SharedTools
  module Tools
    module Git
      # Mutating. Commits staged changes in the repo at repo_root with a
      # message. The message is passed as a single argv element (-m), so it
      # is never parsed by a shell. Requires user authorization (see
      # SharedTools.execute?). Does not push.
      #
      # @example
      #   tool = SharedTools::Tools::Git::CommitTool.new
      #   tool.execute(message: "Fix the thing")
      class CommitTool < ::RubyLLM::Tool
        include Helpers

        def self.name = 'git_commit'

        description "Commit staged changes in the repository with a message. Set all to also " \
                    "stage modified/deleted tracked files first (git commit -a). Does not push."

        params do
          string  :message, description: "Commit message."
          boolean :all,     description: "Stage modified/deleted tracked files before committing (git commit -a). Default false.", required: false
        end

        # @param repo_root [String] optional, defaults to the current directory
        # @param logger [Logger] optional logger
        def initialize(repo_root: nil, logger: nil)
          @repo_root = repo_root || Dir.pwd
          @logger = logger || RubyLLM.logger
        end

        # @param message [String]
        # @param all [Boolean]
        #
        # @return [String, Hash]
        def execute(message:, all: false)
          @logger.info("#{self.class.name}#execute all=#{all}")

          msg = message.to_s
          return { error: "commit message must not be empty" } if msg.strip.empty?

          args = ["commit"]
          args << "-a" if all
          args += ["-m", msg]

          allowed = SharedTools.execute?(tool: self.class.to_s, stuff: "git commit#{all ? ' -a' : ''} -m #{msg.inspect}")
          unless allowed
            @logger.warn("User declined to commit")
            return { error: "User declined to commit" }
          end

          out, err, status = run_git(*args, repo_root: @repo_root)
          result = git_result(out, err, status)
          if result.is_a?(Hash)
            combined = "#{out}\n#{err}"
            return { error: "nothing to commit (stage changes first)" } if combined.match?(/nothing to commit/i)

            return result
          end

          out.strip
        rescue => e
          @logger.error("#{self.class.name} failed: #{e.message}")
          { error: e.message }
        end
      end
    end
  end
end
