# frozen_string_literal: true

require 'open3'
require 'pathname'
require_relative '../../shared_tools'

module SharedTools
  module Tools
    # Applies a unified diff to files under root using `git apply`. Complements
    # MultiEditTool when the caller wants to emit a whole multi-hunk patch
    # (e.g. straight out of Git::DiffTool or DiffTool). The patch is validated
    # with `git apply --check` before anything is written, and every touched
    # path is confined to root — a patch cannot escape root even when root is
    # a subdirectory of a larger git repo. Works with or without root being a
    # git repository; requires git to be installed. Mutating — requires user
    # authorization (see SharedTools.execute?).
    #
    # @example
    #   tool = SharedTools::Tools::ApplyPatchTool.new
    #   tool.execute(patch: unified_diff_text)
    #   tool.execute(patch: unified_diff_text, check: true) # dry run
    class ApplyPatchTool < ::RubyLLM::Tool
      GIT_ENV = { "GIT_PAGER" => "cat", "GIT_TERMINAL_PROMPT" => "0" }.freeze

      def self.name = 'apply_patch'

      description "Apply a unified diff to files under root (as produced by `git diff` / `diff -u`). " \
                  "Validates the patch first and reports the affected files; nothing is written if it " \
                  "would not apply cleanly. Set check: true for a dry run only. Requires git to be " \
                  "installed; root does not need to be a git repository."

      params do
        string  :patch, description: "The unified diff text to apply."
        boolean :check, description: "Validate only (dry run); do not write changes. Default false.", required: false
      end

      # @param root [String] optional, defaults to the current directory
      # @param logger [Logger] optional logger
      def initialize(root: nil, logger: nil)
        @root = root || Dir.pwd
        @logger = logger || RubyLLM.logger
      end

      # @param patch [String]
      # @param check [Boolean]
      #
      # @return [String, Hash]
      def execute(patch:, check: false)
        @logger.info("#{self.class.name}#execute check=#{check}")

        diff = patch.to_s
        diff += "\n" unless diff.end_with?("\n")
        return { error: "patch is empty" } if diff.strip.empty?

        validate_patch_paths!(diff)

        verify = run_git_apply("--check", stdin: diff)
        return { error: "patch does not apply cleanly: #{message(verify)}" } unless succeeded?(verify)

        files = changed_files(diff)
        return "Patch applies cleanly (dry run). Affected files: #{files.join(', ')}" if check

        allowed = SharedTools.execute?(tool: self.class.to_s, stuff: "Apply patch affecting #{files.size} file(s): #{files.join(', ')}")
        unless allowed
          @logger.warn("User declined to apply the patch")
          return { error: "User declined to apply the patch" }
        end

        result = run_git_apply(stdin: diff)
        return { error: "apply failed: #{message(result)}" } unless succeeded?(result)

        "Applied patch to #{files.size} file#{files.size == 1 ? '' : 's'}: #{files.join(', ')}"
      rescue SecurityError => e
        @logger.error("#{self.class.name} path denied: #{e.message}")
        { error: "patch path escapes root: #{e.message}" }
      rescue Errno::ENOENT
        @logger.error("#{self.class.name}: git is not available")
        { error: "git is not available on the host" }
      end

      private

      def run_git_apply(*args, stdin:)
        Open3.capture3(GIT_ENV, "git", "-C", @root.to_s, "apply", *args, stdin_data: stdin)
      end

      def succeeded?((_out, _err, status))
        status.exitstatus&.zero?
      end

      def message((out, err, _status))
        (err.to_s.empty? ? out.to_s : err.to_s).strip
      end

      def validate_patch_paths!(diff)
        root = Pathname.new(File.expand_path(@root))
        diff.each_line do |line|
          if line.start_with?("+++ ")
            check_patch_path!(line[4..].chomp.sub(%r{\Ab/}, ""), root)
          elsif line.start_with?("--- ")
            check_patch_path!(line[4..].chomp.sub(%r{\Aa/}, ""), root)
          end
        end
      end

      def check_patch_path!(path, root)
        return if path.empty? || path == "/dev/null"

        resolved = (root + path).cleanpath
        raise SecurityError, path unless resolved.ascend.any? { |ancestor| ancestor == root }
      end

      def changed_files(diff)
        out, = run_git_apply("--numstat", stdin: diff)
        out.to_s.each_line.filter_map do |line|
          parts = line.strip.split("\t")
          parts.last if parts.size >= 3
        end
      end
    end
  end
end
