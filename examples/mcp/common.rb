# frozen_string_literal: true
#
# Common setup for MCP client demo applications.
# Extends the base examples/common.rb with MCP-specific helpers.
#
# Usage — each MCP demo needs only:
#   require_relative 'common'
#
# Run:
#   bundle exec ruby -I lib -I examples examples/mcp/<name>_demo.rb

require_relative '../common'

# Returns true if npx is available in PATH.
def npx_available?
  system("which npx > /dev/null 2>&1")
end

# Extracts all https:// URLs from a string, stripping trailing punctuation.
def extract_urls(text)
  text.scan(/https?:\/\/\S+/)
      .map { |u| u.gsub(/[.,;:)\]"']+$/, '') }
      .uniq
end

# Opens chart URLs found in a response using the OS default browser.
# Checks the LLM response text first, then falls back to scanning tool
# result messages — the LLM often summarises charts without echoing the URL.
def open_chart_urls(response)
  urls = extract_urls(response.content.to_s)

  if urls.empty? && @chat.respond_to?(:messages)
    tool_text = @chat.messages
                     .select { |m| m.role.to_s == 'tool' }
                     .map    { |m| m.content.to_s }
                     .join("\n")
    urls = extract_urls(tool_text)
  end

  if urls.empty?
    puts "  (no chart URLs found)"
    return
  end

  urls.each do |url|
    puts "  Opening: #{url}"
    system('open', url)
  end
end

# Loads an MCP client by require path and reports its available tools.
# Accepts an optional block guard — skips loading if the block returns false.
# Returns true on success, false if skipped or failed.
def load_client(require_path, client_name, &check)
  return false unless check.nil? || check.call
  require require_path
  client = RubyLLM::MCP.clients[client_name]
  return false if client.nil?
  puts "  Loaded '#{client_name}' — #{client.tools.count} tools: #{client.tools.map(&:name).join(', ')}"
  true
rescue => e
  puts "  Error loading '#{client_name}': #{e.message}"
  false
end
