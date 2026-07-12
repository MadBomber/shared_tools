# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  module Tools
    # A tool for interacting with a git repository: status, diff, log, show,
    # blame, branch, grep, add, commit, and checkout. Mutating actions (add,
    # commit, checkout) require user authorization (see SharedTools.execute?).
    #
    # @example
    #   git = SharedTools::Tools::GitTool.new
    #   git.execute(action: SharedTools::Tools::GitTool::Action::STATUS)
    #   git.execute(action: SharedTools::Tools::GitTool::Action::LOG, count: 5)
    #   git.execute(action: SharedTools::Tools::GitTool::Action::COMMIT, message: "Fix the thing")
    class GitTool < ::RubyLLM::Tool
      def self.name = 'git_tool'

      description <<~TEXT
        A tool for interacting with a git repository. Read-only actions (status, diff, log, show,
        blame, branch, grep) require no authorization. Mutating actions (add, commit, checkout)
        require user authorization.
      TEXT

      module Action
        STATUS   = "status"
        DIFF     = "diff"
        LOG      = "log"
        SHOW     = "show"
        BLAME    = "blame"
        BRANCH   = "branch"
        GREP     = "grep"
        ADD      = "add"
        COMMIT   = "commit"
        CHECKOUT = "checkout"
      end

      ACTIONS = [
        Action::STATUS,
        Action::DIFF,
        Action::LOG,
        Action::SHOW,
        Action::BLAME,
        Action::BRANCH,
        Action::GREP,
        Action::ADD,
        Action::COMMIT,
        Action::CHECKOUT,
      ].freeze

      params do
        string  :action,      description: "The git operation to perform. One of: #{ACTIONS.join(', ')}"
        boolean :staged,      description: "For `#{Action::DIFF}`: show staged changes instead of unstaged.", required: false
        string  :path,        description: "A file or directory path, relative to the repo root. Used by #{Action::DIFF}, #{Action::LOG}, #{Action::SHOW}, #{Action::BLAME}, #{Action::GREP}.", required: false
        string  :ref,         description: "A commit/branch/tag. Used by #{Action::DIFF}, #{Action::SHOW}, #{Action::CHECKOUT}.", required: false
        integer :count,       description: "For `#{Action::LOG}`: number of commits to show.", required: false
        integer :start_line,  description: "For `#{Action::BLAME}`: first line of the range.", required: false
        integer :end_line,    description: "For `#{Action::BLAME}`: last line of the range.", required: false
        boolean :all,         description: "For `#{Action::BRANCH}`: include remote-tracking branches. For `#{Action::ADD}`: stage all changes. For `#{Action::COMMIT}`: stage tracked files first.", required: false
        string  :pattern,     description: "For `#{Action::GREP}`: the pattern to search for.", required: false
        boolean :ignore_case, description: "For `#{Action::GREP}`: case-insensitive search.", required: false
        boolean :fixed,       description: "For `#{Action::GREP}`: treat pattern as a literal string.", required: false
        array   :paths,       of: :string, description: "For `#{Action::ADD}`: paths to stage.", required: false
        string  :message,     description: "For `#{Action::COMMIT}`: the commit message.", required: false
        boolean :create,      description: "For `#{Action::CHECKOUT}`: create ref as a new branch.", required: false
      end

      # @param repo_root [String] optional, defaults to the current directory
      # @param logger [Logger] optional logger
      def initialize(repo_root: nil, logger: nil)
        @repo_root = repo_root || Dir.pwd
        @logger = logger || RubyLLM.logger
      end

      # @return [String, Hash]
      def execute(action:, **opts)
        @logger.info("GitTool#execute action=#{action}")

        case action.to_s.downcase
        when Action::STATUS   then status_tool.execute
        when Action::DIFF     then diff_tool.execute(staged: opts[:staged] || false, path: opts[:path], ref: opts[:ref])
        when Action::LOG      then log_tool.execute(count: opts[:count] || Git::LogTool::DEFAULT_COUNT, path: opts[:path])
        when Action::SHOW     then show_tool.execute(ref: opts[:ref] || "HEAD", path: opts[:path])
        when Action::BLAME    then require_param!(:path, opts[:path]) && blame_tool.execute(path: opts[:path], start_line: opts[:start_line], end_line: opts[:end_line])
        when Action::BRANCH   then branch_tool.execute(all: opts[:all] || false)
        when Action::GREP     then require_param!(:pattern, opts[:pattern]) && grep_tool.execute(pattern: opts[:pattern], path: opts[:path], ignore_case: opts[:ignore_case] || false, fixed: opts[:fixed] || false)
        when Action::ADD      then add_tool.execute(paths: opts[:paths], all: opts[:all] || false)
        when Action::COMMIT   then require_param!(:message, opts[:message]) && commit_tool.execute(message: opts[:message], all: opts[:all] || false)
        when Action::CHECKOUT then require_param!(:ref, opts[:ref]) && checkout_tool.execute(ref: opts[:ref], create: opts[:create] || false)
        else
          { error: "Unsupported action: #{action}. Supported actions are: #{ACTIONS.join(', ')}" }
        end
      rescue StandardError => e
        @logger.error("GitTool execution failed: #{e.message}")
        { error: e.message }
      end

      private

      # @raise [ArgumentError]
      def require_param!(name, value)
        raise ArgumentError, "#{name} param is required for this action" if value.nil?

        true
      end

      def status_tool
        @status_tool ||= Git::StatusTool.new(repo_root: @repo_root, logger: @logger)
      end

      def diff_tool
        @diff_tool ||= Git::DiffTool.new(repo_root: @repo_root, logger: @logger)
      end

      def log_tool
        @log_tool ||= Git::LogTool.new(repo_root: @repo_root, logger: @logger)
      end

      def show_tool
        @show_tool ||= Git::ShowTool.new(repo_root: @repo_root, logger: @logger)
      end

      def blame_tool
        @blame_tool ||= Git::BlameTool.new(repo_root: @repo_root, logger: @logger)
      end

      def branch_tool
        @branch_tool ||= Git::BranchTool.new(repo_root: @repo_root, logger: @logger)
      end

      def grep_tool
        @grep_tool ||= Git::GrepTool.new(repo_root: @repo_root, logger: @logger)
      end

      def add_tool
        @add_tool ||= Git::AddTool.new(repo_root: @repo_root, logger: @logger)
      end

      def commit_tool
        @commit_tool ||= Git::CommitTool.new(repo_root: @repo_root, logger: @logger)
      end

      def checkout_tool
        @checkout_tool ||= Git::CheckoutTool.new(repo_root: @repo_root, logger: @logger)
      end
    end
  end
end
