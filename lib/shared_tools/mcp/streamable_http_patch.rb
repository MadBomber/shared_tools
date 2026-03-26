# lib/shared_tools/mcp/streamable_http_patch.rb
#
# Patch: normalize mixed CRLF/LF line endings in SSE event buffers.
#
# Some MCP servers (e.g. Tavily) use \n to terminate the SSE data line and
# \r\n for the blank separator line, producing the sequence \n\r\n instead
# of the uniform \n\n or \r\n\r\n that the upstream parser expects.
# Without this patch, extract_sse_event never finds an event boundary for
# such responses and every tools/list request times out.
#
# This is a server-side standards violation (RFC 8895 requires consistent
# line endings within an event), but it is common enough in hosted MCP
# servers to warrant a defensive client-side fix.
#
# The patch normalises the accumulation buffer in-place before the separator
# check, which is safe because:
#   - the buffer is a mutable +String (prefixed with +)
#   - it is always written back via buffer.replace(rest) by the caller
#   - repeated normalisation of already-normalised content is a no-op

require "ruby_llm/mcp"

module RubyLLM
  module MCP
    module Native
      module Transports
        class StreamableHTTP
          private

          def extract_sse_event(buffer)
            buffer.gsub!("\r\n", "\n")
            buffer.gsub!("\r", "\n")
            return nil unless buffer.include?("\n\n")

            raw, rest = buffer.split("\n\n", 2)
            [parse_sse_event(raw), rest || ""]
          end
        end
      end
    end
  end
end
