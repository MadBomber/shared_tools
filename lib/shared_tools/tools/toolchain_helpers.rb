# frozen_string_literal: true

require "pathname"
require_relative "../../shared_tools"
require_relative "../process_runner"

module SharedTools
  module Tools
    # Shared behavior for the Ruby toolchain tools (BundleTool, LintTool,
    # RunTestsTool, PythonTestsTool). Mixing tools must set @root in
    # #initialize.
    #
    # Unlike BashTool, these run in @root and inherit the full host
    # environment. That's deliberate: tools like bundler, rbenv/rvm, and the
    # test/lint binaries rely on the Ruby environment (PATH shims, GEM_HOME,
    # BUNDLE_*) to resolve correctly, and these are trusted dev commands the
    # caller opted into (they all require SharedTools.execute? authorization).
    module ToolchainHelpers
      class CommandMissing < StandardError; end

      def gemfile?
        File.file?(File.join(@root, "Gemfile"))
      end

      # Runs argv in @root. With use_bundle, prefixes `bundle exec` when a
      # Gemfile is present. Returns [out, err, status]; raises CommandMissing
      # if the executable can't be found.
      def run_in_project(argv, use_bundle: false, timeout: 120)
        command = use_bundle && gemfile? ? ["bundle", "exec", *argv] : argv
        SharedTools::ProcessRunner.capture(
          command,
          env: {}, # inherit the full host environment
          chdir: @root,
          timeout: timeout,
          unsetenv_others: false
        )
      rescue Errno::ENOENT
        raise CommandMissing, command.first
      end

      # Maps a finished toolchain run onto a return value. Non-zero exit is
      # NOT treated as a tool error here — failing tests / lint offenses are
      # results the caller needs to see, with a headline prepended.
      def toolchain_output(out, err, status, pass_label:, fail_label:, timeout:)
        return { error: "timed out after #{timeout}s" } if status == :timeout

        combined = [out, err].map(&:to_s).reject(&:empty?).join("\n")
        headline = status.exitstatus.zero? ? pass_label : fail_label
        "#{headline}\n\n#{combined}".strip
      end

      # Resolve a path param to a root-relative path, rejecting escapes.
      def jail_relative(path)
        return nil if path.nil? || path.to_s.empty?

        root = Pathname.new(File.expand_path(@root))
        resolved = (root + path).cleanpath
        raise SecurityError, "path escapes root: #{path}" unless resolved.ascend.any? { |ancestor| ancestor == root }

        resolved.relative_path_from(root).to_s
      end
    end
  end
end
