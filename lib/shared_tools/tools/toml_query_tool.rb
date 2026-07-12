# frozen_string_literal: true

require 'json'
require_relative '../../shared_tools'

module SharedTools
  module Tools
    # Parses TOML (from a file or an inline string) and either pretty-prints
    # it (as JSON, for readability) or extracts a value with a dot/bracket
    # path. In-process, read-only, no external gem dependency — handy for
    # Cargo.toml, pyproject.toml, and similar config.
    #
    # Path syntax matches JsonQueryTool / YamlQueryTool: dependencies.serde.version,
    # products[0].name, products[].name
    #
    # @example
    #   tool = SharedTools::Tools::TomlQueryTool.new
    #   tool.execute(path: "./Cargo.toml", query: "dependencies.serde.version")
    class TomlQueryTool < ::RubyLLM::Tool
      MAX_BYTES = 5 * 1024 * 1024

      def self.name = 'toml_query'

      description "Query TOML with a path expression, or pretty-print it. Provide either a file " \
                  "path or an inline toml string. Path syntax: keys separated by dots, [n] for " \
                  "array index, [] to map over an array (e.g. products[].name)."

      params do
        string :path,  description: "TOML file to read. Provide this or toml.", required: false
        string :toml,  description: "Inline TOML string. Provide this or path.", required: false
        string :query, description: "Path expression to extract, e.g. 'dependencies.serde.version'. Omit to pretty-print. Optional.", required: false
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param path [String, nil]
      # @param toml [String, nil]
      # @param query [String, nil]
      #
      # @return [String, Hash]
      def execute(path: nil, toml: nil, query: nil)
        @logger.info("#{self.class.name}#execute path=#{path.inspect} query=#{query.inspect}")

        source = load_source(path, toml)
        return source if source.is_a?(Hash) # error

        data = SharedTools::TomlParser.parse(source)
        result = query.to_s.strip.empty? ? data : SharedTools::DataPath.query(data, query)
        JSON.pretty_generate(result)
      rescue SharedTools::TomlParser::ParseError => e
        @logger.error("#{self.class.name} invalid TOML: #{e.message}")
        { error: "invalid TOML: #{e.message}" }
      rescue SharedTools::DataPath::Error => e
        @logger.error("#{self.class.name} bad query: #{e.message}")
        { error: e.message }
      rescue => e
        @logger.error("#{self.class.name} failed: #{e.message}")
        { error: e.message }
      end

      private

      def load_source(path, toml)
        if path && !path.to_s.empty?
          return { error: "file not found: #{path}" } unless File.exist?(path)
          return { error: "not a file: #{path}" } unless File.file?(path)
          return { error: "file too large (> #{MAX_BYTES} bytes)" } if File.size(path) > MAX_BYTES

          File.read(path).scrub
        elsif toml && !toml.to_s.empty?
          toml.to_s
        else
          { error: "provide either path or toml" }
        end
      end
    end
  end
end
