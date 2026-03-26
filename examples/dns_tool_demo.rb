#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Demo: DnsTool
#
# Perform DNS lookups, reverse lookups, record queries (A, AAAA, MX, TXT, NS, CNAME),
# external IP detection, and WHOIS database queries.
#
# Run:
#   bundle exec ruby -I examples examples/dns_tool_demo.rb

ENV['RUBY_LLM_DEBUG'] = 'true'

require_relative 'common'
require 'shared_tools/tools/dns_tool'


title "DnsTool Demo — DNS lookups, WHOIS queries, and external IP detection"

@chat = @chat.with_tool(SharedTools::Tools::DnsTool.new)

ask "Look up the A records for 'ruby-lang.org'."

ask "Look up the IPv6 (AAAA) addresses for 'google.com'."

ask "What are the MX (mail exchange) records for 'gmail.com'? List them in priority order."

ask "Get the TXT records for 'github.com' and explain what they are used for."

ask "Who are the authoritative nameservers (NS records) for 'cloudflare.com'?"

ask "Perform a reverse DNS lookup on the IP address 8.8.8.8 and tell me the hostname."

ask "Get all available DNS records for 'example.com'."

title "External IP", char: '-'
@chat = new_chat.with_tool(SharedTools::Tools::DnsTool.new)
ask "What is my current external (public-facing) IP address?"

ask "Now do a reverse DNS lookup on that IP address to see if it has a hostname."

title "WHOIS — Domain Lookup", char: '-'
@chat = new_chat.with_tool(SharedTools::Tools::DnsTool.new)
ask "Do a WHOIS lookup on 'github.com'. Who is the registrar, when does it expire, and what nameservers is it using?"

ask "Do a WHOIS lookup on 'ruby-lang.org'. When was it registered and when does it expire?"

title "WHOIS — IP Address Lookup", char: '-'
@chat = new_chat.with_tool(SharedTools::Tools::DnsTool.new)
ask "Do a WHOIS lookup on the IP 8.8.8.8. Who owns this IP, what netblock is it in, and what is the abuse contact?"

title "Combined Workflow", char: '-'
@chat = new_chat.with_tool(SharedTools::Tools::DnsTool.new)
ask <<~PROMPT
  I want a full investigation of 'cloudflare.com':
  1. Look up its A records
  2. Do a WHOIS lookup on the domain
  3. Do a WHOIS lookup on one of the IP addresses you found
  Summarize what you learn about who owns and operates this domain and infrastructure.
PROMPT

title "Done", char: '-'
puts "DnsTool demonstrated DNS records, reverse lookups, external IP detection, and WHOIS queries."
