# frozen_string_literal: true

require "json"
require "net/http"
require "uri"
require_relative "../../shared_tools"

module SharedTools
  module Tools
    # Read-only RubyGems.org metadata lookup. The host is fixed and all user
    # input is URL-encoded into the path/query (and gem names are validated),
    # so there is no arbitrary-URL / SSRF surface here.
    #
    # @example
    #   tool = SharedTools::Tools::GemTool.new
    #   tool.execute(name: "ruby_llm")
    #   tool.execute(name: "ruby_llm", action: "version")
    #   tool.execute(name: "sqlite3", action: "search")
    class GemTool < ::RubyLLM::Tool
      class NotFound < StandardError; end
      class HttpError < StandardError; end

      HTTP_TIMEOUT = 10
      USER_AGENT = "SharedTools/#{SharedTools::VERSION} (+https://github.com/madbomber/shared_tools)"
      ACTIONS = %w[info version dependencies search].freeze
      NAME_RE = /\A[A-Za-z0-9_.-]+\z/
      HOST = "https://rubygems.org"

      def self.name = 'gem'

      description "Look up RubyGems.org metadata for a gem (read-only). Actions: info (summary), " \
                  "version (latest version), dependencies (runtime deps), search (find gems by " \
                  "query). For 'search', pass the query as name."

      params do
        string :name,   description: "Gem name, or — for action 'search' — the search query."
        string :action, description: "One of: info, version, dependencies, search. Default info.", required: false
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param name [String]
      # @param action [String]
      #
      # @return [String, Hash]
      def execute(name:, action: "info")
        @logger.info("#{self.class.name}#execute name=#{name.inspect} action=#{action.inspect}")

        act = normalize_action(action)
        return { error: "unknown action: #{act} (use #{ACTIONS.join(', ')})" } unless ACTIONS.include?(act)
        return search(name) if act == "search"

        gem = name.to_s.strip
        return { error: "invalid gem name: #{gem.inspect}" } unless gem.match?(NAME_RE)

        case act
        when "version"      then version(gem)
        when "dependencies" then dependencies(gem)
        else                     info(gem)
        end
      rescue NotFound
        @logger.error("#{self.class.name}: gem not found: #{name}")
        { error: "gem not found: #{name}" }
      rescue HttpError => e
        @logger.error("#{self.class.name}: rubygems.org request failed: #{e.message}")
        { error: "rubygems.org request failed: #{e.message}" }
      end

      private

      def normalize_action(action)
        a = action.to_s.strip.downcase
        a.empty? ? "info" : a
      end

      def info(gem)
        data = get_json("#{HOST}/api/v1/gems/#{enc(gem)}.json")
        lines = ["#{data['name']} #{data['version']}"]
        lines << data["info"].to_s.strip unless data["info"].to_s.strip.empty?
        lines << "homepage: #{data['homepage_uri']}" if data["homepage_uri"]
        lines << "licenses: #{Array(data['licenses']).join(', ')}" if data["licenses"]
        lines << "downloads: #{data['downloads']}" if data["downloads"]
        runtime = data.dig("dependencies", "runtime") || []
        unless runtime.empty?
          lines << "runtime deps: #{runtime.map { |d| "#{d['name']} #{d['requirements']}" }.join('; ')}"
        end
        lines.join("\n")
      end

      def version(gem)
        data = get_json("#{HOST}/api/v1/versions/#{enc(gem)}/latest.json")
        v = data["version"]
        return { error: "gem not found: #{gem}" } if v.nil? || v == "unknown"

        "#{gem} #{v}"
      end

      def dependencies(gem)
        data = get_json("#{HOST}/api/v1/gems/#{enc(gem)}.json")
        runtime = data.dig("dependencies", "runtime") || []
        dev = data.dig("dependencies", "development") || []
        return "#{gem} #{data['version']} has no runtime dependencies" if runtime.empty?

        body = +"#{gem} #{data['version']} runtime dependencies:\n"
        runtime.each { |d| body << "  #{d['name']} #{d['requirements']}\n" }
        body << "(+#{dev.size} development deps)" unless dev.empty?
        body
      end

      def search(query)
        q = query.to_s.strip
        return { error: "empty search query" } if q.empty?

        results = get_json("#{HOST}/api/v1/search.json?query=#{enc(q)}")
        return "no gems found for #{q.inspect}" unless results.is_a?(Array) && results.any?

        body = +"#{results.size} result#{results.size == 1 ? '' : 's'} for #{q.inspect}:\n"
        results.first(20).each do |g|
          summary = g["info"].to_s.split("\n").first
          body << "  #{g['name']} #{g['version']} — #{summary}\n"
        end
        body
      end

      def enc(str)
        URI.encode_www_form_component(str)
      end

      # Seam for tests. Performs a GET and parses JSON, mapping transport and
      # not-found conditions onto the tool's error classes.
      def get_json(url)
        uri = URI.parse(url)
        req = Net::HTTP::Get.new(uri)
        req["User-Agent"] = USER_AGENT
        req["Accept"] = "application/json"

        res = Net::HTTP.start(uri.host, uri.port,
                              use_ssl: uri.scheme == "https",
                              open_timeout: HTTP_TIMEOUT,
                              read_timeout: HTTP_TIMEOUT) { |http| http.request(req) }

        case res
        when Net::HTTPSuccess  then JSON.parse(res.body)
        when Net::HTTPNotFound then raise NotFound
        else raise HttpError, "HTTP #{res.code}"
        end
      rescue JSON::ParserError => e
        raise HttpError, "invalid JSON (#{e.message})"
      rescue SocketError, Net::OpenTimeout, Net::ReadTimeout => e
        raise HttpError, e.message
      end
    end
  end
end
