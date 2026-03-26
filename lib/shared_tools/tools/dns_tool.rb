# frozen_string_literal: true

require 'resolv'
require 'socket'
require 'net/http'
require 'uri'
require_relative '../../shared_tools'

module SharedTools
  module Tools
    # DNS lookup tool supporting A, AAAA, MX, TXT, NS, CNAME, reverse, all-records,
    # external IP detection, and WHOIS database queries.
    #
    # @example
    #   tool = SharedTools::Tools::DnsTool.new
    #   tool.execute(action: 'a',           host: 'ruby-lang.org')
    #   tool.execute(action: 'mx',          host: 'gmail.com')
    #   tool.execute(action: 'reverse',     host: '8.8.8.8')
    #   tool.execute(action: 'external_ip')
    #   tool.execute(action: 'whois',       host: 'github.com')
    #   tool.execute(action: 'whois',       host: '8.8.8.8')
    class DnsTool < ::RubyLLM::Tool
      def self.name = 'dns_tool'

      description <<~DESC
        Perform DNS lookups, reverse lookups, record queries, external IP detection,
        and WHOIS database queries for any hostname, domain name, or IP address.

        Actions:
        - 'a'           — IPv4 address records (A)
        - 'aaaa'        — IPv6 address records (AAAA)
        - 'mx'          — Mail exchange records, sorted by priority
        - 'txt'         — TXT records (SPF, DKIM, verification tokens, etc.)
        - 'ns'          — Authoritative nameserver records
        - 'cname'       — Canonical name (alias) records
        - 'reverse'     — Reverse PTR lookup for an IP address
        - 'all'         — A, MX, TXT, NS, and CNAME records combined
        - 'external_ip' — Detect the current machine's public-facing IP address
        - 'ip_location' — Geolocate an IP address (city, region, country, lat/lon, timezone, ISP)
        - 'whois'       — Query the WHOIS database for a domain name or IP address
      DESC

      params do
        string :action, description: <<~DESC.strip
          The DNS or network operation to perform. One of:
          - 'a'           — Look up IPv4 A records for a hostname. Returns the IPv4 addresses
                            that the hostname resolves to. Useful for verifying DNS propagation,
                            checking load balancer IPs, or confirming a domain points to the
                            expected server.
          - 'aaaa'        — Look up IPv6 AAAA records for a hostname. Returns IPv6 addresses
                            that the hostname resolves to. Important for dual-stack network
                            verification and IPv6 connectivity testing.
          - 'mx'          — Look up Mail Exchange (MX) records for a domain, sorted by
                            priority (lowest number = highest priority). Essential for diagnosing
                            email delivery issues, verifying mail server configuration, and
                            confirming that a domain is using the expected mail provider.
          - 'txt'         — Look up TXT records for a domain. TXT records carry human-readable
                            text and machine-readable data including SPF policies (which servers
                            may send mail for the domain), DKIM public keys (for email signing),
                            DMARC policies, domain ownership verification tokens (Google, GitHub,
                            etc.), and BIMI brand indicators.
          - 'ns'          — Look up the authoritative Name Server (NS) records for a domain.
                            Returns the hostnames of the DNS servers that are authoritative for
                            the domain. Useful for verifying registrar settings, diagnosing DNS
                            delegation problems, and confirming a domain is using a specific
                            DNS provider.
          - 'cname'       — Look up Canonical Name (CNAME) alias records for a hostname.
                            Returns the target hostname that this alias points to. Common for
                            CDN configurations, third-party service integrations (e.g. Shopify,
                            Heroku), and subdomain aliases.
          - 'reverse'     — Perform a reverse PTR (pointer) lookup for an IP address. Returns
                            the hostname associated with the IP, if one is configured. Important
                            for mail server deliverability (forward-confirmed reverse DNS),
                            identifying unknown IP addresses, and network forensics.
          - 'all'         — Retrieve A, MX, TXT, NS, and CNAME records for a domain in a
                            single call. Provides a comprehensive snapshot of a domain's DNS
                            configuration. Useful for domain audits, migration planning, and
                            quick overviews.
          - 'external_ip' — Detect the current machine's public-facing (external) IP address
                            as seen by the internet. Does not require a host parameter. Useful
                            for firewall rule generation, VPN verification, geolocation context,
                            abuse report submissions, and confirming that traffic is routing
                            through the expected network path (e.g. a VPN or proxy).
          - 'ip_location' — Geolocate an IP address using a free geolocation API. Returns the
                            city, region, country, country code, latitude, longitude, timezone,
                            ISP name, and organisation. Accepts any public IPv4 address in the
                            host parameter; omit host (or pass the result of an 'external_ip'
                            call) to geolocate your own public IP. Useful for determining a
                            user's approximate location from their IP address, cross-referencing
                            IP ownership with physical geography, building location-aware
                            workflows (e.g. routing to the nearest server), and providing
                            contextual information such as local time and weather.
          - 'whois'       — Query the WHOIS database for a domain name or IP address. For
                            domain names, returns registrar information, registration and
                            expiry dates, name servers, registrant organization (when not
                            privacy-protected), and domain status flags. For IP addresses,
                            returns the network owner, ASN (Autonomous System Number), CIDR
                            netblock, country of allocation, and abuse contact information.
                            Useful for identifying who owns an IP attacking your server,
                            checking domain expiry dates, verifying registrar lock status,
                            finding abuse contacts, and threat intelligence workflows.
        DESC

        string :host, description: <<~DESC.strip, required: false
          The hostname, domain name, or IP address to query. Required for all actions
          except 'external_ip'. Examples:
          - Hostname:    'ruby-lang.org', 'mail.google.com'
          - Domain:      'github.com', 'cloudflare.com'
          - IP address:  '8.8.8.8', '2001:4860:4860::8888'
          For the 'reverse' action, provide an IP address.
          For the 'whois' action, provide either a domain name or an IP address.
          For the 'external_ip' action, this parameter is ignored.
          For the 'ip_location' action, provide a public IPv4 address, or omit to geolocate your own external IP.
        DESC
      end

      WHOIS_PORT    = 43
      WHOIS_TIMEOUT = 10
      IANA_WHOIS    = 'whois.iana.org'
      ARIN_WHOIS    = 'whois.arin.net'
      IP_SERVICES   = %w[
        https://api.ipify.org
        https://ifconfig.me/ip
        https://icanhazip.com
      ].freeze

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param action [String] lookup type
      # @param host   [String] hostname or IP (not required for external_ip)
      # @return [Hash] results
      def execute(action:, host: nil)
        @logger.info("DnsTool#execute action=#{action} host=#{host}")

        case action.to_s.downcase
        when 'a'           then lookup_a(host)
        when 'aaaa'        then lookup_aaaa(host)
        when 'mx'          then lookup_mx(host)
        when 'txt'         then lookup_txt(host)
        when 'ns'          then lookup_ns(host)
        when 'cname'       then lookup_cname(host)
        when 'reverse'     then lookup_reverse(host)
        when 'all'         then lookup_all(host)
        when 'external_ip' then lookup_external_ip
        when 'ip_location' then lookup_ip_location(host)
        when 'whois'       then lookup_whois(host)
        else
          { success: false, error: "Unknown action '#{action}'. Use: a, aaaa, mx, txt, ns, cname, reverse, all, external_ip, ip_location, whois" }
        end
      rescue => e
        @logger.error("DnsTool error for #{host}: #{e.message}")
        { success: false, host: host, error: e.message }
      end

      private

      def lookup_a(host)
        records = Resolv.getaddresses(host).select { |a| a.match?(/\A\d+\.\d+\.\d+\.\d+\z/) }
        { success: true, host: host, type: 'A', records: records }
      end

      def lookup_aaaa(host)
        records = Resolv.getaddresses(host).reject { |a| a.match?(/\A\d+\.\d+\.\d+\.\d+\z/) }
        { success: true, host: host, type: 'AAAA', records: records }
      end

      def lookup_mx(host)
        records = []
        Resolv::DNS.open do |dns|
          dns.getresources(host, Resolv::DNS::Resource::IN::MX).each do |r|
            records << { priority: r.preference, exchange: r.exchange.to_s }
          end
        end
        records.sort_by! { |r| r[:priority] }
        { success: true, host: host, type: 'MX', records: records }
      end

      def lookup_txt(host)
        records = []
        Resolv::DNS.open do |dns|
          dns.getresources(host, Resolv::DNS::Resource::IN::TXT).each do |r|
            records << r.strings.join(' ')
          end
        end
        { success: true, host: host, type: 'TXT', records: records }
      end

      def lookup_ns(host)
        records = []
        Resolv::DNS.open do |dns|
          dns.getresources(host, Resolv::DNS::Resource::IN::NS).each do |r|
            records << r.name.to_s
          end
        end
        { success: true, host: host, type: 'NS', records: records.sort }
      end

      def lookup_cname(host)
        records = []
        Resolv::DNS.open do |dns|
          dns.getresources(host, Resolv::DNS::Resource::IN::CNAME).each do |r|
            records << r.name.to_s
          end
        end
        { success: true, host: host, type: 'CNAME', records: records }
      end

      def lookup_reverse(ip)
        hostname = Resolv.getname(ip)
        { success: true, ip: ip, type: 'PTR', hostname: hostname }
      rescue Resolv::ResolvError => e
        { success: false, ip: ip, type: 'PTR', error: "No reverse DNS entry found: #{e.message}" }
      end

      def lookup_all(host)
        {
          success: true,
          host:    host,
          a:       lookup_a(host)[:records],
          mx:      lookup_mx(host)[:records],
          txt:     lookup_txt(host)[:records],
          ns:      lookup_ns(host)[:records],
          cname:   lookup_cname(host)[:records]
        }
      end

      # Detect external IP by querying well-known public IP echo services.
      # Tries each service in order and returns the first successful response.
      def lookup_external_ip
        IP_SERVICES.each do |url|
          ip = http_get(url)&.strip
          next unless ip&.match?(/\A[\d.:a-fA-F]+\z/)

          @logger.info("External IP resolved via #{url}: #{ip}")
          return {
            success:  true,
            type:     'external_ip',
            ip:       ip,
            source:   url,
            note:     'This is your public-facing IP address as seen by the internet.'
          }
        rescue => e
          @logger.warn("IP service #{url} failed: #{e.message}")
          next
        end

        { success: false, type: 'external_ip', error: 'All external IP services unreachable' }
      end

      # Geolocate an IP address using the ip-api.com free JSON endpoint.
      # If no IP is supplied, geolocates the caller's own external IP.
      def lookup_ip_location(ip = nil)
        target = ip.to_s.strip.empty? ? '' : "/#{ip.strip}"
        url    = "http://ip-api.com/json#{target}?fields=status,message,country,countryCode,region,regionName,city,zip,lat,lon,timezone,isp,org,as,query"

        @logger.info("IP geolocation query: #{url}")
        raw  = http_get(url)
        data = JSON.parse(raw)

        if data['status'] == 'fail'
          return { success: false, type: 'ip_location', error: data['message'], ip: ip }
        end

        {
          success:      true,
          type:         'ip_location',
          ip:           data['query'],
          city:         data['city'],
          region:       data['regionName'],
          region_code:  data['region'],
          country:      data['country'],
          country_code: data['countryCode'],
          zip:          data['zip'],
          latitude:     data['lat'],
          longitude:    data['lon'],
          timezone:     data['timezone'],
          isp:          data['isp'],
          organization: data['org'],
          asn:          data['as'],
          note:         'Geolocation is approximate. Accuracy varies by ISP and region.'
        }
      rescue => e
        @logger.error("IP geolocation failed for #{ip}: #{e.message}")
        { success: false, type: 'ip_location', error: e.message, ip: ip }
      end

      # Query the WHOIS database for a domain name or IP address.
      # For domains, queries IANA first to find the authoritative WHOIS server,
      # then queries that server for full registration details.
      # For IPs, queries ARIN (which redirects to the appropriate RIR).
      def lookup_whois(host)
        return { success: false, error: "host is required for whois lookup" } if host.nil? || host.strip.empty?

        host = host.strip.downcase

        if ip_address?(host)
          whois_server = ARIN_WHOIS
          raw          = whois_query(whois_server, host)
          parsed       = parse_whois_ip(raw)
        else
          # Step 1: ask IANA which server is authoritative for this TLD
          iana_response = whois_query(IANA_WHOIS, host)
          whois_server  = extract_whois_server(iana_response) || IANA_WHOIS

          # Step 2: query the authoritative server
          raw    = whois_query(whois_server, host)
          parsed = parse_whois_domain(raw)
        end

        {
          success:      true,
          host:         host,
          type:         ip_address?(host) ? 'whois_ip' : 'whois_domain',
          whois_server: whois_server,
          parsed:       parsed,
          raw:          raw
        }
      rescue => e
        @logger.error("WHOIS lookup failed for #{host}: #{e.message}")
        { success: false, host: host, type: 'whois', error: e.message }
      end

      # Open a TCP connection to a WHOIS server on port 43, send the query,
      # and return the full plain-text response.
      def whois_query(server, query)
        @logger.debug("WHOIS query: #{server} <- #{query}")
        response = String.new(encoding: 'binary')

        Socket.tcp(server, WHOIS_PORT, connect_timeout: WHOIS_TIMEOUT) do |sock|
          sock.write("#{query}\r\n")
          response << sock.read
        end

        response.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
      end

      # Extract the 'whois:' referral server from an IANA response.
      def extract_whois_server(iana_response)
        iana_response.each_line do |line|
          return $1.strip if line.match?(/^whois:/i) && line =~ /^whois:\s+(\S+)/i
        end
        nil
      end

      # Parse key fields from a domain WHOIS response into a structured hash.
      def parse_whois_domain(raw)
        fields = {
          registrar:          extract_field(raw, /registrar:\s+(.+)/i),
          registrar_url:      extract_field(raw, /registrar url:\s+(.+)/i),
          created:            extract_field(raw, /creation date:\s+(.+)/i) ||
                              extract_field(raw, /registered:\s+(.+)/i),
          updated:            extract_field(raw, /updated date:\s+(.+)/i) ||
                              extract_field(raw, /last[\s-]updated?:\s+(.+)/i),
          expires:            extract_field(raw, /registry expiry date:\s+(.+)/i) ||
                              extract_field(raw, /expir(?:y|ation) date:\s+(.+)/i) ||
                              extract_field(raw, /paid[\s-]till:\s+(.+)/i),
          status:             extract_all_fields(raw, /domain status:\s+(.+)/i),
          name_servers:       extract_all_fields(raw, /name server:\s+(.+)/i),
          registrant_org:     extract_field(raw, /registrant\s+organization:\s+(.+)/i) ||
                              extract_field(raw, /registrant:\s+(.+)/i),
          registrant_country: extract_field(raw, /registrant\s+country:\s+(.+)/i),
          dnssec:             extract_field(raw, /dnssec:\s+(.+)/i)
        }.compact

        fields[:name_servers] = fields[:name_servers]&.map(&:downcase)&.sort&.uniq
        fields
      end

      # Parse key fields from an IP/network WHOIS response into a structured hash.
      def parse_whois_ip(raw)
        {
          organization: extract_field(raw, /orgname:\s+(.+)/i) ||
                        extract_field(raw, /org-name:\s+(.+)/i) ||
                        extract_field(raw, /netname:\s+(.+)/i),
          network:      extract_field(raw, /(?:inetnum|netrange|cidr):\s+(.+)/i),
          cidr:         extract_field(raw, /cidr:\s+(.+)/i),
          country:      extract_field(raw, /country:\s+(.+)/i),
          asn:          extract_field(raw, /originas:\s+(.+)/i) ||
                        extract_field(raw, /aut-num:\s+(.+)/i),
          abuse_email:  extract_field(raw, /orgabuseemail:\s+(.+)/i) ||
                        extract_field(raw, /abuse-mailbox:\s+(.+)/i),
          abuse_phone:  extract_field(raw, /orgabusephone:\s+(.+)/i),
          updated:      extract_field(raw, /updated:\s+(.+)/i) ||
                        extract_field(raw, /last[\s-]modified:\s+(.+)/i)
        }.compact
      end

      def extract_field(text, pattern)
        text.each_line do |line|
          m = line.match(pattern)
          return m[1].strip if m
        end
        nil
      end

      def extract_all_fields(text, pattern)
        results = []
        text.each_line do |line|
          m = line.match(pattern)
          results << m[1].strip if m
        end
        results.empty? ? nil : results
      end

      def ip_address?(str)
        str.match?(/\A\d{1,3}(\.\d{1,3}){3}\z/) ||
          str.match?(/\A[0-9a-fA-F:]+\z/) && str.include?(':')
      end

      def http_get(url)
        uri      = URI(url)
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                            open_timeout: 5, read_timeout: 5) do |http|
          http.get(uri.path.empty? ? '/' : uri.path).body
        end
      end
    end
  end
end
