# DnsTool

DNS resolution, WHOIS lookups, IP geolocation, and external IP detection — all via the standard library with no API key required.

## Basic Usage

```ruby
require 'shared_tools'
require 'shared_tools/tools/dns_tool'

dns = SharedTools::Tools::DnsTool.new

# A record lookup
result = dns.execute(action: "a", host: "example.com")

# Get my external IP address
result = dns.execute(action: "external_ip")

# Geolocate an IP
result = dns.execute(action: "ip_location", host: "8.8.8.8")

# WHOIS for a domain
result = dns.execute(action: "whois", host: "ruby-lang.org")
```

## Actions

### a

Look up the IPv4 address (A record) for a hostname.

```ruby
dns.execute(action: "a", host: "example.com")
# => { host: "example.com", addresses: ["93.184.216.34"], ttl: 3600 }
```

---

### aaaa

Look up the IPv6 address (AAAA record) for a hostname.

```ruby
dns.execute(action: "aaaa", host: "example.com")
```

---

### mx

Look up mail exchange (MX) records for a domain.

```ruby
dns.execute(action: "mx", host: "gmail.com")
# => { host: "gmail.com", records: [{ priority: 10, exchange: "alt1.gmail-smtp-in.l.google.com" }, ...] }
```

---

### ns

Look up name server (NS) records for a domain.

```ruby
dns.execute(action: "ns", host: "ruby-lang.org")
# => { host: "ruby-lang.org", nameservers: ["ns1.ruby-lang.org", ...] }
```

---

### txt

Look up TXT records (SPF, DKIM, domain verification tokens, etc.) for a domain.

```ruby
dns.execute(action: "txt", host: "github.com")
# => { host: "github.com", records: ["v=spf1 ip4:..."] }
```

---

### cname

Look up the canonical name (CNAME) for an alias.

```ruby
dns.execute(action: "cname", host: "www.example.com")
```

---

### reverse

Perform a reverse DNS lookup (PTR record) for an IP address.

```ruby
dns.execute(action: "reverse", host: "8.8.8.8")
# => { ip: "8.8.8.8", hostname: "dns.google" }
```

---

### all

Run all standard lookups (A, AAAA, MX, NS, TXT, CNAME) for a host in one call.

```ruby
dns.execute(action: "all", host: "example.com")
```

---

### external_ip

Detect the machine's current public (external) IP address. No `host` parameter required.

Uses a list of free public IP services and returns the first successful result.

```ruby
dns.execute(action: "external_ip")
# => { ip: "203.0.113.42", source: "https://api.ipify.org" }
```

---

### ip_location

Geolocate an IP address using the free [ip-api.com](http://ip-api.com) service. No API key required.

Returns city, region, country, latitude, longitude, timezone, ISP, and ASN.

**Parameters:**

- `host` *(optional)*: IP address to geolocate. If omitted, geolocates the machine's own external IP.

```ruby
# Geolocate a specific IP
dns.execute(action: "ip_location", host: "8.8.8.8")
# => { ip: "8.8.8.8", city: "Mountain View", region: "California",
#      country: "United States", country_code: "US", lat: 37.4056,
#      lon: -122.0775, timezone: "America/Los_Angeles",
#      isp: "Google LLC", org: "Google Public DNS", asn: "AS15169" }

# Geolocate your own machine's IP
dns.execute(action: "ip_location")
```

---

### whois

Query the WHOIS database for a domain name or IP address using standard TCP on port 43. No API key required.

For domains, automatically follows IANA referrals to the authoritative registrar. For IP addresses, queries ARIN.

**Parameters:**

- `host`: Domain name or IP address to look up

```ruby
# WHOIS for a domain
dns.execute(action: "whois", host: "ruby-lang.org")
# => { query: "ruby-lang.org", registrar: "...", created: "...",
#      expires: "...", updated: "...", status: [...], nameservers: [...],
#      raw: "..." }

# WHOIS for an IP address
dns.execute(action: "whois", host: "1.1.1.1")
# => { query: "1.1.1.1", organization: "APNIC and Cloudflare DNS Resolver project",
#      country: "AU", raw: "..." }
```

## Integration with LLM Agents

DnsTool is especially useful when combined with WeatherTool and CurrentDateTimeTool for location-aware workflows:

```ruby
require 'ruby_llm'
require 'shared_tools/tools/dns_tool'
require 'shared_tools/tools/weather_tool'
require 'shared_tools/tools/current_date_time_tool'

chat = RubyLLM.chat.with_tools(
  SharedTools::Tools::DnsTool.new,
  SharedTools::Tools::WeatherTool.new,
  SharedTools::Tools::CurrentDateTimeTool.new
)

chat.ask(<<~PROMPT)
  1. Use current_date_time_tool to get today's date and day of week.
  2. Use dns_tool (action: external_ip) to get my public IP.
  3. Use dns_tool (action: ip_location) to find my city and country.
  4. Use weather_tool to fetch current weather and a 3-day forecast for that city.
  Report the current conditions and what to expect over the next three days,
  using the real date from the tool (not your training data).
PROMPT
```

## No API Key Required

All DnsTool actions use one of the following:

- Ruby's built-in `resolv` library for DNS queries
- Free public IP services (ipify.org, ifconfig.me, etc.) for `external_ip`
- The free [ip-api.com](http://ip-api.com) JSON API for `ip_location`
- Standard WHOIS protocol (TCP port 43) for `whois`

## See Also

- [WeatherTool](weather.md) - Combine with ip_location for local forecasts
- [CurrentDateTimeTool](index.md) - Use alongside DnsTool in location-aware prompts
