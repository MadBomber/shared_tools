# frozen_string_literal: true

require "test_helper"

class ReplaceInFilesToolTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    File.write(File.join(@dir, "a.rb"), "FooBar\nFooBar again\n")
    File.write(File.join(@dir, "b.txt"), "nothing here\n")
    @tool = SharedTools::Tools::ReplaceInFilesTool.new(root: @dir)
    SharedTools.auto_execute(true)
  end

  def teardown
    FileUtils.rm_rf(@dir) if @dir && File.exist?(@dir)
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "replace_in_files", SharedTools::Tools::ReplaceInFilesTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_replaces_literal_text_across_files
    result = @tool.execute(pattern: "FooBar", replacement: "BazQux")

    assert_includes result, "Replaced 2 occurrences across 1 file"
    assert_equal "BazQux\nBazQux again\n", File.read(File.join(@dir, "a.rb"))
  end

  def test_dry_run_does_not_write
    result = @tool.execute(pattern: "FooBar", replacement: "BazQux", dry_run: true)

    assert_includes result, "Would replace"
    assert_equal "FooBar\nFooBar again\n", File.read(File.join(@dir, "a.rb"))
  end

  def test_glob_restricts_scope
    result = @tool.execute(pattern: "nothing", replacement: "something", glob: "*.rb")

    assert_includes result, "0 occurrences"
    assert_equal "nothing here\n", File.read(File.join(@dir, "b.txt"))
  end

  def test_regex_with_backreferences
    File.write(File.join(@dir, "c.rb"), "version 1.2\n")

    result = @tool.execute(pattern: 'version (\d+)\.(\d+)', replacement: 'v\1_\2', regex: true, glob: "c.rb")

    assert_includes result, "Replaced 1 occurrence"
    assert_equal "v1_2\n", File.read(File.join(@dir, "c.rb"))
  end

  def test_ignore_case
    result = @tool.execute(pattern: "foobar", replacement: "X", ignore_case: true)

    assert_includes result, "Replaced 2 occurrences"
  end

  def test_empty_pattern_returns_error
    result = @tool.execute(pattern: "")

    assert result.is_a?(Hash)
    assert_includes result[:error], "must not be empty"
  end

  def test_no_matches
    result = @tool.execute(pattern: "zzz_nomatch_zzz", replacement: "x")

    assert_includes result, "0 occurrences"
  end

  def test_respects_auto_execute_false
    SharedTools.auto_execute(false)

    with_stdin_input("n") do
      result = @tool.execute(pattern: "FooBar", replacement: "BazQux")
      assert result.is_a?(Hash)
      assert_includes result[:error], "declined"
    end

    assert_equal "FooBar\nFooBar again\n", File.read(File.join(@dir, "a.rb"))
  end

  def test_dry_run_does_not_require_authorization
    SharedTools.auto_execute(false)

    result = @tool.execute(pattern: "FooBar", replacement: "BazQux", dry_run: true)

    assert_includes result, "Would replace"
  end
end
