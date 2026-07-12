# frozen_string_literal: true

require_relative "helpers"

module SharedTools
  module Tools
    module Git
      # Read-only. Shows a commit (message + diff) or the contents of a file
      # at a given ref. External diff drivers and textconv are disabled.
      #
      # @example
      #   tool = SharedTools::Tools::Git::ShowTool.new
      #   tool.execute
      #   tool.execute(ref: "HEAD~1", path: "lib/foo.rb")
      class ShowTool < ::RubyLLM::Tool
        include Helpers

        def self.name = 'git_show'

        description "Show a git object in the repository. With no path, shows the commit at ref " \
                    "(message and diff). With a path, shows that file's contents as of ref. Defaults " \
                    "to HEAD. Read-only."

        params do
          string :ref,  description: "Commit/branch/tag to show. Default HEAD.", required: false
          string :path, description: "If given, show this file's contents at ref instead of the commit. Optional.", required: false
        end

        # @param repo_root [String] optional, defaults to the current directory
        # @param logger [Logger] optional logger
        def initialize(repo_root: nil, logger: nil)
          @repo_root = repo_root || Dir.pwd
          @logger = logger || RubyLLM.logger
        end

        # @param ref [String]
        # @param path [String, nil]
        #
        # @return [String, Hash]
        def execute(ref: "HEAD", path: nil)
          @logger.info("#{self.class.name}#execute ref=#{ref.inspect} path=#{path.inspect}")

          ref = ref.to_s.strip
          ref = "HEAD" if ref.empty?
          return { error: "invalid ref: #{ref.inspect}" } unless valid_ref?(ref)

          rel = repo_relative(path, repo_root: @repo_root)
          args = if rel
                   ["show", "#{ref}:#{rel}"]
                 else
                   ["show", "--no-ext-diff", "--no-textconv", "--stat", "--patch", ref]
                 end

          out, err, status = run_git(*args, repo_root: @repo_root)
          git_result(out, err, status)
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
