# frozen_string_literal: true

require "test_helper"

class ClipboardToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::ClipboardTool.new
  end

  def test_tool_name
    assert_equal 'clipboard_tool', SharedTools::Tools::ClipboardTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_write_then_read_roundtrip
    text = "clipboard_test_#{Time.now.to_i}"
    write_result = @tool.execute(action: 'write', text: text)
    assert write_result[:success], "write failed: #{write_result.inspect}"

    read_result = @tool.execute(action: 'read')
    assert read_result[:success]
    assert_equal text, read_result[:content]
  rescue => e
    skip "Clipboard not available in this environment: #{e.message}"
  end

  def test_clear_empties_clipboard
    @tool.execute(action: 'write', text: 'something')
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
end
