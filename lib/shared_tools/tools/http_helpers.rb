# frozen_string_literal: true

require "net/http"
require "uri"
require_relative "../../shared_tools"
require_relative "../url_guard"

module SharedTools
  module Tools
    # Shared guarded-HTTP behavior for WebFetchTool, HttpRequestTool, and
    # DownloadFileTool. Every request URL and every redirect hop passes
    # through UrlGuard, and the socket is pinned to the vetted IP so a second
    # DNS lookup can't redirect to an internal address; when the host has
    # several vetted addresses, an unreachable one is skipped for the next.
    # SSRF protection is always on — there is no bypass.
    module HttpHelpers
      HTTP_TIMEOUT = 10
      MAX_REDIRECTS = 5
      MAX_FETCH_BYTES = 5 * 1024 * 1024
      USER_AGENT = "SharedTools/#{SharedTools::VERSION} (+https://github.com/madbomber/shared_tools)"

      # Errors raised before a request is sent, when one vetted address
      # cannot be reached (e.g. an IPv6 address on a host with no IPv6
      # route); the next vetted address is tried.
      CONNECT_ERRORS = [
        Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL, Net::OpenTimeout
      ].freeze

      Response = Struct.new(:status, :headers, :body, :final_url, keyword_init: true)

      class FetchError < StandardError; end

      def url_guard
        SharedTools::UrlGuard.new(allowlist: @web_allowlist || [], denylist: @web_denylist || [])
      end

      # GET with redirect following and a body-size cap. Each hop is
      # re-guarded and re-pinned.
      def guarded_get(url)
        checker = url_guard
        current = url
        seen = 0

        loop do
          resolution = checker.resolve!(current)
          response, body = perform_pinned(resolution, "GET", nil, nil)

          if redirect?(response)
            location = response["location"]
            raise FetchError, "redirect with no Location header (status #{response.code})" unless location
            raise FetchError, "too many redirects (max #{MAX_REDIRECTS})" if seen >= MAX_REDIRECTS

            seen += 1
            current = URI.join(resolution.uri.to_s, location).to_s
            next
          end

          return Response.new(status: response.code.to_i, headers: response.to_hash,
                              body: body, final_url: resolution.uri.to_s)
        end
      rescue SharedTools::UrlGuard::Blocked
        raise
      rescue StandardError => e
        raise FetchError, e.message
      end

      # A single request with an explicit method/headers/body (no redirect
      # following). Used by HttpRequestTool.
      def guarded_request(method, url, headers: {}, body: nil)
        resolution = url_guard.resolve!(url)
        response, raw = perform_pinned(resolution, method.to_s.upcase, headers, body)
        Response.new(status: response.code.to_i, headers: response.to_hash, body: raw, final_url: resolution.uri.to_s)
      rescue SharedTools::UrlGuard::Blocked
        raise
      rescue StandardError => e
        raise FetchError, e.message
      end

      private

      def redirect?(response)
        response.is_a?(Net::HTTPRedirection)
      end

      # Connect to each vetted address in turn until one is reachable.
      def perform_pinned(resolution, method, headers, body)
        pins = Array(resolution.addresses)
        pins = [resolution.address] if pins.empty?

        pins.each_with_index do |pin, index|
          return perform(resolution.uri, method, headers, body, pin)
        rescue *CONNECT_ERRORS
          raise if index == pins.size - 1
        end
      end

      def perform(uri, method, headers, body, pin)
        request = build_request(uri, method, headers, body)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.ipaddr = pin if pin # pin to the vetted address (closes DNS rebinding)
        http.open_timeout = HTTP_TIMEOUT
        http.read_timeout = HTTP_TIMEOUT

        captured = +""
        response = http.start do |conn|
          conn.request(request) do |res|
            unless res.is_a?(Net::HTTPRedirection)
              res.read_body do |chunk|
                captured << chunk
                break if captured.bytesize >= MAX_FETCH_BYTES
              end
            end
            res
          end
        end

        [response, captured]
      end

      def build_request(uri, method, headers, body)
        klass = begin
          Net::HTTP.const_get(method.capitalize)
        rescue NameError
          nil
        end
        raise FetchError, "unsupported HTTP method: #{method}" unless klass && klass <= Net::HTTPRequest

        request = klass.new(uri)
        request["User-Agent"] = USER_AGENT
        request["Accept"] ||= "*/*"
        Array(headers).each { |k, v| request[k.to_s] = v.to_s } if headers
        request.body = body.to_s if body && !body.to_s.empty?
        request
      end
    end
  end
end
