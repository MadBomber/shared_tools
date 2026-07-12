# frozen_string_literal: true

require "test_helper"

class ApplyPatchToolTest < Minitest::Test
  PATCH = <<~PATCH
    --- a/file.txt
    +++ b/file.txt
    @@ -1,3 +1,3 @@
     line1
    -line2
    +LINE_TWO
     line3
  PATCH

  def setup
    @dir = Dir.mktmpdir
    @path = File.join(@dir, "file.txt")
    File.write(@path, "line1\nline2\nline3\n")

    @tool = SharedTools::Tools::ApplyPatchTool.new(root: @dir)
    SharedTools.auto_execute(true)
  end

  def teardown
    FileUtils.rm_rf(@dir) if @dir && File.exist?(@dir)
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "apply_patch", SharedTools::Tools::ApplyPatchTool.name
  end

  def test_applies_patch
    result = @tool.execute(patch: PATCH)

    assert_includes result, "file.txt"
    assert_equal "line1\nLINE_TWO\nline3\n", File.read(@path)
  end

  def test_check_true_does_not_write
    result = @tool.execute(patch: PATCH, check: true)

    assert_includes result, "dry run"
    assert_equal "line1\nline2\nline3\n", File.read(@path)
  end

  def test_empty_patch_returns_error
    result = @tool.execute(patch: "")

    assert result.is_a?(Hash)
    assert_includes result[:error], "empty"
  end

  def test_patch_that_does_not_apply_returns_error
    bad_patch = <<~PATCH
      --- a/file.txt
      +++ b/file.txt
      @@ -1,3 +1,3 @@
       line1
      -does_not_exist
      +LINE_TWO
       line3
    PATCH

    result = @tool.execute(patch: bad_patch)

    assert result.is_a?(Hash)
    assert_includes result[:error], "does not apply cleanly"
  end

  def test_path_traversal_rejected
    evil_patch = <<~PATCH
      --- a/../../../etc/passwd
      +++ b/../../../etc/passwd
      @@ -1 +1 @@
      -x
      +y
    PATCH

    result = @tool.execute(patch: evil_patch)

    assert result.is_a?(Hash)
    assert_includes result[:error], "escapes root"
  end

  def test_respects_auto_execute_false
    SharedTools.auto_execute(false)

    with_stdin_input("n") do
      result = @tool.execute(patch: PATCH)
      assert result.is_a?(Hash)
      assert_includes result[:error], "declined"
    end

    assert_equal "line1\nline2\nline3\n", File.read(@path)
  end
end
