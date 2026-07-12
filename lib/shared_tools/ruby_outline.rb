# frozen_string_literal: true

require "ripper"

module SharedTools
  # Extracts a structural outline (classes, modules, methods, constants) from
  # Ruby source, with line numbers and nesting depth, for ParseRubyTool.
  # Parsing only — the code is never executed.
  #
  # Two backends sit behind one dispatcher and produce identical Entry lists:
  #
  #   * PrismBackend  — used automatically when `require "prism"` succeeds.
  #     Prism is bundled with Ruby 3.3+, so on a modern Ruby this needs no gem
  #     install. It is the same parser the VM itself uses, so its line numbers
  #     and structure are authoritative.
  #   * RipperBackend — the stdlib fallback for runtimes that don't bundle
  #     Prism. Dependency-free, always present.
  module RubyOutline
    class ParseError < StandardError; end

    Entry = Struct.new(:kind, :name, :line, :depth, keyword_init: true)

    module_function

    # True when the Prism backend can be loaded on this Ruby. Memoized.
    def prism_available?
      return @prism_available if defined?(@prism_available)

      @prism_available = begin
        require "prism"
        true
      rescue LoadError
        false
      end
    end

    def active_backend
      prism_available? ? PrismBackend : RipperBackend
    end

    # Returns an Array<Entry> in source order. Raises ParseError on a syntax
    # error. Pass backend: to force a specific one.
    def extract(source, backend: active_backend)
      backend.extract(source.to_s)
    end

    # --- Prism backend ----------------------------------------------------
    module PrismBackend
      module_function

      def extract(source)
        require "prism"
        result = Prism.parse(source)
        raise ParseError, "source is not valid Ruby (syntax error)" unless result.success?

        acc = []
        visit(result.value, 0, acc)
        acc
      end

      def visit(node, depth, acc)
        return if node.nil?

        case node
        when Prism::ClassNode
          acc << Entry.new(kind: :class, name: node.constant_path.slice,
                           line: node.constant_path.location.start_line, depth: depth)
          visit(node.body, depth + 1, acc)
        when Prism::ModuleNode
          acc << Entry.new(kind: :module, name: node.constant_path.slice,
                           line: node.constant_path.location.start_line, depth: depth)
          visit(node.body, depth + 1, acc)
        when Prism::SingletonClassNode
          acc << Entry.new(kind: :singleton_class, name: "<< #{node.expression.slice}",
                           line: node.location.start_line, depth: depth)
          visit(node.body, depth + 1, acc)
        when Prism::DefNode
          name = node.receiver ? "#{node.receiver.slice}.#{node.name}" : node.name.to_s
          acc << Entry.new(kind: :method, name: name, line: node.name_loc.start_line, depth: depth)
          # method bodies are not descended into
        when Prism::ConstantWriteNode
          acc << Entry.new(kind: :constant, name: node.name.to_s,
                           line: node.name_loc.start_line, depth: depth)
        else
          node.compact_child_nodes.each { |child| visit(child, depth, acc) }
        end
      end
    end

    # --- Ripper backend (stdlib) ------------------------------------------
    module RipperBackend
      module_function

      def extract(source)
        sexp = Ripper.sexp(source.to_s)
        raise ParseError, "source is not valid Ruby (syntax error)" if sexp.nil?

        acc = []
        walk(sexp, 0, acc)
        acc
      end

      def walk(node, depth, acc)
        return unless node.is_a?(Array)

        if node[0].is_a?(Symbol)
          dispatch(node, depth, acc)
        else
          node.each { |child| walk(child, depth, acc) }
        end
      end

      def dispatch(node, depth, acc)
        case node[0]
        when :program
          walk(node[1], depth, acc)
        when :class
          acc << Entry.new(kind: :class, name: const_name(node[1]), line: line_of(node[1]), depth: depth)
          walk(node[3], depth + 1, acc) # bodystmt
        when :module
          acc << Entry.new(kind: :module, name: const_name(node[1]), line: line_of(node[1]), depth: depth)
          walk(node[2], depth + 1, acc)
        when :sclass # class << self
          acc << Entry.new(kind: :singleton_class, name: "<< #{simple_name(node[1])}", line: line_of(node), depth: depth)
          walk(node[2], depth + 1, acc)
        when :def
          acc << Entry.new(kind: :method, name: ident_name(node[1]), line: line_of(node[1]), depth: depth)
        when :defs # def self.x / def Recv.x
          name = "#{simple_name(node[1])}.#{ident_name(node[3])}"
          acc << Entry.new(kind: :method, name: name, line: line_of(node[3]), depth: depth)
        when :bodystmt
          walk(node[1], depth, acc)
        when :assign
          handle_assign(node, depth, acc)
        else
          node[1..].each { |child| walk(child, depth, acc) }
        end
      end

      def handle_assign(node, depth, acc)
        target = node[1]
        return unless target.is_a?(Array) && target[0] == :var_field

        field = target[1]
        return unless field.is_a?(Array) && field[0] == :@const

        acc << Entry.new(kind: :constant, name: field[1], line: field[2]&.first, depth: depth)
      end

      def const_name(node)
        case node && node[0]
        when :const_ref, :top_const_ref, :var_ref
          simple_name(node[1])
        when :const_path_ref # Foo::Bar
          "#{const_name(node[1])}::#{simple_name(node[2])}"
        else
          simple_name(node)
        end
      end

      def simple_name(node)
        return node.to_s unless node.is_a?(Array)

        case node[0]
        when :@const, :@ident, :@ivar, :@gvar, :@kw then node[1].to_s
        when :const_ref, :var_ref, :var_field then simple_name(node[1])
        when :const_path_ref then "#{simple_name(node[1])}::#{simple_name(node[2])}"
        else
          leaf = find_name_leaf(node)
          leaf ? leaf[1].to_s : "?"
        end
      end

      def ident_name(node)
        return node.to_s unless node.is_a?(Array)

        node[0] == :@ident || node[0] == :@const || node[0] == :@kw ? node[1].to_s : simple_name(node)
      end

      def line_of(node)
        return nil unless node.is_a?(Array)

        if node.size == 3 && node[2].is_a?(Array) && node[2].size == 2 &&
           node[2][0].is_a?(Integer) && node[0].is_a?(Symbol)
          return node[2][0]
        end

        node.each do |child|
          line = line_of(child)
          return line if line
        end
        nil
      end

      def find_name_leaf(node)
        return nil unless node.is_a?(Array)
        return node if %i[@const @ident @kw].include?(node[0])

        node.each do |child|
          found = find_name_leaf(child)
          return found if found
        end
        nil
      end
    end
  end
end
