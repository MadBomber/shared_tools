#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: DnsTool
#
# Perform DNS lookups, reverse lookups, and record queries (A, MX, TXT, NS, CNAME).
#
# Run:
#   bundle exec ruby -I examples examples/dns_tool_demo.rb

require_relative 'common'
require 'shared_tools/tools/dns_tool'


title "DnsTool Demo — DNS lookups, reverse queries, and record inspection"

@chat = @chat.with_tool(SharedTools::Tools::DnsTool.new)

ask "Look up the A records for 'ruby-lang.org'."

ask "Look up the IPv6 (AAAA) addresses for 'google.com'."

ask "What are the MX (mail exchange) records for 'gmail.com'? List them in priority order."

ask "Get the TXT records for 'github.com' and explain what they are used for."

ask "Who are the authoritative nameservers (NS records) for 'cloudflare.com'?"

ask "Perform a reverse DNS lookup on the IP address 8.8.8.8 and tell me the hostname."

ask "Get all available DNS records for 'example.com'."

title "Done", char: '-'
puts "DnsTool demonstrated A, AAAA, MX, TXT, NS, reverse, and all-records DNS queries."
