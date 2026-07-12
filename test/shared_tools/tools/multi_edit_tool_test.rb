# frozen_string_literal: true

require "test_helper"

class MultiEditToolTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @path = File.join(@dir, "file.txt")
    File.write(@path, "hello world\nfoo bar\nfoo bar\n")

    @tool = SharedTools::Tools::MultiEditTool.new(root: @dir)
    SharedTools.auto_execute(true)
  end

  def teardown
    FileUtils.rm_rf(@dir) if @dir && File.exist?(@dir)
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "multi_edit", SharedTools::Tools::MultiEditTool.name
  end

  def test_applies_sequential_edits
    result = @tool.execute(path: "file.txt", edits: [
      { old_string: "hello world", new_string: "goodbye world" },
      { old_string: "foo bar", new_string: "baz qux", replace_all: true }
    ])

    assert_includes result, "Applied 2 edits"
    assert_equal "goodbye world\nbaz qux\nbaz qux\n", File.read(@path)
  end

  def test_later_edit_sees_result_of_earlier_edit
    result = @tool.execute(path: "file.txt", edits: [
      { old_string: "hello", new_string: "HELLO" },
      { old_string: "HELLO world", new_string: "greeting" }
    ])

    assert_includes result, "Applied 2 edits"
    assert_includes File.read(@path), "greeting"
  end

  def test_ambiguous_match_without_replace_all_fails_and_writes_nothing
    original = File.read(@path)

    result = @tool.execute(path: "file.txt", edits: [{ old_string: "foo bar", new_string: "x" }])

    assert result.is_a?(Hash)
    assert_includes result[:error], "ambiguous"
    assert_equal original, File.read(@path)
  end

  def test_missing_old_string_fails_and_writes_nothing
    original = File.read(@path)

    result = @tool.execute(path: "file.txt", edits: [{ old_string: "nope", new_string: "x" }])

    assert result.is_a?(Hash)
    assert_includes result[:error], "not found"
    assert_equal original, File.read(@path)
  end

  def test_partial_failure_in_sequence_writes_nothing
    original = File.read(@path)

    result = @tool.execute(path: "file.txt", edits: [
      { old_string: "hello world", new_string: "greeting" },
      { old_string: "nonexistent", new_string: "x" }
    ])

    assert result.is_a?(Hash)
    assert_equal original, File.read(@path)
  end

  def test_empty_edits_array_returns_error
    result = @tool.execute(path: "file.txt", edits: [])

    assert result.is_a?(Hash)
    assert_includes result[:error], "non-empty array"
  end

  def test_identical_old_and_new_string_fails
    result = @tool.execute(path: "file.txt", edits: [{ old_string: "hello world", new_string: "hello world" }])

    assert result.is_a?(Hash)
    assert_includes result[:error], "identical"
  end

  def test_missing_file_returns_error
    result = @tool.execute(path: "nope.txt", edits: [{ old_string: "a", new_string: "b" }])

    assert result.is_a?(Hash)
    assert_includes result[:error], "not a file"
  end

  def test_path_traversal_rejected
    result = @tool.execute(path: "../../etc/passwd", edits: [{ old_string: "a", new_string: "b" }])

    assert result.is_a?(Hash)
    assert_includes result[:error], "escapes"
  end

  def test_respects_auto_execute_false
    SharedTools.auto_execute(false)

    with_stdin_input("n") do
      result = @tool.execute(path: "file.txt", edits: [{ old_string: "hello world", new_string: "x" }])
      assert result.is_a?(Hash)
      assert_includes result[:error], "declined"
    end

    assert_equal "hello world\nfoo bar\nfoo bar\n", File.read(@path)
  end
end
