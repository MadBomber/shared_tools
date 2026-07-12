# frozen_string_literal: true

require_relative "helpers"

module SharedTools
  module Tools
    module Git
      # Read-only. Searches the repo's tracked files with `git grep` and
      # returns matching lines with file:line prefixes. Faster and cleaner
      # than a filesystem grep in a git repo because it only looks at
      # tracked content and skips binary files.
      #
      # @example
      #   tool = SharedTools::Tools::Git::GrepTool.new
      #   tool.execute(pattern: "def execute")
      class GrepTool < ::RubyLLM::Tool
        include Helpers

        def self.name = 'git_grep'

        description "Search the tracked files of the repository for a pattern using git grep, " \
                    "returning file:line: matches. Optionally restrict to a path, ignore case, or treat " \
                    "the pattern as a fixed string instead of a regex."

        params do
          string  :pattern,     description: "The pattern to search for (a basic regex unless fixed is true)."
          string  :path,        description: "Restrict the search to this file or directory, relative to the repo root. Optional.", required: false
          boolean :ignore_case, description: "Case-insensitive search. Default false.", required: false
          boolean :fixed,       description: "Treat the pattern as a literal string rather than a regex. Default false.", required: false
        end

        # @param repo_root [String] optional, defaults to the current directory
        # @param logger [Logger] optional logger
        def initialize(repo_root: nil, logger: nil)
          @repo_root = repo_root || Dir.pwd
          @logger = logger || RubyLLM.logger
        end

        # @param pattern [String]
        # @param path [String, nil]
        # @param ignore_case [Boolean]
        # @param fixed [Boolean]
        #
        # @return [String, Hash]
        def execute(pattern:, path: nil, ignore_case: false, fixed: false)
          @logger.info("#{self.class.name}#execute pattern=#{pattern.inspect} path=#{path.inspect}")

          pat = pattern.to_s
          return { error: "pattern must not be empty" } if pat.empty?

          rel = repo_relative(path, repo_root: @repo_root)
          args = ["grep", "-n", "-I", "--no-color"]
          args << "-i" if ignore_case
          args << "-F" if fixed
          args += ["-e", pat] # -e guards against a pattern that begins with "-"
          args += ["--", rel] if rel

          out, err, status = run_git(*args, repo_root: @repo_root)
          interpret(out, err, status)
        rescue SecurityError => e
          @logger.error("#{self.class.name} path denied: #{e.message}")
          { error: e.message }
        rescue => e
          @logger.error("#{self.class.name} failed: #{e.message}")
          { error: e.message }
        end

        private

        # git grep exits 1 (with no error output) when there are simply no
        # matches — that's a normal result, not a tool failure.
        def interpret(out, err, status)
          case status.exitstatus
          when 0 then out
          when 1 then err.to_s.strip.empty? ? "no matches" : { error: err.strip }
          else { error: err.to_s.strip.empty? ? out.to_s.strip : err.strip }
          end
        end
      end
    end
  end
end
