# frozen_string_literal: true

require "open3"
require "pathname"

module SharedTools
  module Tools
    module Git
      # Shared behavior for the git tools: running git the same hardened way,
      # and mapping its output onto the shared_tools { error: } contract.
      #
      # Hardening matters because git executes commands configured *by the
      # repository* in several places, which turns "read-only" commands into
      # arbitrary code execution when operating on an untrusted checkout:
      #   - core.fsmonitor runs a command during `git status`
      #   - diff.external / textconv run commands during `git diff`
      # core.fsmonitor is disabled via `-c`, and the diff/show tools pass
      # --no-ext-diff --no-textconv. The pager and credential prompts are
      # also disabled so a call can never hang waiting on a TTY.
      module Helpers
        GIT_ENV = { "GIT_PAGER" => "cat", "GIT_TERMINAL_PROMPT" => "0" }.freeze
        # A ref/branch the model supplies: no leading dash (option injection),
        # and only the characters git refs legitimately use.
        REF_RE = %r{\A[A-Za-z0-9][\w./\-]*\z}

        # @param args [Array<String>]
        # @param repo_root [String]
        # @return [Array(String, String, Process::Status)] stdout, stderr, status
        def run_git(*args, repo_root:)
          Open3.capture3(GIT_ENV, "git", "-c", "core.fsmonitor=", "-C", repo_root.to_s, "--no-pager", *args)
        end

        # Maps a finished git run onto the shared_tools return contract.
        #
        # @return [String, Hash] stdout on success, or an { error:, code: } hash
        def git_result(out, err, status)
          return out if status.success?

          message = (err.to_s.empty? ? out.to_s : err.to_s).strip
          code = message.match?(/not a git repository/i) ? :not_a_repo : :git_error
          { error: message.empty? ? "git failed with exit code #{status.exitstatus}" : "git failed: #{message}", code: code }
        end

        # @param ref [String]
        # @return [Boolean]
        def valid_ref?(ref)
          ref.to_s.match?(REF_RE)
        end

        # Resolve a path param to a repo-relative path, rejecting jail escapes.
        # Returns nil for a blank path.
        #
        # @param path [String, nil]
        # @param repo_root [String]
        #
        # @raise [SecurityError] if the path escapes repo_root
        # @return [String, nil]
        def repo_relative(path, repo_root:)
          return nil if path.nil? || path.to_s.strip.empty?

          root = Pathname.new(File.expand_path(repo_root))
          resolved = (root + path).cleanpath
          raise SecurityError, "path escapes repo_root: #{path}" unless resolved.ascend.any? { |ancestor| ancestor == root }

          resolved.relative_path_from(root).to_s
        end
      end
    end
  end
end
