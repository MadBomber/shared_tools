# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  module Tools
    # Renders a depth-limited directory tree — a quick way to see project
    # structure without walking it one level at a time with
    # Disk::DirectoryListTool. Read-only; ignored directories are skipped,
    # symlinks are not followed, and the listing is capped.
    #
    # @example
    #   tool = SharedTools::Tools::TreeTool.new
    #   tool.execute
    #   tool.execute(path: "lib", max_depth: 2)
    class TreeTool < ::RubyLLM::Tool
      DEFAULT_DEPTH = 3
      MAX_ENTRIES = 500
      IGNORED_DIRS = %w[.git .hg .svn node_modules .bundle tmp].freeze

      def self.name = 'tree'

      description "Show a directory tree, to a limited depth. Directories are marked with a " \
                  "trailing slash. Skips ignored directories (node_modules, .git, ...) and hidden " \
                  "entries unless show_hidden is set."

      params do
        integer :max_depth,   description: "How many levels deep to descend (default #{DEFAULT_DEPTH}).", required: false
        string  :path,        description: "Directory to start from. Defaults to the current directory.", required: false
        boolean :show_hidden, description: "Include dot-files and dot-directories. Default false.", required: false
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param path [String, nil]
      # @param max_depth [Integer]
      # @param show_hidden [Boolean]
      #
      # @return [String, Hash]
      def execute(path: nil, max_depth: DEFAULT_DEPTH, show_hidden: false)
        @logger.info("#{self.class.name}#execute path=#{path.inspect} max_depth=#{max_depth} show_hidden=#{show_hidden}")

        root = File.expand_path(path.to_s.empty? ? "." : path)
        return { error: "not a directory: #{path || '.'}" } unless File.directory?(root)

        depth = max_depth.to_i
        depth = DEFAULT_DEPTH if depth <= 0

        @count = 0
        @truncated = false
        lines = ["#{File.basename(root)}/"]
        walk(root, depth, show_hidden, "", lines)
        lines << "... (truncated at #{MAX_ENTRIES} entries)" if @truncated

        lines.join("\n")
      rescue => e
        @logger.error("#{self.class.name} failed: #{e.message}")
        { error: e.message }
      end

      private

      def walk(dir, depth_left, show_hidden, indent, lines)
        return if depth_left <= 0 || @truncated

        entries = children(dir, show_hidden)
        entries.each_with_index do |entry, idx|
          if @count >= MAX_ENTRIES
            @truncated = true
            return
          end

          full = File.join(dir, entry)
          is_dir = File.directory?(full) && !File.symlink?(full)
          connector = idx == entries.length - 1 ? "└── " : "├── "
          lines << "#{indent}#{connector}#{entry}#{is_dir ? '/' : ''}"
          @count += 1

          next unless is_dir

          child_indent = indent + (idx == entries.length - 1 ? "    " : "│   ")
          walk(full, depth_left - 1, show_hidden, child_indent, lines)
        end
      end

      def children(dir, show_hidden)
        entries = Dir.children(dir)
        entries.reject! { |e| e.start_with?(".") } unless show_hidden
        entries.reject! { |e| File.directory?(File.join(dir, e)) && IGNORED_DIRS.include?(e) }
        # directories first, then files, each alphabetical
        entries.sort_by { |e| [File.directory?(File.join(dir, e)) ? 0 : 1, e.downcase] }
      rescue SystemCallError
        []
      end
    end
  end
end
