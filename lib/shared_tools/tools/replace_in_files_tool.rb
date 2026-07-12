# frozen_string_literal: true

require_relative "../../shared_tools"

module SharedTools
  module Tools
    # Find-and-replace across the files in root that match a glob. Literal
    # by default; set regex: true for a pattern (with backreferences in the
    # replacement). Binary files and ignored directories are skipped, the
    # pattern runs under a ReDoS timeout, and every path is confined to
    # root. Use dry_run: true to preview the impact without writing.
    # Mutating — requires user authorization (see SharedTools.execute?).
    #
    # @example
    #   tool = SharedTools::Tools::ReplaceInFilesTool.new(root: "./my-project")
    #   tool.execute(pattern: "FooBar", replacement: "BazQux", glob: "**/*.rb")
    #   tool.execute(pattern: "v(\\d+)\\.(\\d+)", replacement: 'v\1.\2-beta', regex: true, dry_run: true)
    class ReplaceInFilesTool < ::RubyLLM::Tool
      MAX_BYTES = 5 * 1024 * 1024
      MAX_LISTED = 100
      REGEX_TIMEOUT = 2
      IGNORED_DIRS = %w[.git .hg .svn node_modules .bundle tmp].freeze

      def self.name = 'replace_in_files'

      description "Replace occurrences of a pattern with a replacement across files in root " \
                  "matching a glob (default '**/*'). Literal by default; set regex true to use a " \
                  "regular expression (replacement may use \\1 backreferences). Set dry_run true to " \
                  "preview without writing. Skips binary files and ignored directories."

      params do
        string  :pattern,     description: "Text (or regex if regex=true) to find."
        string  :replacement, description: "Replacement text. With regex=true, \\1 etc. refer to capture groups.", required: false
        string  :glob,        description: "Glob of files to search, relative to root. Default '**/*'.", required: false
        boolean :regex,       description: "Treat pattern as a regular expression. Default false (literal).", required: false
        boolean :ignore_case, description: "Case-insensitive matching. Default false.", required: false
        boolean :dry_run,     description: "Report what would change without writing. Default false.", required: false
      end

      # @param root [String] optional, defaults to the current directory
      # @param logger [Logger] optional logger
      def initialize(root: nil, logger: nil)
        @root = root || Dir.pwd
        @logger = logger || RubyLLM.logger
      end

      # @param pattern [String]
      # @param replacement [String]
      # @param glob [String]
      # @param regex [Boolean]
      # @param ignore_case [Boolean]
      # @param dry_run [Boolean]
      #
      # @return [String, Hash]
      def execute(pattern:, replacement: "", glob: "**/*", regex: false, ignore_case: false, dry_run: false)
        @logger.info("#{self.class.name}#execute pattern=#{pattern.inspect} glob=#{glob.inspect} regex=#{regex} dry_run=#{dry_run}")

        return { error: "pattern must not be empty" } if pattern.to_s.empty?

        matcher = build_matcher(pattern, regex, ignore_case)
        root = File.realpath(@root)

        candidates = candidate_files(glob, root)
        preview = candidates.filter_map do |abs, rel|
          content = File.read(abs)
          next unless text?(content)

          count, = substitute(content, matcher, replacement.to_s, regex)
          [abs, rel, count] unless count.zero?
        end

        return format_summary([], 0, dry_run) if preview.empty?

        unless dry_run
          allowed = SharedTools.execute?(tool: self.class.to_s, stuff: "Replace #{preview.sum { |_, _, c| c }} occurrence(s) across #{preview.size} file(s)")
          unless allowed
            @logger.warn("User declined to replace in files")
            return { error: "User declined to replace in files" }
          end
        end

        changed = []
        total = 0
        preview.each do |abs, rel, _count|
          content = File.read(abs)
          count, updated = substitute(content, matcher, replacement.to_s, regex)
          next if count.zero?

          total += count
          changed << [rel, count]
          File.write(abs, updated) unless dry_run
        end

        format_summary(changed, total, dry_run)
      rescue Regexp::TimeoutError
        @logger.error("#{self.class.name}: regex timed out")
        { error: "pattern timed out (possible ReDoS); narrow the pattern" }
      rescue RegexpError => e
        @logger.error("#{self.class.name}: invalid regex: #{e.message}")
        { error: "invalid regular expression: #{e.message}" }
      end

      private

      def build_matcher(pattern, regex, ignore_case)
        flags = ignore_case ? Regexp::IGNORECASE : 0
        src = regex ? pattern.to_s : Regexp.escape(pattern.to_s)
        Regexp.new(src, flags, timeout: REGEX_TIMEOUT)
      end

      def candidate_files(glob, root)
        Dir.glob(File.join(root, glob)).filter_map do |abs|
          next unless File.file?(abs)

          real = begin
            File.realpath(abs)
          rescue StandardError
            next
          end
          next unless real == root || real.start_with?(root + File::SEPARATOR)

          rel = real.delete_prefix(root + File::SEPARATOR)
          next if ignored?(rel)
          next if File.size(real) > MAX_BYTES

          [real, rel]
        end
      end

      def ignored?(rel)
        parts = rel.split(File::SEPARATOR)
        IGNORED_DIRS.any? { |dir| parts.include?(dir) }
      end

      def text?(content)
        nul = 0.chr
        content.valid_encoding? && !content.include?(nul)
      end

      def substitute(content, matcher, replacement, regex)
        if regex
          count = content.scan(matcher).size
          return [0, content] if count.zero?

          [count, content.gsub(matcher, replacement)]
        else
          count = 0
          updated = content.gsub(matcher) { count += 1; replacement }
          return [0, content] if count.zero?

          [count, updated]
        end
      end

      def format_summary(changed, total, dry_run)
        verb = dry_run ? "Would replace" : "Replaced"
        return "#{verb} 0 occurrences (no matching files changed)." if changed.empty?

        header = "#{verb} #{total} occurrence#{total == 1 ? '' : 's'} across #{changed.size} file#{changed.size == 1 ? '' : 's'}#{dry_run ? ' (dry run)' : ''}:"
        lines = changed.first(MAX_LISTED).map { |rel, n| "  #{rel} (#{n})" }
        lines << "  ... and #{changed.size - MAX_LISTED} more" if changed.size > MAX_LISTED
        ([header] + lines).join("\n")
      end
    end
  end
end
