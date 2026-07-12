# frozen_string_literal: true

require 'json'
require_relative '../../shared_tools'

module SharedTools
  module Tools
    # Parses JSON (from a file or an inline string) and either pretty-prints
    # it or extracts a value with a dot/bracket path. In-process, read-only.
    #
    # Path syntax: dot-separated keys, [n] for array indices, and [] to map a
    # field across an array. Examples:
    #   users[0].name        users[].email        config.server.port
    #
    # @example
    #   tool = SharedTools::Tools::JsonQueryTool.new
    #   tool.execute(path: "./config.json", query: "servers[0].host")
    #   tool.execute(json: '{"a":{"b":1}}', query: "a.b")
    class JsonQueryTool < ::RubyLLM::Tool
      MAX_BYTES = 5 * 1024 * 1024

      def self.name = 'json_query'

      description "Query JSON with a path expression, or pretty-print it. Provide either a file " \
                  "path or an inline json string. Path syntax: keys separated by dots, [n] for " \
                  "array index, [] to map over an array (e.g. users[].name)."

      params do
        string :path,  description: "JSON file to read. Provide this or json.", required: false
        string :json,  description: "Inline JSON string. Provide this or path.", required: false
        string :query, description: "Path expression to extract, e.g. 'users[0].name'. Omit to pretty-print. Optional.", required: false
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param path [String, nil]
      # @param json [String, nil]
      # @param query [String, nil]
      #
      # @return [String, Hash]
      def execute(path: nil, json: nil, query: nil)
        @logger.info("#{self.class.name}#execute path=#{path.inspect} query=#{query.inspect}")

        source = load_source(path, json)
        return source if source.is_a?(Hash) # error

        data = JSON.parse(source)
        result = query.to_s.strip.empty? ? data : SharedTools::DataPath.query(data, query)
        JSON.pretty_generate(result)
      rescue JSON::ParserError => e
        @logger.error("#{self.class.name} invalid JSON: #{e.message}")
        { error: "invalid JSON: #{e.message}" }
      rescue SharedTools::DataPath::Error => e
        @logger.error("#{self.class.name} bad query: #{e.message}")
        { error: e.message }
      rescue => e
        @logger.error("#{self.class.name} failed: #{e.message}")
        { error: e.message }
      end

      private

      def load_source(path, json)
        if path && !path.to_s.empty?
          return { error: "file not found: #{path}" } unless File.exist?(path)
          return { error: "not a file: #{path}" } unless File.file?(path)
          return { error: "file too large (> #{MAX_BYTES} bytes)" } if File.size(path) > MAX_BYTES

          File.read(path).scrub
        elsif json && !json.to_s.empty?
          json.to_s
        else
          { error: "provide either path or json" }
        end
      end
    end
  end
end
