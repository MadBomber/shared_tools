# frozen_string_literal: true

require "test_helper"
require "ruby_llm/mcp"
require "shared_tools/mcp/streamable_http_patch"

# Tests for the SSE line-ending normalization monkey-patch applied to
# RubyLLM::MCP::Native::Transports::StreamableHTTP#extract_sse_event.
#
# The patch fixes a server-side RFC 8895 violation where some hosted MCP
# servers (e.g. Tavily) terminate the data line with \n but use \r\n for the
# blank separator, yielding \n\r\n instead of the uniform \n\n or \r\n\r\n
# that the original parser requires. Without the patch the event boundary is
# never found and every tools/list request times out after 30 seconds.
#
# We use StreamableHTTP.allocate to obtain an instance without calling the
# complex constructor (which requires a coordinator, url, etc.), then define a
# lightweight parse_sse_event stub on that instance so we can test the
# normalization and splitting logic in complete isolation.
class StreamableHttpPatchTest < Minitest::Test

  TRANSPORT = RubyLLM::MCP::Native::Transports::StreamableHTTP

  # Build an instance that bypasses the real constructor and provides a
  # predictable parse_sse_event so tests only verify buffer normalization.
  def setup
    @instance = TRANSPORT.allocate

    # Stub parse_sse_event to return a hash containing the raw event text.
    # This lets us assert on what the patch passed to it.
    @instance.define_singleton_method(:parse_sse_event) do |raw|
      { raw: raw }
    end
  end

  # Wrap in a mutable String — the real buffer is always mutable (built by
  # on_response_body_chunk), and gsub! requires it. frozen_string_literal: true
  # at the top of this file would otherwise freeze bare string literals.
  def extract(str)
    @instance.send(:extract_sse_event, +str)
  end

  # -------------------------------------------------------------------------
  # Returns nil when no event boundary is present
  # -------------------------------------------------------------------------

  def test_returns_nil_when_buffer_is_empty
    assert_nil extract("")
  end

  def test_returns_nil_when_buffer_has_no_event_boundary
    assert_nil extract("data: hello")
  end

  def test_returns_nil_for_single_newline_only
    assert_nil extract("\n")
  end

  # -------------------------------------------------------------------------
  # Uniform \n\n — standard LF-only events
  # -------------------------------------------------------------------------

  def test_extracts_event_with_uniform_lf_separator
    buffer = "data: hello\n\n"
    event, rest = extract(buffer)

    assert_equal "data: hello", event[:raw]
    assert_equal "", rest
  end

  def test_rest_contains_content_after_first_event_lf
    buffer = "data: first\n\ndata: second\n\n"
    event, rest = extract(buffer)

    assert_equal "data: first", event[:raw]
    assert_equal "data: second\n\n", rest
  end

  # -------------------------------------------------------------------------
  # Uniform \r\n\r\n — standard CRLF events (normalised to LF)
  # -------------------------------------------------------------------------

  def test_extracts_event_with_uniform_crlf_separator
    buffer = "data: hello\r\n\r\n"
    event, rest = extract(buffer)

    # After normalisation: "data: hello\n\n" — the data line itself loses \r
    assert_equal "data: hello", event[:raw]
    assert_equal "", rest
  end

  def test_rest_contains_content_after_first_event_crlf
    buffer = "data: first\r\n\r\ndata: second\r\n\r\n"
    event, rest = extract(buffer)

    assert_equal "data: first", event[:raw]
    # rest is normalised too
    assert_equal "data: second\n\n", rest
  end

  # -------------------------------------------------------------------------
  # Mixed \n\r\n — the Tavily / RFC violation case
  # -------------------------------------------------------------------------

  def test_extracts_event_with_mixed_lf_crlf_separator
    # Data line ends with \n; blank separator is \r\n → produces \n\r\n
    buffer = "data: hello\n\r\n"
    event, rest = extract(buffer)

    assert_equal "data: hello", event[:raw]
    assert_equal "", rest
  end

  def test_extracts_multiline_event_with_mixed_line_endings
    buffer = "event: tools/list\ndata: {\"result\":true}\n\r\n"
    event, rest = extract(buffer)

    assert_equal "event: tools/list\ndata: {\"result\":true}", event[:raw]
    assert_equal "", rest
  end

  def test_rest_contains_content_after_mixed_ending_event
    buffer = "data: first\n\r\ndata: second\n\n"
    event, rest = extract(buffer)

    assert_equal "data: first", event[:raw]
    assert_equal "data: second\n\n", rest
  end

  # -------------------------------------------------------------------------
  # Standalone \r — bare CR normalised to LF
  # -------------------------------------------------------------------------

  def test_extracts_event_with_bare_cr_separator
    buffer = "data: hello\r\r"
    event, rest = extract(buffer)

    assert_equal "data: hello", event[:raw]
    assert_equal "", rest
  end

  # -------------------------------------------------------------------------
  # Idempotency — normalising already-normalised content is a no-op
  # -------------------------------------------------------------------------

  def test_normalisation_is_idempotent
    buffer = "data: hello\n\n"
    first_event, _  = extract(buffer.dup)
    second_event, _ = extract(buffer.dup)

    assert_equal first_event, second_event
  end

  def test_repeated_extraction_on_same_buffer_object_is_safe
    buffer = +"data: hello\n\r\n"    # mutable string (prefixed +)
    event1, _ = extract(buffer)
    # buffer has been normalised in-place; extracting again on a re-normalised
    # buffer should still find no boundary (content was consumed as rest = "")
    assert_equal "data: hello", event1[:raw]
  end

  # -------------------------------------------------------------------------
  # rest is never nil — always a String
  # -------------------------------------------------------------------------

  def test_rest_is_empty_string_not_nil_when_nothing_follows
    _, rest = extract("data: hello\n\n")
    assert_instance_of String, rest
    assert_equal "", rest
  end

  def test_rest_is_empty_string_for_crlf_event_with_no_trailer
    _, rest = extract("data: hello\r\n\r\n")
    assert_instance_of String, rest
    assert_equal "", rest
  end

end
