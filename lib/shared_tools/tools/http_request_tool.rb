# frozen_string_literal: true

require_relative "../../shared_tools"
require_relative "http_helpers"

module SharedTools
  module Tools
    # A general HTTP client, UrlGuard-protected. Read methods (GET/HEAD) work
    # by default; mutating methods (POST/PUT/PATCH/DELETE) require user
    # authorization (see SharedTools.execute?), so the safe default can't
    # change remote state. Returns status, key headers, and the body.
    #
    # @example
    #   tool = SharedTools::Tools::HttpRequestTool.new
    #   tool.execute(url: "https://api.example.com/status")
    #   tool.execute(url: "https://api.example.com/items", method: "POST", body: '{"name":"x"}')
    class HttpRequestTool < ::RubyLLM::Tool
      include HttpHelpers

      READ_METHODS = %w[GET HEAD].freeze
      MUTATING_METHODS = %w[POST PUT PATCH DELETE].freeze
      SHOWN_HEADERS = %w[content-type content-length location etag last-modified].freeze

      def self.name = 'http_request'

      description "Make an HTTP request to an http/https URL and return the status, headers, and " \
                  "body. GET and HEAD are available by default; POST/PUT/PATCH/DELETE require user " \
                  "authorization. Cannot reach private, loopback, or cloud-metadata addresses."

      params do
        string :url,     description: "The http/https URL to request."
        string :method,  description: "HTTP method: GET (default), HEAD, POST, PUT, PATCH, DELETE.", required: false
        object :headers, description: "Optional request headers as a JSON object of name/value strings.", required: false do
          additional_properties true
        end
        string :body,    description: "Optional request body (for POST/PUT/PATCH).", required: false
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param url [String]
      # @param method [String]
      # @param headers [Hash, nil]
      # @param body [String, nil]
      #
      # @return [String, Hash]
      def execute(url:, method: "GET", headers: nil, body: nil)
        @logger.info("#{self.class.name}#execute url=#{url.inspect} method=#{method}")

        verb = method.to_s.strip.upcase
        verb = "GET" if verb.empty?
        return { error: "unsupported method: #{verb}" } unless (READ_METHODS + MUTATING_METHODS).include?(verb)

        if MUTATING_METHODS.include?(verb)
          allowed = SharedTools.execute?(tool: self.class.to_s, stuff: "#{verb} #{url}")
          unless allowed
            @logger.warn("User declined #{verb} #{url}")
            return { error: "User declined the request" }
          end
        end

        response = guarded_request(verb, url, headers: headers, body: body)
        return { error: "HTTP #{response.status} from #{response.final_url}" } if response.status >= 400

        format_response(verb, response)
      rescue SharedTools::UrlGuard::Blocked => e
        @logger.error("#{self.class.name} url blocked: #{e.message}")
        { error: e.message }
      rescue HttpHelpers::FetchError => e
        @logger.error("#{self.class.name} request failed: #{e.message}")
        { error: "request failed: #{e.message}" }
      end

      private

      def format_response(verb, response)
        lines = ["#{verb} #{response.final_url} -> #{response.status}"]
        SHOWN_HEADERS.each do |name|
          value = Array(response.headers[name]).first
          lines << "#{name}: #{value}" if value
        end
        body = response.body.to_s.scrub
        lines << "\n--- body ---\n#{body}" unless body.empty?
        lines.join("\n")
      end
    end
  end
end
