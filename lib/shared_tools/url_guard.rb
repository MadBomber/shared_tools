# frozen_string_literal: true

require "uri"
require "ipaddr"
require "resolv"

module SharedTools
  # SSRF defense for tools that fetch arbitrary URLs (WebFetchTool,
  # HttpRequestTool, DownloadFileTool). It:
  #   - allows only http/https,
  #   - rejects embedded credentials,
  #   - enforces optional domain allow/deny lists,
  #   - resolves the host and blocks the request if ANY resolved address is
  #     private, loopback, link-local (incl. the cloud metadata IP), CGNAT,
  #     unique-local IPv6, or otherwise reserved.
  #
  # resolve! also returns a vetted IP so the caller can pin the socket to it
  # (Net::HTTP#ipaddr=), closing the DNS-rebinding window: the address that
  # was vetted is exactly the one connected to, while TLS/SNI/cert checks
  # still use the hostname. Re-run resolve! on every redirect hop (the http
  # helper does).
  class UrlGuard
    class Blocked < StandardError; end

    # A vetted result: the parsed URI plus a concrete IP that every
    # connection should be pinned to, so a second DNS lookup at connect time
    # can't swap in a private address (DNS rebinding).
    Resolution = Struct.new(:uri, :address, keyword_init: true)

    ALLOWED_SCHEMES = %w[http https].freeze

    BLOCKED_RANGES = %w[
      0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16
      172.16.0.0/12 192.0.0.0/24 192.0.2.0/24 192.168.0.0/16 198.18.0.0/15
      198.51.100.0/24 203.0.113.0/24 224.0.0.0/4 240.0.0.0/4 255.255.255.255/32
      ::1/128 ::/128 fc00::/7 fe80::/10
    ].map { |cidr| IPAddr.new(cidr) }.freeze

    def initialize(allowlist: [], denylist: [])
      @allowlist = Array(allowlist).map { |d| d.to_s.downcase }
      @denylist = Array(denylist).map { |d| d.to_s.downcase }
    end

    # Returns a parsed URI if the URL is safe to fetch; raises Blocked
    # otherwise.
    def check!(url)
      resolve!(url).uri
    end

    # Like check!, but also returns a vetted IP address to pin the connection
    # to (see Resolution). Raises Blocked otherwise.
    def resolve!(url)
      uri = parse(url)
      raise Blocked, "only http/https URLs are allowed" unless ALLOWED_SCHEMES.include?(uri.scheme)
      raise Blocked, "URL must include a host" if uri.host.nil? || uri.host.empty?
      raise Blocked, "URLs with embedded credentials are not allowed" if uri.userinfo

      host = uri.host.downcase
      enforce_domain_lists(host)
      address = vetted_address(host)
      Resolution.new(uri: uri, address: address)
    end

    private

    def parse(url)
      URI.parse(url.to_s)
    rescue URI::InvalidURIError => e
      raise Blocked, "invalid URL: #{e.message}"
    end

    def enforce_domain_lists(host)
      raise Blocked, "host is denylisted: #{host}" if @denylist.any? { |d| host == d || host.end_with?(".#{d}") }
      return if @allowlist.empty?

      allowed = @allowlist.any? { |d| host == d || host.end_with?(".#{d}") }
      raise Blocked, "host is not on the allowlist: #{host}" unless allowed
    end

    # Resolve the host, block the request if ANY resolved address is in a
    # blocked range, and return the first address for the caller to pin to.
    def vetted_address(host)
      addresses = resolve(host)
      raise Blocked, "could not resolve host: #{host}" if addresses.empty?

      addresses.each do |addr|
        raise Blocked, "host resolves to a blocked address (#{addr})" if blocked_ip?(addr)
      end
      addresses.first
    end

    def resolve(host)
      Resolv.getaddresses(host)
    rescue StandardError
      []
    end

    def blocked_ip?(addr)
      ip = IPAddr.new(addr.to_s)
      ip = ip.native if ip.respond_to?(:ipv4_mapped?) && ip.ipv4_mapped?
      BLOCKED_RANGES.any? { |range| range.include?(ip) }
    rescue IPAddr::Error
      true # if we can't parse it, don't fetch it
    end
  end
end
