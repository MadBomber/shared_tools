# frozen_string_literal: true

require "test_helper"

class ClipboardToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::ClipboardTool.new
    # Save the developer's clipboard so the tests don't destroy it.
    saved = @tool.execute(action: 'read')
    @saved_clipboard = saved[:content] if saved[:success]
  end

  def teardown
    @tool.execute(action: 'write', text: @saved_clipboard) if @saved_clipboard
  end

  def test_tool_name
    assert_equal 'clipboard', SharedTools::Tools::ClipboardTool.tool_name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_write_then_read_roundtrip
    text = "clipboard_test_#{Time.now.to_i}"
    write_result = @tool.execute(action: 'write', text: text)
    skip_unless_clipboard(write_result)

    read_result = @tool.execute(action: 'read')
    assert read_result[:success]
    assert_equal text, read_result[:content]
  rescue => e
    skip "Clipboard not available in this environment: #{e.message}"
  end

  def test_clear_empties_clipboard
    skip_unless_clipboard(@tool.execute(action: 'write', text: 'something'))
    clear_result = @tool.execute(action: 'clear')
    assert clear_result[:success]

    read_result = @tool.execute(action: 'read')
    assert_equal '', read_result[:content].to_s.strip
  rescue => e
    skip "Clipboard not available in this environment: #{e.message}"
  end

  def test_unknown_action_returns_error
    result = @tool.execute(action: 'explode')
    refute result[:success]
    assert result[:error]
    assert_includes result[:error], 'Unknown action'
  end

  def test_write_without_text_returns_error
    result = @tool.execute(action: 'write', text: nil)
    refute result[:success]
  rescue => e
    skip "Clipboard not available in this environment: #{e.message}"
  end

  private

  # The tool reports a missing clipboard program as { success: false }
  # rather than raising, so check the result instead of rescuing.
  def skip_unless_clipboard(result)
    skip "Clipboard not available in this environment: #{result[:error]}" unless result[:success]
  end
end
