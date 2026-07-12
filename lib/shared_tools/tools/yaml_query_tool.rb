# frozen_string_literal: true

require 'yaml'
require 'json'
require 'date'
require_relative '../../shared_tools'

module SharedTools
  module Tools
    # Parses YAML (from a file or an inline string) and either pretty-prints
    # it (as JSON, for readability) or extracts a value with a dot/bracket
    # path. Uses safe_load — no arbitrary Ruby objects are instantiated from
    # the document.
    #
    # Path syntax matches JsonQueryTool: users[0].name, users[].email, config.port
    #
    # @example
    #   tool = SharedTools::Tools::YamlQueryTool.new
    #   tool.execute(path: "./docker-compose.yml", query: "services[0].image")
    class YamlQueryTool < ::RubyLLM::Tool
      MAX_BYTES = 5 * 1024 * 1024
      PERMITTED = [Date, Time, Symbol].freeze

      def self.name = 'yaml_query'

      description "Query YAML with a path expression, or pretty-print it. Provide either a file " \
                  "path or an inline yaml string. Loaded safely (no object deserialization). Path " \
                  "syntax: keys separated by dots, [n] for array index, [] to map over an array."

      params do
        string :path,  description: "YAML file to read. Provide this or yaml.", required: false
        string :yaml,  description: "Inline YAML string. Provide this or path.", required: false
        string :query, description: "Path expression to extract, e.g. 'services[0].image'. Omit to pretty-print. Optional.", required: false
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param path [String, nil]
      # @param yaml [String, nil]
      # @param query [String, nil]
      #
      # @return [String, Hash]
      def execute(path: nil, yaml: nil, query: nil)
        @logger.info("#{self.class.name}#execute path=#{path.inspect} query=#{query.inspect}")

        source = load_source(path, yaml)
        return source if source.is_a?(Hash) # error

        data = YAML.safe_load(source, permitted_classes: PERMITTED, aliases: true)
        result = query.to_s.strip.empty? ? data : SharedTools::DataPath.query(data, query)
        JSON.pretty_generate(result)
      rescue Psych::DisallowedClass => e
        @logger.error("#{self.class.name} unsafe YAML: #{e.message}")
        { error: "YAML contains a disallowed type: #{e.message}" }
      rescue Psych::SyntaxError => e
        @logger.error("#{self.class.name} invalid YAML: #{e.message}")
        { error: "invalid YAML: #{e.message}" }
      rescue SharedTools::DataPath::Error => e
        @logger.error("#{self.class.name} bad query: #{e.message}")
        { error: e.message }
      rescue => e
        @logger.error("#{self.class.name} failed: #{e.message}")
        { error: e.message }
      end

      private

      def load_source(path, yaml)
        if path && !path.to_s.empty?
          return { error: "file not found: #{path}" } unless File.exist?(path)
          return { error: "not a file: #{path}" } unless File.file?(path)
          return { error: "file too large (> #{MAX_BYTES} bytes)" } if File.size(path) > MAX_BYTES

          File.read(path).scrub
        elsif yaml && !yaml.to_s.empty?
          yaml.to_s
        else
          { error: "provide either path or yaml" }
        end
      end
    end
  end
end
