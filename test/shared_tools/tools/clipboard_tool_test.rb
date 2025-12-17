# frozen_string_literal: true

require "test_helper"

class ClipboardToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::ClipboardTool.new
  end

  def test_tool_name
    assert_equal 'clipboard', SharedTools::Tools::ClipboardTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_can_instantiate_without_arguments
    tool = SharedTools::Tools::ClipboardTool.new
    assert_instance_of SharedTools::Tools::ClipboardTool, tool
  end

  def test_read_action_returns_clipboard_content
    # Write known content first
    @tool.execute(action: 'write', content: 'test clipboard content')

    result = @tool.execute(action: 'read')

    assert result[:success]
    assert_equal 'test clipboard content', result[:content]
    assert_equal 22, result[:length]
  end

  def test_write_action_sets_clipboard_content
    result = @tool.execute(action: 'write', content: 'hello from test')

    assert result[:success]
    assert_equal "Content written to clipboard", result[:message]
    assert_equal 15, result[:length]

    # Verify by reading back
    read_result = @tool.execute(action: 'read')
    assert_equal 'hello from test', read_result[:content]
  end

  def test_write_action_requires_content
    result = @tool.execute(action: 'write', content: nil)

    refute result[:success]
    assert_includes result[:error], "Content is required"
  end

  def test_write_action_rejects_empty_content
    result = @tool.execute(action: 'write', content: '')

    refute result[:success]
    assert_includes result[:error], "Content is required"
  end

  def test_clear_action_empties_clipboard
    # First write something
    @tool.execute(action: 'write', content: 'some content')

    # Clear it
    result = @tool.execute(action: 'clear')

    assert result[:success]
    assert_equal "Clipboard cleared", result[:message]

    # Verify clipboard is empty
    read_result = @tool.execute(action: 'read')
    assert_equal '', read_result[:content]
  end

  def test_unknown_action_returns_error
    result = @tool.execute(action: 'unknown')

    refute result[:success]
    assert_includes result[:error], "Unknown action: unknown"
    assert_includes result[:error], "Valid actions are: read, write, clear"
  end

  def test_action_is_case_insensitive
    @tool.execute(action: 'write', content: 'case test')

    result_lower = @tool.execute(action: 'read')
    assert result_lower[:success]

    result_upper = @tool.execute(action: 'READ')
    assert result_upper[:success]

    result_mixed = @tool.execute(action: 'Read')
    assert result_mixed[:success]
  end

  def test_handles_multiline_content
    multiline = "Line 1\nLine 2\nLine 3"
    @tool.execute(action: 'write', content: multiline)

    result = @tool.execute(action: 'read')

    assert result[:success]
    assert_equal multiline, result[:content]
  end

  def test_handles_unicode_content
    unicode = "Hello 世界 🌍 émoji"
    @tool.execute(action: 'write', content: unicode)

    result = @tool.execute(action: 'read')

    assert result[:success]
    assert_equal unicode, result[:content]
  end

  def test_handles_special_characters
    special = "Special chars: $`\"'\\!@#%^&*()"
    @tool.execute(action: 'write', content: special)

    result = @tool.execute(action: 'read')

    assert result[:success]
    assert_equal special, result[:content]
  end

  def test_platform_detection
    # This tests the private method indirectly through successful operations
    result = @tool.execute(action: 'write', content: 'platform test')

    assert result[:success], "Should work on the current platform"
  end
end
