# frozen_string_literal: true

require "find"
require "pathname"

module SharedTools
  module Tools
    # Search file contents for a regular expression under a directory and
    # return "path:line: text" hits. Pure Ruby (no `rg`/`grep` dependency).
    # Read-only — no authorization prompt required.
    #
    # The pattern comes from an LLM, so two abuse vectors are guarded against:
    #   - ReDoS: the regex is compiled with a per-match timeout, so
    #     catastrophic backtracking can't hang the process.
    #   - Runaway scans: results are capped at max_results (default 50, max
    #     500), and the walk skips binary files, symlinks, oversized files,
    #     and common noise directories (.git, node_modules, tmp, ...).
    #
    # @example
    #   tool = SharedTools::Tools::SearchCodebaseTool.new
    #   tool.execute(pattern: "def execute")
    #   tool.execute(pattern: "RubyLLM", glob: "*.rb", max_results: 20)
    #   tool.execute(pattern: "TODO", context: 2) # 2 lines of context around each match
    class SearchCodebaseTool < ::RubyLLM::Tool
      MAX_RESULTS_CAP = 500
      DEFAULT_MAX_RESULTS = 50
      MAX_FILE_BYTES = 5 * 1024 * 1024
      MAX_CONTEXT = 50
      REGEX_TIMEOUT = 2
      IGNORED_DIRS = %w[.git .hg .svn node_modules .bundle tmp].freeze

      def self.name = 'search_codebase'

      description "Search file contents for a regular expression under a directory. Returns " \
                  "'path:line: text' for each match, or context blocks when context/before/after " \
                  "is set. Optionally restrict to files whose name matches a glob, and/or match " \
                  "case-insensitively. Results are capped, ReDoS-guarded, and require no external " \
                  "search binary."

      params do
        string  :pattern,     description: "Regular expression to search for."
        string  :path,        description: "Directory to search in (default: current directory)", required: false
        string  :glob,        description: "Only search files whose basename matches this glob, e.g. '*.rb'. Optional.", required: false
        boolean :ignore_case, description: "Case-insensitive match. Default false.", required: false
        integer :context,     description: "Lines of context to show before AND after each match (like grep -C). Optional.", required: false
        integer :before,      description: "Lines of context before each match (like grep -B). Overrides context. Optional.", required: false
        integer :after,       description: "Lines of context after each match (like grep -A). Overrides context. Optional.", required: false
        integer :max_results, description: "Maximum number of matches to return (default #{DEFAULT_MAX_RESULTS}, max #{MAX_RESULTS_CAP}).", required: false
      end

      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      def execute(pattern:, path: ".", glob: nil, ignore_case: false, context: nil, before: nil, after: nil, max_results: DEFAULT_MAX_RESULTS)
        @logger.info("SearchCodebaseTool#execute pattern=#{pattern.inspect} path=#{path} glob=#{glob.inspect}")

        return { error: "Search pattern cannot be empty" } if pattern.to_s.strip.empty?

        search_path = File.expand_path(path)
        return { error: "Path not found: #{path}" } unless File.exist?(search_path)
        return { error: "Not a directory: #{path}" } unless File.directory?(search_path)

        regex = build_regex(pattern, ignore_case)
        max = [[max_results.to_i, 1].max, MAX_RESULTS_CAP].min
        ctx_before = clamp_context(before.nil? ? context : before)
        ctx_after  = clamp_context(after.nil? ? context : after)

        matches, truncated =
          if ctx_before.zero? && ctx_after.zero?
            gather(search_path, regex, glob, max)
          else
            gather_with_context(search_path, regex, glob, ctx_before, ctx_after, max)
          end

        { matches: matches, count: matches.size, truncated: truncated, tool: "ruby" }
      rescue Regexp::TimeoutError
        @logger.error("SearchCodebaseTool regex timed out: #{pattern.inspect}")
        { error: "regex timed out (possible catastrophic backtracking); simplify the pattern" }
      rescue RegexpError => e
        @logger.error("SearchCodebaseTool invalid regex: #{e.message}")
        { error: "invalid regex: #{e.message}" }
      rescue => e
        @logger.error("SearchCodebaseTool error: #{e.message}")
        { error: e.message }
      end

      private

      def build_regex(pattern, ignore_case)
        options = ignore_case ? Regexp::IGNORECASE : 0
        Regexp.new(pattern.to_s, options, timeout: REGEX_TIMEOUT)
      end

      def clamp_context(value)
        n = value.to_i
        return 0 if n <= 0

        [n, MAX_CONTEXT].min
      end

      def gather(root, regex, glob, max)
        base = Pathname.new(root)
        matches = []
        truncated = false

        catch(:done) do
          walk(root, glob) do |file|
            scan(file, regex) do |lineno, text|
              rel = Pathname.new(file).relative_path_from(base).to_s
              matches << "#{rel}:#{lineno}: #{text.strip}"
              if matches.size >= max
                truncated = true
                throw :done
              end
            end
          end
        end

        [matches, truncated]
      end

      # Like gather, but expands each match with before/after context lines,
      # merges overlapping/adjacent ranges per file, and returns formatted
      # blocks. Match lines use "path:line: text"; context lines use
      # "path-line- text".
      def gather_with_context(root, regex, glob, ctx_before, ctx_after, max)
        base = Pathname.new(root)
        blocks = []
        total = 0
        truncated = false

        catch(:done) do
          walk(root, glob) do |file|
            next if binary?(file)

            lines = read_lines(file)
            next if lines.nil?

            match_idxs = []
            lines.each_with_index { |line, i| match_idxs << i if regex.match?(line) }
            next if match_idxs.empty?

            taken = match_idxs.first(max - total)
            truncated = true if taken.size < match_idxs.size
            match_set = {}
            taken.each { |i| match_set[i] = true }

            rel = Pathname.new(file).relative_path_from(base).to_s
            ranges = taken.map { |i| [[i - ctx_before, 0].max, [i + ctx_after, lines.size - 1].min] }
            merge_ranges(ranges).each do |lo, hi|
              block = (lo..hi).map do |i|
                sep = match_set[i] ? ":" : "-"
                "#{rel}#{sep}#{i + 1}#{sep} #{lines[i].to_s.strip}"
              end
              blocks << block.join("\n")
            end

            total += taken.size
            throw :done if total >= max
          end
        end

        [blocks, truncated]
      end

      def read_lines(file)
        File.readlines(file).map(&:scrub)
      rescue ArgumentError, SystemCallError
        nil
      end

      def merge_ranges(ranges)
        merged = []
        ranges.sort_by(&:first).each do |lo, hi|
          if !merged.empty? && lo <= merged.last[1] + 1
            merged.last[1] = [merged.last[1], hi].max
          else
            merged << [lo, hi]
          end
        end
        merged
      end

      def walk(root, glob)
        Find.find(root) do |entry|
          basename = File.basename(entry)

          if File.directory?(entry)
            Find.prune if IGNORED_DIRS.include?(basename)
            next
          end

          next if File.symlink?(entry)
          next if glob && !File.fnmatch?(glob, basename, File::FNM_PATHNAME)
          next unless File.file?(entry)
          next if File.size(entry) > MAX_FILE_BYTES

          yield entry
        end
      end

      def scan(file, regex)
        return if binary?(file)

        File.foreach(file).with_index(1) do |line, lineno|
          safe = line.scrub
          yield(lineno, safe) if regex.match?(safe)
        end
      rescue ArgumentError
        # Unreadable as text (encoding) — skip the file rather than fail.
        nil
      end

      def binary?(file)
        File.binread(file, 1024).to_s.include?(" ".b)
      rescue StandardError
        false
      end
    end
  end
end
