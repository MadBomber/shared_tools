# frozen_string_literal: true

require_relative "../../shared_tools"
require_relative "http_helpers"

module SharedTools
  module Tools
    # Fetches a URL over http/https and returns its readable text (HTML is
    # stripped to text). Every request and redirect hop passes through
    # UrlGuard, so it can't be pointed at internal/loopback/metadata
    # addresses. Read-only — no authorization prompt required.
    #
    # @example
    #   tool = SharedTools::Tools::WebFetchTool.new
    #   tool.execute(url: "https://example.com")
    class WebFetchTool < ::RubyLLM::Tool
      include HttpHelpers

      def self.name = 'web_fetch'

      description "Fetch a web page or text/JSON resource over http/https and return its readable " \
                  "content (HTML is converted to text). Follows redirects safely. Cannot reach " \
                  "private, loopback, or cloud-metadata addresses."

      params do
        string :url, description: "The http/https URL to fetch."
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param url [String]
      #
      # @return [String, Hash]
      def execute(url:)
        @logger.info("#{self.class.name}#execute url=#{url.inspect}")

        response = guarded_get(url)
        return { error: "HTTP #{response.status} from #{response.final_url}" } if response.status >= 400

        content_type = content_type_of(response)
        text = extract_text(response.body, content_type)

        header = "GET #{response.final_url} -> #{response.status} (#{content_type})"
        "#{header}\n\n#{text}".strip
      rescue SharedTools::UrlGuard::Blocked => e
        @logger.error("#{self.class.name} url blocked: #{e.message}")
        { error: e.message }
      rescue HttpHelpers::FetchError => e
        @logger.error("#{self.class.name} fetch failed: #{e.message}")
        { error: "fetch failed: #{e.message}" }
      end

      private

      def content_type_of(response)
        Array(response.headers["content-type"]).first.to_s.split(";").first.to_s.strip
      end

      def extract_text(body, content_type)
        text = body.to_s.scrub
        return collapse(text) unless content_type =~ /html|xml/i

        text = text.dup
        text.gsub!(%r{<script\b[^>]*>.*?</script>}mi, " ")
        text.gsub!(%r{<style\b[^>]*>.*?</style>}mi, " ")
        text.gsub!(/<!--.*?-->/m, " ")
        text.gsub!(%r{</(?:p|div|br|li|h[1-6]|tr|section|article)\s*/?>}i, "\n")
        text.gsub!(/<[^>]+>/, " ")
        collapse(decode_entities(text))
      end

      def decode_entities(str)
        str.gsub("&amp;", "&").gsub("&lt;", "<").gsub("&gt;", ">")
           .gsub("&quot;", '"').gsub("&#39;", "'").gsub("&nbsp;", " ")
      end

      def collapse(str)
        str.gsub(/[ \t]+/, " ").gsub(/\n[ \t]*/, "\n").gsub(/\n{3,}/, "\n\n").strip
      end
    end
  end
end
