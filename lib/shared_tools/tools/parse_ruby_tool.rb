# frozen_string_literal: true

require "pathname"
require_relative "../../shared_tools"
require_relative "../ruby_outline"

module SharedTools
  module Tools
    # Produces a structural outline of a Ruby file (classes, modules,
    # methods, constants) with line numbers, or finds where a name is
    # defined. In-process via Ripper/Prism — it parses, never executes, the
    # code. Read-only.
    #
    # @example
    #   tool = SharedTools::Tools::ParseRubyTool.new
    #   tool.execute(path: "./lib/foo.rb")
    #   tool.execute(path: "./lib/foo.rb", query: "initialize")
    #   tool.execute(path: "./lib/foo.rb", kind: "method")
    class ParseRubyTool < ::RubyLLM::Tool
      KINDS = %w[class module method constant].freeze
      MAX_BYTES = 5 * 1024 * 1024

      def self.name = 'parse_ruby'

      description "Outline a Ruby file's structure (classes, modules, methods, constants with line " \
                  "numbers), or locate definitions. Give a query to find definitions whose name " \
                  "matches, and/or a kind to filter. Parses in-process; does not run the code."

      params do
        string :path,  description: "Ruby file to outline."
        string :query, description: "Only show definitions whose (qualified) name matches this, case-insensitive. Optional.", required: false
        string :kind,  description: "Filter to a kind: class, module, method, or constant. Optional.", required: false
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param path [String]
      # @param query [String, nil]
      # @param kind [String, nil]
      #
      # @return [String, Hash]
      def execute(path:, query: nil, kind: nil)
        @logger.info("#{self.class.name}#execute path=#{path.inspect} query=#{query.inspect} kind=#{kind.inspect}")

        k = kind.to_s.strip.downcase
        k = nil if k.empty?
        return { error: "unknown kind: #{k} (use #{KINDS.join(', ')})" } if k && !KINDS.include?(k)

        return { error: "file not found: #{path}" } unless File.exist?(path)
        return { error: "not a file: #{path}" } unless File.file?(path)
        return { error: "file too large (> #{MAX_BYTES} bytes)" } if File.size(path) > MAX_BYTES

        entries = SharedTools::RubyOutline.extract(File.read(path).scrub)
        return "no definitions found in #{path}" if entries.empty?

        render(entries, path, query, k)
      rescue SharedTools::RubyOutline::ParseError => e
        @logger.error("#{self.class.name}: #{e.message} in #{path}")
        { error: "#{e.message} in #{path}" }
      rescue => e
        @logger.error("#{self.class.name} failed: #{e.message}")
        { error: e.message }
      end

      private

      def render(entries, path, query, kind)
        if query || kind
          flat_list(entries, path, query, kind)
        else
          "Outline of #{path}:\n#{tree(entries)}"
        end
      end

      def tree(entries)
        entries.map { |e| "#{'  ' * e.depth}#{label(e)} (L#{e.line})" }.join("\n")
      end

      def flat_list(entries, path, query, kind)
        pairs = qualify(entries)
        pairs = pairs.select { |e, _| e.kind.to_s == kind } if kind
        if query
          q = query.downcase
          pairs = pairs.select { |e, qn| qn.downcase.include?(q) || e.name.downcase.include?(q) }
        end
        return "no matching definitions in #{path}" if pairs.empty?

        desc = ["definitions", ("matching #{query.inspect}" if query), ("of kind #{kind}" if kind)].compact.join(" ")
        header = "#{pairs.size} #{desc} in #{path}:"
        "#{header}\n#{pairs.map { |e, qn| "#{qn} (L#{e.line}) [#{e.kind}]" }.join("\n")}"
      end

      # Pair each entry with its fully-qualified name using the depth stack.
      def qualify(entries)
        namespace = []
        entries.map do |entry|
          namespace = namespace.first(entry.depth)
          ns = namespace.compact
          qualified =
            case entry.kind
            when :class, :module, :singleton_class
              full = (ns + [entry.name]).join("::")
              namespace[entry.depth] = entry.name
              full
            when :method
              ns.empty? ? entry.name : "#{ns.join('::')}##{entry.name}"
            else # constant
              ns.empty? ? entry.name : "#{ns.join('::')}::#{entry.name}"
            end
          [entry, qualified]
        end
      end

      def label(entry)
        case entry.kind
        when :class, :singleton_class then "class #{entry.name}"
        when :module then "module #{entry.name}"
        when :method then "def #{entry.name}"
        else entry.name
        end
      end
    end
  end
end
