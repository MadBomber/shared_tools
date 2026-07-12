# frozen_string_literal: true

require "fileutils"
require "pathname"
require_relative "../../shared_tools"
require_relative "http_helpers"

module SharedTools
  module Tools
    # Downloads a URL to a file within root. The request goes through
    # UrlGuard (so it can't be pointed at internal/loopback/metadata
    # addresses), follows redirects safely, and is capped at
    # HttpHelpers::MAX_FETCH_BYTES. The destination path is confined to
    # root. Mutating — requires user authorization (see
    # SharedTools.execute?).
    #
    # @example
    #   tool = SharedTools::Tools::DownloadFileTool.new(root: "./downloads")
    #   tool.execute(url: "https://example.com/file.zip", path: "file.zip")
    class DownloadFileTool < ::RubyLLM::Tool
      include HttpHelpers

      def self.name = 'download_file'

      description "Download an http/https URL to a file within root. SSRF-protected and " \
                  "size-capped. Use for fetching an asset or release to disk (web_fetch returns text " \
                  "instead). Overwrites an existing file."

      params do
        string :url,  description: "The http/https URL to download."
        string :path, description: "Destination path, relative to root."
      end

      # @param root [String] optional, defaults to the current directory
      # @param logger [Logger] optional logger
      def initialize(root: nil, logger: nil)
        @root = root || Dir.pwd
        @logger = logger || RubyLLM.logger
      end

      # @param url [String]
      # @param path [String]
      #
      # @return [String, Hash]
      def execute(url:, path:)
        @logger.info("#{self.class.name}#execute url=#{url.inspect} path=#{path.inspect}")

        real = resolve!(path)
        return { error: "path is a directory: #{path}" } if File.directory?(real)

        allowed = SharedTools.execute?(tool: self.class.to_s, stuff: "Download #{url} to #{path}")
        unless allowed
          @logger.warn("User declined to download #{url}")
          return { error: "User declined to download the file" }
        end

        response = guarded_get(url)
        return { error: "server returned HTTP #{response.status} for #{response.final_url}" } if response.status >= 400

        body = response.body.to_s
        FileUtils.mkdir_p(File.dirname(real))
        File.binwrite(real, body)

        "Downloaded #{body.bytesize} bytes from #{response.final_url} to #{path}"
      rescue SecurityError => e
        @logger.error("#{self.class.name} path denied: #{e.message}")
        { error: e.message }
      rescue SharedTools::UrlGuard::Blocked => e
        @logger.error("#{self.class.name} url blocked: #{e.message}")
        { error: e.message }
      rescue HttpHelpers::FetchError => e
        @logger.error("#{self.class.name} download failed: #{e.message}")
        { error: "download failed: #{e.message}" }
      end

      private

      def resolve!(path)
        root = Pathname.new(File.expand_path(@root))
        resolved = (root + path).cleanpath
        raise SecurityError, "path escapes root: #{path}" unless resolved.ascend.any? { |ancestor| ancestor == root }

        resolved.to_s
      end
    end
  end
end
