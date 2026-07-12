# frozen_string_literal: true

require "test_helper"

class SearchCodebaseToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::SearchCodebaseTool.new
    @temp_dir = Dir.mktmpdir

    File.write(File.join(@temp_dir, "alpha.rb"),  "def hello; 'world'; end\ndef greet; 'hi'; end\n")
    File.write(File.join(@temp_dir, "beta.rb"),   "class Foo; def hello; end; end\n")
    File.write(File.join(@temp_dir, "gamma.txt"), "hello from a text file\n")
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_tool_name
    assert_equal "search_codebase", SharedTools::Tools::SearchCodebaseTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_finds_matches_across_files
    result = @tool.execute(pattern: "hello", path: @temp_dir)

    assert_kind_of Hash, result
    assert result[:count] >= 2, "Expected at least 2 matches, got #{result[:count]}"
    assert result[:matches].any? { |m| m.include?("hello") }
  end

  def test_returns_required_keys
    result = @tool.execute(pattern: "hello", path: @temp_dir)

    assert result.key?(:matches)
    assert result.key?(:count)
    assert result.key?(:truncated)
    assert result.key?(:tool)
  end

  def test_tool_key_is_ruby
    result = @tool.execute(pattern: "hello", path: @temp_dir)

    assert_equal "ruby", result[:tool]
  end

  def test_glob_filter_restricts_to_matching_files
    result = @tool.execute(pattern: "hello", path: @temp_dir, glob: "*.rb")

    assert result[:count] >= 1
    result[:matches].each do |line|
      assert line.match?(/\.rb:/), "Expected only .rb matches, got: #{line}"
    end
  end

  def test_glob_filter_excludes_other_files
    result_rb  = @tool.execute(pattern: "hello", path: @temp_dir, glob: "*.rb")
    result_txt = @tool.execute(pattern: "hello", path: @temp_dir, glob: "*.txt")

    assert result_rb[:matches].none?  { |m| m.include?("gamma.txt") }
    assert result_txt[:matches].none? { |m| m.include?(".rb:") }
  end

  def test_ignore_case
    result = @tool.execute(pattern: "HELLO", path: @temp_dir, ignore_case: true)

    assert result[:count] >= 2
  end

  def test_context_expands_match_into_a_block
    result = @tool.execute(pattern: "hello", path: @temp_dir, glob: "alpha.rb", context: 1)

    assert_equal 1, result[:count]
    assert_includes result[:matches].first, "greet"
  end

  def test_before_and_after_override_context
    result = @tool.execute(pattern: "hello", path: @temp_dir, glob: "alpha.rb", context: 5, after: 1)

    assert_includes result[:matches].first, "greet"
  end

  def test_max_results_limits_output
    result = @tool.execute(pattern: "hello", path: @temp_dir, max_results: 1)

    assert_equal 1, result[:count]
  end

  def test_truncated_flag_set_when_results_exceed_max
    result = @tool.execute(pattern: "hello", path: @temp_dir, max_results: 1)

    assert result[:truncated], "Expected truncated to be true"
  end

  def test_truncated_flag_false_when_results_within_max
    result = @tool.execute(pattern: "hello", path: @temp_dir, max_results: 100)

    refute result[:truncated]
  end

  def test_empty_pattern_returns_error
    result = @tool.execute(pattern: "")

    assert result.key?(:error)
    assert_includes result[:error], "cannot be empty"
  end

  def test_whitespace_only_pattern_returns_error
    result = @tool.execute(pattern: "   ")

    assert result.key?(:error)
    assert_includes result[:error], "cannot be empty"
  end

  def test_nonexistent_path_returns_error
    result = @tool.execute(pattern: "hello", path: "/nonexistent_dir_xyz_abc")

    assert result.key?(:error)
    assert_includes result[:error], "not found"
  end

  def test_no_matches_returns_empty_results
    result = @tool.execute(pattern: "zzz_no_match_zzz", path: @temp_dir)

    assert_equal 0, result[:count]
    assert_equal [], result[:matches]
    refute result[:truncated]
  end

  def test_max_results_capped_at_maximum
    result = @tool.execute(pattern: "hello", path: @temp_dir, max_results: 99999)

    assert result[:count] <= SharedTools::Tools::SearchCodebaseTool::MAX_RESULTS_CAP
  end

  def test_max_results_minimum_is_one
    result = @tool.execute(pattern: "hello", path: @temp_dir, max_results: 0)

    assert result[:count] >= 0
  end

  def test_invalid_regex_returns_error
    result = @tool.execute(pattern: "(", path: @temp_dir)

    assert result.key?(:error)
    assert_includes result[:error], "invalid regex"
  end

  def test_defaults_to_current_directory
    result = @tool.execute(pattern: "module SharedTools")

    assert_kind_of Hash, result
    refute result.key?(:error), "Unexpected error: #{result[:error]}"
  end
end
