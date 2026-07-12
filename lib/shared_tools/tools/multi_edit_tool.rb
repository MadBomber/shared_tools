# frozen_string_literal: true

require 'pathname'
require_relative '../../shared_tools'

module SharedTools
  module Tools
    # Applies several string replacements to one file in a single, atomic
    # operation. Edits are applied in order (a later edit sees the result of
    # earlier ones); each edit's old_string must match exactly once unless
    # replace_all is set. If any edit can't be applied, nothing is written and
    # the failing edit is reported — so the file is never left half-edited.
    # Mutating — requires user authorization (see SharedTools.execute?).
    #
    # @example
    #   tool = SharedTools::Tools::MultiEditTool.new
    #   tool.execute(path: "./lib/foo.rb", edits: [
    #     { old_string: "def bar", new_string: "def baz" },
    #     { old_string: "BAR", new_string: "BAZ", replace_all: true }
    #   ])
    class MultiEditTool < ::RubyLLM::Tool
      class BadEdit < StandardError; end

      MAX_BYTES = 10 * 1024 * 1024

      def self.name = 'multi_edit'

      description "Apply multiple find/replace edits to a single file atomically. Provide edits as " \
                  "an array of objects with old_string, new_string, and optional replace_all. Edits " \
                  "run in order; if any fails to apply cleanly, no changes are written."

      params do
        string :path, description: "File to edit, relative to root."
        array  :edits, description: "Array of edits, applied in order." do
          object do
            string  :old_string,  description: "Exact text to replace. Include surrounding lines so it's unique."
            string  :new_string,  description: "Replacement text."
            boolean :replace_all, description: "Replace every occurrence instead of requiring a unique match. Default false.", required: false
          end
        end
      end

      # @param root [String] optional, defaults to the current directory
      # @param logger [Logger] optional logger
      def initialize(root: nil, logger: nil)
        @root = root || Dir.pwd
        @logger = logger || RubyLLM.logger
      end

      # @param path [String]
      # @param edits [Array<Hash>]
      #
      # @return [String, Hash]
      def execute(path:, edits:)
        @logger.info("#{self.class.name}#execute path=#{path.inspect} edits=#{Array(edits).size}")

        return { error: "edits must be a non-empty array" } unless edits.is_a?(Array) && !edits.empty?

        real = resolve!(path)
        return { error: "not a file: #{path}" } unless File.file?(real)
        return { error: "file too large (> #{MAX_BYTES} bytes)" } if File.size(real) > MAX_BYTES

        original = File.read(real).scrub
        content = original
        total = 0

        edits.each_with_index do |edit, i|
          content, n = apply_edit(content, edit, i + 1, path)
          total += n
        end

        allowed = SharedTools.execute?(tool: self.class.to_s, stuff: "Apply #{edits.size} edit(s) to #{path}")
        unless allowed
          @logger.warn("User declined to edit #{path}")
          return { error: "User declined to edit #{path}" }
        end

        File.write(real, content)
        "Applied #{edits.size} edit#{edits.size == 1 ? '' : 's'} to #{path} " \
          "(#{total} replacement#{total == 1 ? '' : 's'}, #{original.bytesize} -> #{content.bytesize} bytes)"
      rescue SecurityError => e
        @logger.error("#{self.class.name} path denied: #{e.message}")
        { error: e.message }
      rescue BadEdit => e
        @logger.error("#{self.class.name} bad edit: #{e.message}")
        { error: e.message }
      rescue => e
        @logger.error("#{self.class.name} failed: #{e.message}")
        { error: e.message }
      end

      private

      def apply_edit(content, edit, index, path)
        edit = normalize_edit(edit)
        old_s = edit["old_string"].to_s
        new_s = edit["new_string"].to_s
        replace_all = [true, "true"].include?(edit["replace_all"])

        raise BadEdit, "edit #{index}: old_string must not be empty" if old_s.empty?
        raise BadEdit, "edit #{index}: old_string and new_string are identical" if old_s == new_s

        if replace_all
          count = 0
          updated = content.gsub(old_s) { count += 1; new_s }
          raise BadEdit, "edit #{index}: old_string not found in #{path}" if count.zero?

          [updated, count]
        else
          count = content.scan(Regexp.new(Regexp.escape(old_s))).size
          raise BadEdit, "edit #{index}: old_string not found in #{path}" if count.zero?
          if count > 1
            raise BadEdit, "edit #{index}: old_string is ambiguous (#{count} matches in #{path}); " \
                           "add surrounding context or set replace_all"
          end

          [content.sub(old_s) { new_s }, 1]
        end
      end

      def normalize_edit(edit)
        edit.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
      end

      def resolve!(path)
        root = Pathname.new(File.expand_path(@root))
        resolved = (root + path).cleanpath
        raise SecurityError, "path escapes root: #{path}" unless resolved.ascend.any? { |ancestor| ancestor == root }

        resolved.to_s
      end
    end
  end
end
