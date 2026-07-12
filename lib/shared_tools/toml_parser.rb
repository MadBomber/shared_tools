# frozen_string_literal: true

module SharedTools
  # A small, dependency-free TOML parser used by TomlQueryTool. Covers the
  # common surface of TOML 1.0 used by real config files: comments;
  # bare/quoted/dotted keys; [tables] and [[arrays of tables]]; basic/literal
  # strings and their multiline forms; integers (with underscores and
  # 0x/0o/0b), floats (exponents, inf, nan), booleans; offset/local
  # date-times, dates and times (kept as strings); arrays (multiline, nested,
  # heterogeneous); and inline tables. Returns nested Hashes/Arrays with
  # string keys, ready for JSON output or DataPath navigation.
  module TomlParser
    class ParseError < StandardError; end

    module_function

    def parse(text)
      Parser.new(text).parse
    end

    # Recursive-descent parser over a character cursor.
    class Parser
      DATETIME = /\A(\d{4}-\d{2}-\d{2}([Tt ]\d{2}:\d{2}:\d{2}(\.\d+)?([Zz]|[+-]\d{2}:\d{2})?)?|\d{2}:\d{2}:\d{2}(\.\d+)?)/

      def initialize(source)
        @s = source.to_s
        @i = 0
        @len = @s.length
        @root = {}
      end

      def parse
        @current = @root
        loop do
          skip_blank
          break if eof?

          if peek == "["
            parse_table_header
          else
            key = parse_key
            skip_inline_ws
            expect("=")
            value = parse_value
            assign(@current, key, value)
            expect_line_end
          end
        end
        @root
      end

      private

      # --- table headers ------------------------------------------------
      def parse_table_header
        advance # [
        array = false
        if peek == "["
          advance
          array = true
        end
        skip_inline_ws
        keys = parse_key
        skip_inline_ws
        expect("]")
        expect("]") if array
        expect_line_end

        @current = array ? open_array_table(keys) : open_table(keys)
      end

      def open_table(keys)
        node = @root
        keys.each do |k|
          node[k] = {} unless node.key?(k)
          raise ParseError, "cannot redefine #{k.inspect} as a table" unless node[k].is_a?(Hash) || node[k].is_a?(Array)

          node = node[k].is_a?(Array) ? node[k].last : node[k]
        end
        node
      end

      def open_array_table(keys)
        node = @root
        keys[0..-2].each do |k|
          node[k] = {} unless node.key?(k)
          raise ParseError, "cannot redefine #{k.inspect} as a table" unless node[k].is_a?(Hash) || node[k].is_a?(Array)

          node = node[k].is_a?(Array) ? node[k].last : node[k]
        end
        last = keys[-1]
        node[last] ||= []
        raise ParseError, "key #{last.inspect} is not an array of tables" unless node[last].is_a?(Array)

        fresh = {}
        node[last] << fresh
        fresh
      end

      # --- keys ---------------------------------------------------------
      def parse_key
        parts = []
        loop do
          skip_inline_ws
          parts << parse_key_segment
          skip_inline_ws
          break unless peek == "."

          advance
        end
        parts
      end

      def parse_key_segment
        case peek
        when '"' then parse_basic_string
        when "'" then parse_literal_string
        else
          start = @i
          advance while !eof? && peek.match?(/[A-Za-z0-9_-]/)
          raise ParseError, "empty key near position #{@i}" if @i == start

          @s[start...@i]
        end
      end

      def assign(table, keys, value)
        node = table
        keys[0..-2].each do |k|
          node[k] = {} unless node.key?(k)
          raise ParseError, "cannot redefine #{k.inspect} as a table" unless node[k].is_a?(Hash)

          node = node[k]
        end
        node[keys[-1]] = value
      end

      # --- values -------------------------------------------------------
      def parse_value
        skip_inline_ws
        case peek
        when '"', "'" then parse_string
        when "[" then parse_array
        when "{" then parse_inline_table
        else parse_atom
        end
      end

      def parse_atom
        rest = @s[@i..]
        if (m = rest.match(DATETIME))
          @i += m[0].length
          return m[0]
        end
        if rest.start_with?("true")
          @i += 4
          return true
        end
        if rest.start_with?("false")
          @i += 5
          return false
        end
        parse_number
      end

      def parse_number
        start = @i
        advance while !eof? && !peek.match?(/[\s,\]}#]/)
        token = @s[start...@i]
        raise ParseError, "expected a value near position #{start}" if token.empty?

        classify_number(token)
      end

      def classify_number(token)
        t = token.gsub("_", "")
        return Float::INFINITY if %w[inf +inf].include?(t)
        return -Float::INFINITY if t == "-inf"
        return Float::NAN if %w[nan +nan -nan].include?(t)

        if (m = t.match(/\A[+-]?0(x|o|b)(.+)\z/))
          base = { "x" => 16, "o" => 8, "b" => 2 }[m[1]]
          return Integer(m[2], base)
        end
        return Float(t) if t.match?(/[.eE]/) && !t.match?(/\A[+-]?0x/i)

        Integer(t, 10)
      rescue ArgumentError
        raise ParseError, "invalid number: #{token.inspect}"
      end

      # --- strings ------------------------------------------------------
      def parse_string
        if @s[@i, 3] == '"""'
          parse_multiline_basic
        elsif @s[@i, 3] == "'''"
          parse_multiline_literal
        elsif peek == '"'
          parse_basic_string
        else
          parse_literal_string
        end
      end

      def parse_basic_string
        advance # opening "
        out = +""
        until eof?
          c = peek
          raise ParseError, "unterminated string" if c == "\n"

          if c == '"'
            advance
            return out
          elsif c == "\\"
            advance
            out << read_escape
          else
            out << c
            advance
          end
        end
        raise ParseError, "unterminated string"
      end

      def parse_literal_string
        advance # opening '
        start = @i
        advance while !eof? && peek != "'" && peek != "\n"
        raise ParseError, "unterminated literal string" if eof? || peek == "\n"

        str = @s[start...@i]
        advance # closing '
        str
      end

      def parse_multiline_basic
        @i += 3
        @i += 1 if peek == "\n"
        out = +""
        until eof?
          if @s[@i, 3] == '"""'
            @i += 3
            return out
          elsif peek == "\\" && @s[@i + 1..].match?(/\A[ \t]*\r?\n/)
            @i += 1
            @i += 1 while !eof? && peek.match?(/[\s]/)
          elsif peek == "\\"
            advance
            out << read_escape
          else
            out << peek
            advance
          end
        end
        raise ParseError, "unterminated multiline string"
      end

      def parse_multiline_literal
        @i += 3
        @i += 1 if peek == "\n"
        start = @i
        until eof?
          if @s[@i, 3] == "'''"
            str = @s[start...@i]
            @i += 3
            return str
          end
          advance
        end
        raise ParseError, "unterminated multiline literal string"
      end

      def read_escape
        c = peek
        advance
        case c
        when "n" then "\n"
        when "t" then "\t"
        when "r" then "\r"
        when "b" then "\b"
        when "f" then "\f"
        when '"' then '"'
        when "\\" then "\\"
        when "u" then read_unicode(4)
        when "U" then read_unicode(8)
        else raise ParseError, "invalid escape: \\#{c}"
        end
      end

      def read_unicode(width)
        hex = @s[@i, width]
        raise ParseError, "invalid unicode escape" unless hex && hex.match?(/\A[0-9A-Fa-f]{#{width}}\z/)

        @i += width
        [hex.to_i(16)].pack("U")
      end

      # --- arrays & inline tables --------------------------------------
      def parse_array
        advance # [
        arr = []
        loop do
          skip_ws_comments
          break if eof?

          if peek == "]"
            advance
            return arr
          end
          arr << parse_value
          skip_ws_comments
          if peek == ","
            advance
          elsif peek == "]"
            advance
            return arr
          else
            raise ParseError, "expected ',' or ']' in array near position #{@i}"
          end
        end
        raise ParseError, "unterminated array"
      end

      def parse_inline_table
        advance # {
        table = {}
        skip_ws_comments
        if peek == "}"
          advance
          return table
        end
        loop do
          skip_ws_comments
          key = parse_key
          skip_inline_ws
          expect("=")
          assign(table, key, parse_value)
          skip_ws_comments
          if peek == ","
            advance
          elsif peek == "}"
            advance
            return table
          else
            raise ParseError, "expected ',' or '}' in inline table near position #{@i}"
          end
        end
      end

      # --- cursor helpers ----------------------------------------------
      def peek
        @s[@i]
      end

      def advance
        @i += 1
      end

      def eof?
        @i >= @len
      end

      def expect(char)
        raise ParseError, "expected #{char.inspect} near position #{@i}, got #{peek.inspect}" unless peek == char

        advance
      end

      def skip_inline_ws
        advance while !eof? && (peek == " " || peek == "\t")
      end

      # Between top-level statements: whitespace, newlines and comment lines.
      def skip_blank
        loop do
          if !eof? && peek.match?(/[ \t\r\n]/)
            advance
          elsif peek == "#"
            advance while !eof? && peek != "\n"
          else
            break
          end
        end
      end

      # Inside arrays/inline tables: whitespace, newlines and comments.
      def skip_ws_comments
        skip_blank
      end

      # After a key/value or header: optional comment, then newline or EOF.
      def expect_line_end
        skip_inline_ws
        if peek == "#"
          advance while !eof? && peek != "\n"
        end
        return if eof?

        advance if peek == "\r"
        if peek == "\n"
          advance
        elsif !eof?
          raise ParseError, "expected end of line near position #{@i}, got #{peek.inspect}"
        end
      end
    end
  end
end
