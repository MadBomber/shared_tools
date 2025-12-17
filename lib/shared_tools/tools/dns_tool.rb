# frozen_string_literal: true

require 'ruby_llm/tool'
require 'resolv'
require 'socket'

module SharedTools
  module Tools
    # A tool for performing DNS lookups and reverse DNS queries.
    # Uses Ruby's built-in Resolv library for cross-platform support.
    #
    # @example
    #   tool = SharedTools::Tools::DnsTool.new
    #   result = tool.execute(action: 'lookup', hostname: 'google.com')
    #   puts result[:addresses]
    class DnsTool < RubyLLM::Tool
      def self.name = 'dns'

      description <<~'DESCRIPTION'
        Perform DNS lookups and reverse DNS queries.

        Uses Ruby's built-in Resolv library for cross-platform DNS resolution.

        Actions:
        - 'lookup': Resolve a hostname to IP addresses
        - 'reverse': Perform reverse DNS lookup (IP to hostname)
        - 'mx': Get MX (mail exchange) records for a domain
        - 'txt': Get TXT records for a domain
        - 'ns': Get NS (nameserver) records for a domain
        - 'all': Get all available DNS records for a domain

        Record Types (for lookup action):
        - 'A': IPv4 addresses (default)
        - 'AAAA': IPv6 addresses
        - 'CNAME': Canonical name records
        - 'ANY': All record types

        Example usage:
          tool = SharedTools::Tools::DnsTool.new

          # Basic lookup
          tool.execute(action: 'lookup', hostname: 'google.com')

          # Get MX records
          tool.execute(action: 'mx', hostname: 'gmail.com')

          # Reverse lookup
          tool.execute(action: 'reverse', ip: '8.8.8.8')

          # Get all records
          tool.execute(action: 'all', hostname: 'example.com')
      DESCRIPTION

      params do
        string :action, description: <<~DESC.strip
          The DNS action to perform:
          - 'lookup': Resolve hostname to IP addresses
          - 'reverse': IP to hostname lookup
          - 'mx': Get mail exchange records
          - 'txt': Get TXT records
          - 'ns': Get nameserver records
          - 'all': Get all available records
        DESC

        string :hostname, description: <<~DESC.strip, required: false
          The hostname/domain to look up.
          Required for 'lookup', 'mx', 'txt', 'ns', and 'all' actions.
        DESC

        string :ip, description: <<~DESC.strip, required: false
          The IP address for reverse DNS lookup.
          Required for 'reverse' action.
        DESC

        string :record_type, description: <<~DESC.strip, required: false
          Record type for 'lookup' action:
          - 'A': IPv4 addresses (default)
          - 'AAAA': IPv6 addresses
          - 'CNAME': Canonical name
          - 'ANY': All types
        DESC
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # Execute DNS action
      #
      # @param action [String] DNS action to perform
      # @param hostname [String, nil] hostname to look up
      # @param ip [String, nil] IP for reverse lookup
      # @param record_type [String, nil] record type for lookup
      # @return [Hash] DNS results
      def execute(action:, hostname: nil, ip: nil, record_type: nil)
        @logger.info("DnsTool#execute action=#{action.inspect}")

        case action.to_s.downcase
        when 'lookup'
          lookup(hostname, record_type || 'A')
        when 'reverse'
          reverse_lookup(ip)
        when 'mx'
          mx_lookup(hostname)
        when 'txt'
          txt_lookup(hostname)
        when 'ns'
          ns_lookup(hostname)
        when 'all'
          all_records(hostname)
        else
          {
            success: false,
            error: "Unknown action: #{action}. Valid actions are: lookup, reverse, mx, txt, ns, all"
          }
        end
      rescue Resolv::ResolvError => e
        @logger.error("DnsTool DNS error: #{e.message}")
        {
          success: false,
          error: "DNS resolution failed: #{e.message}"
        }
      rescue => e
        @logger.error("DnsTool error: #{e.message}")
        {
          success: false,
          error: e.message
        }
      end

      private

      def lookup(hostname, record_type)
        return { success: false, error: "Hostname is required" } if hostname.nil? || hostname.empty?

        results = {
          success: true,
          hostname: hostname,
          record_type: record_type.upcase,
          addresses: []
        }

        resolver = Resolv::DNS.new

        case record_type.upcase
        when 'A'
          addresses = resolver.getresources(hostname, Resolv::DNS::Resource::IN::A)
          results[:addresses] = addresses.map { |a| { type: 'A', address: a.address.to_s } }
        when 'AAAA'
          addresses = resolver.getresources(hostname, Resolv::DNS::Resource::IN::AAAA)
          results[:addresses] = addresses.map { |a| { type: 'AAAA', address: a.address.to_s } }
        when 'CNAME'
          cnames = resolver.getresources(hostname, Resolv::DNS::Resource::IN::CNAME)
          results[:addresses] = cnames.map { |c| { type: 'CNAME', name: c.name.to_s } }
        when 'ANY'
          # Get A records
          a_records = resolver.getresources(hostname, Resolv::DNS::Resource::IN::A)
          results[:addresses] += a_records.map { |a| { type: 'A', address: a.address.to_s } }

          # Get AAAA records
          aaaa_records = resolver.getresources(hostname, Resolv::DNS::Resource::IN::AAAA)
          results[:addresses] += aaaa_records.map { |a| { type: 'AAAA', address: a.address.to_s } }

          # Get CNAME records
          cname_records = resolver.getresources(hostname, Resolv::DNS::Resource::IN::CNAME)
          results[:addresses] += cname_records.map { |c| { type: 'CNAME', name: c.name.to_s } }
        else
          return { success: false, error: "Unknown record type: #{record_type}. Valid types are: A, AAAA, CNAME, ANY" }
        end

        resolver.close
        results
      end

      def reverse_lookup(ip)
        return { success: false, error: "IP address is required" } if ip.nil? || ip.empty?

        # Validate IP address format
        unless valid_ip?(ip)
          return { success: false, error: "Invalid IP address format: #{ip}" }
        end

        hostnames = []

        begin
          # Try using Resolv for reverse lookup
          name = Resolv.getname(ip)
          hostnames << name
        rescue Resolv::ResolvError
          # Try alternative method using DNS PTR record
          begin
            resolver = Resolv::DNS.new
            ptr_name = ip_to_ptr(ip)
            ptrs = resolver.getresources(ptr_name, Resolv::DNS::Resource::IN::PTR)
            hostnames = ptrs.map { |p| p.name.to_s }
            resolver.close
          rescue
            # No reverse DNS record found
          end
        end

        {
          success: true,
          ip: ip,
          hostnames: hostnames,
          found: !hostnames.empty?
        }
      end

      def mx_lookup(hostname)
        return { success: false, error: "Hostname is required" } if hostname.nil? || hostname.empty?

        resolver = Resolv::DNS.new
        mx_records = resolver.getresources(hostname, Resolv::DNS::Resource::IN::MX)

        records = mx_records.map do |mx|
          {
            priority: mx.preference,
            exchange: mx.exchange.to_s
          }
        end.sort_by { |r| r[:priority] }

        resolver.close

        {
          success: true,
          hostname: hostname,
          mx_records: records,
          count: records.length
        }
      end

      def txt_lookup(hostname)
        return { success: false, error: "Hostname is required" } if hostname.nil? || hostname.empty?

        resolver = Resolv::DNS.new
        txt_records = resolver.getresources(hostname, Resolv::DNS::Resource::IN::TXT)

        records = txt_records.map do |txt|
          txt.strings.join
        end

        resolver.close

        {
          success: true,
          hostname: hostname,
          txt_records: records,
          count: records.length
        }
      end

      def ns_lookup(hostname)
        return { success: false, error: "Hostname is required" } if hostname.nil? || hostname.empty?

        resolver = Resolv::DNS.new
        ns_records = resolver.getresources(hostname, Resolv::DNS::Resource::IN::NS)

        records = ns_records.map { |ns| ns.name.to_s }

        resolver.close

        {
          success: true,
          hostname: hostname,
          nameservers: records,
          count: records.length
        }
      end

      def all_records(hostname)
        return { success: false, error: "Hostname is required" } if hostname.nil? || hostname.empty?

        resolver = Resolv::DNS.new

        results = {
          success: true,
          hostname: hostname,
          records: {}
        }

        # A records
        a_records = resolver.getresources(hostname, Resolv::DNS::Resource::IN::A)
        results[:records][:A] = a_records.map { |a| a.address.to_s } unless a_records.empty?

        # AAAA records
        aaaa_records = resolver.getresources(hostname, Resolv::DNS::Resource::IN::AAAA)
        results[:records][:AAAA] = aaaa_records.map { |a| a.address.to_s } unless aaaa_records.empty?

        # MX records
        mx_records = resolver.getresources(hostname, Resolv::DNS::Resource::IN::MX)
        unless mx_records.empty?
          results[:records][:MX] = mx_records.map do |mx|
            { priority: mx.preference, exchange: mx.exchange.to_s }
          end.sort_by { |r| r[:priority] }
        end

        # TXT records
        txt_records = resolver.getresources(hostname, Resolv::DNS::Resource::IN::TXT)
        results[:records][:TXT] = txt_records.map { |t| t.strings.join } unless txt_records.empty?

        # NS records
        ns_records = resolver.getresources(hostname, Resolv::DNS::Resource::IN::NS)
        results[:records][:NS] = ns_records.map { |ns| ns.name.to_s } unless ns_records.empty?

        # CNAME records
        cname_records = resolver.getresources(hostname, Resolv::DNS::Resource::IN::CNAME)
        results[:records][:CNAME] = cname_records.map { |c| c.name.to_s } unless cname_records.empty?

        # SOA record
        begin
          soa_records = resolver.getresources(hostname, Resolv::DNS::Resource::IN::SOA)
          unless soa_records.empty?
            soa = soa_records.first
            results[:records][:SOA] = {
              mname: soa.mname.to_s,
              rname: soa.rname.to_s,
              serial: soa.serial,
              refresh: soa.refresh,
              retry: soa.retry,
              expire: soa.expire,
              minimum: soa.minimum
            }
          end
        rescue
          # SOA might not be available for all domains
        end

        resolver.close
        results
      end

      def valid_ip?(ip)
        # Check IPv4
        return true if ip =~ /\A(\d{1,3}\.){3}\d{1,3}\z/ &&
                       ip.split('.').all? { |octet| octet.to_i.between?(0, 255) }

        # Check IPv6 (simplified check)
        return true if ip =~ /\A[\da-fA-F:]+\z/ && ip.include?(':')

        false
      end

      def ip_to_ptr(ip)
        if ip.include?(':')
          # IPv6 - not fully implemented, but basic support
          ip.gsub(':', '').chars.reverse.join('.') + '.ip6.arpa'
        else
          # IPv4
          ip.split('.').reverse.join('.') + '.in-addr.arpa'
        end
      end
    end
  end
end
