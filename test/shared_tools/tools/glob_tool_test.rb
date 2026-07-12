# frozen_string_literal: true

require "test_helper"

class GlobToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::GlobTool.new
    @dir = Dir.mktmpdir
    File.write(File.join(@dir, "alpha.rb"), "x")
    File.write(File.join(@dir, "beta.rb"), "x")
    File.write(File.join(@dir, "gamma.txt"), "x")
    Dir.mkdir(File.join(@dir, "sub"))
    File.write(File.join(@dir, "sub", "delta.rb"), "x")
  end

  def teardown
    FileUtils.rm_rf(@dir) if @dir && File.exist?(@dir)
  end

  def test_tool_name
    assert_equal "glob", SharedTools::Tools::GlobTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_finds_matches_at_top_level
    result = @tool.execute(pattern: "*.rb", base: @dir)

    assert_includes result, "alpha.rb"
    assert_includes result, "beta.rb"
    refute_includes result, "sub/delta.rb"
  end

  def test_recursive_glob_finds_nested_matches
    result = @tool.execute(pattern: "**/*.rb", base: @dir)

    assert_includes result, "alpha.rb"
    assert_includes result, "sub/delta.rb"
  end

  def test_results_are_sorted
    result = @tool.execute(pattern: "*.rb", base: @dir)

    lines = result.lines.drop(1).map(&:strip)
    assert_equal lines.sort, lines
  end

  def test_no_matches
    result = @tool.execute(pattern: "*.nonexistent", base: @dir)

    assert_includes result, "0 matches"
  end

  def test_empty_pattern_returns_error
    result = @tool.execute(pattern: "", base: @dir)

    assert result.is_a?(Hash)
    assert_includes result[:error], "must be provided"
  end

  def test_pattern_with_dotdot_rejected
    result = @tool.execute(pattern: "../*", base: @dir)

    assert result.is_a?(Hash)
    assert_includes result[:error], "may not contain"
  end

  def test_base_not_a_directory_returns_error
    result = @tool.execute(pattern: "*.rb", base: File.join(@dir, "alpha.rb"))

    assert result.is_a?(Hash)
    assert_includes result[:error], "not a directory"
  end

  def test_defaults_base_to_current_directory
    result = @tool.execute(pattern: "*.gemspec")

    refute result.is_a?(Hash) && result.key?(:error)
  end
end
