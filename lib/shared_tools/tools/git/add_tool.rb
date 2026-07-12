# frozen_string_literal: true

require_relative "helpers"

module SharedTools
  module Tools
    module Git
      # Mutating. Stages changes in the repo at repo_root. Requires user
      # authorization (see SharedTools.execute?).
      #
      # @example
      #   tool = SharedTools::Tools::Git::AddTool.new
      #   tool.execute(paths: ["lib/foo.rb"])
      #   tool.execute(all: true)
      class AddTool < ::RubyLLM::Tool
        include Helpers

        def self.name = 'git_add'

        description "Stage changes in the repository. Pass specific paths, or set all to stage " \
                    "every change (git add -A)."

        params do
          array   :paths, of: :string, description: "Paths to stage, relative to the repo root.", required: false
          boolean :all,   description: "Stage all changes (git add -A) instead of specific paths. Default false.", required: false
        end

        # @param repo_root [String] optional, defaults to the current directory
        # @param logger [Logger] optional logger
        def initialize(repo_root: nil, logger: nil)
          @repo_root = repo_root || Dir.pwd
          @logger = logger || RubyLLM.logger
        end

        # @param paths [Array<String>, nil]
        # @param all [Boolean]
        #
        # @return [String, Hash]
        def execute(paths: nil, all: false)
          @logger.info("#{self.class.name}#execute paths=#{paths.inspect} all=#{all}")

          rels = Array(paths).filter_map { |p| repo_relative(p, repo_root: @repo_root) }

          if all
            args = ["add", "-A"]
          elsif rels.empty?
            return { error: "provide paths or set all: true" }
          else
            args = ["add", "--", *rels]
          end

          allowed = SharedTools.execute?(tool: self.class.to_s, stuff: args.join(" "))
          unless allowed
            @logger.warn("User declined to stage changes")
            return { error: "User declined to stage changes" }
          end

          out, err, status = run_git(*args, repo_root: @repo_root)
          result = git_result(out, err, status)
          return result if result.is_a?(Hash)

          all ? "Staged all changes" : "Staged: #{rels.join(', ')}"
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
