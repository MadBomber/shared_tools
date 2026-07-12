# frozen_string_literal: true

module SharedTools
  # Shared path-navigation for the structured-data query tools (JsonQueryTool,
  # YamlQueryTool, TomlQueryTool). Path syntax: dot-separated keys, [n] for
  # array indices, and [] to map a field across an array. Examples:
  #   users[0].name        users[].email        config.server.port
  module DataPath
    class Error < StandardError; end

    module_function

    def query(data, path)
      apply(data, parse(path))
    end

    def parse(path)
      cleaned = path.to_s.strip.sub(/\A\$?\.?/, "")
      tokens = []
      cleaned.scan(/[^.\[\]]+|\[\d+\]|\[\]/) do |match|
        tokens << case match
                  when "[]" then :map
                  when /\A\[(\d+)\]\z/ then Regexp.last_match(1).to_i
                  else match
                  end
      end
      raise Error, "could not parse path: #{path.inspect}" if tokens.empty?

      tokens
    end

    def apply(data, tokens)
      return data if tokens.empty? || data.nil?

      token, *rest = tokens
      case token
      when :map
        raise Error, "[] expects an array, got #{data.class}" unless data.is_a?(Array)

        data.map { |element| apply(element, rest) }
      when Integer
        raise Error, "index [#{token}] expects an array, got #{data.class}" unless data.is_a?(Array)

        apply(data[token], rest)
      else
        raise Error, "key '#{token}' expects an object, got #{data.class}" unless data.is_a?(Hash)

        apply(data[token], rest)
      end
    end
  end
end
