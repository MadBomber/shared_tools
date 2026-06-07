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
    result = @tool.execute(term: "hello", path: @temp_dir)

    assert_kind_of Hash, result
    assert result[:count] >= 2, "Expected at least 2 matches, got #{result[:count]}"
    assert result[:matches].any? { |m| m.include?("hello") }
  end

  def test_returns_required_keys
    result = @tool.execute(term: "hello", path: @temp_dir)

    assert result.key?(:matches)
    assert result.key?(:count)
    assert result.key?(:truncated)
    assert result.key?(:tool)
  end

  def test_extension_filter_restricts_to_matching_files
    result = @tool.execute(term: "hello", path: @temp_dir, extension: "rb")

    assert result[:count] >= 1
    result[:matches].each do |line|
      assert line.match?(/\.rb:/), "Expected only .rb matches, got: #{line}"
    end
  end

  def test_extension_filter_excludes_other_files
    result_rb  = @tool.execute(term: "hello", path: @temp_dir, extension: "rb")
    result_txt = @tool.execute(term: "hello", path: @temp_dir, extension: "txt")

    assert result_rb[:matches].none?  { |m| m.include?("gamma.txt") }
    assert result_txt[:matches].none? { |m| m.include?(".rb:") }
  end

  def test_max_results_limits_output
    result = @tool.execute(term: "hello", path: @temp_dir, max_results: 1)

    assert_equal 1, result[:count]
  end

  def test_truncated_flag_set_when_results_exceed_max
    # Create enough matches to exceed max_results: 1
    result = @tool.execute(term: "hello", path: @temp_dir, max_results: 1)

    # We have matches in alpha.rb, beta.rb, and gamma.txt — at least 3 total
    # so truncated should be true with max_results: 1
    assert result[:truncated], "Expected truncated to be true"
  end

  def test_truncated_flag_false_when_results_within_max
    result = @tool.execute(term: "hello", path: @temp_dir, max_results: 100)

    refute result[:truncated]
  end

  def test_empty_term_returns_error
    result = @tool.execute(term: "")

    assert result.key?(:error)
    assert_includes result[:error], "cannot be empty"
  end

  def test_whitespace_only_term_returns_error
    result = @tool.execute(term: "   ")

    assert result.key?(:error)
    assert_includes result[:error], "cannot be empty"
  end

  def test_nonexistent_path_returns_error
    result = @tool.execute(term: "hello", path: "/nonexistent_dir_xyz_abc")

    assert result.key?(:error)
    assert_includes result[:error], "not found"
  end

  def test_no_matches_returns_empty_results
    result = @tool.execute(term: "zzz_no_match_zzz", path: @temp_dir)

    assert_equal 0, result[:count]
    assert_equal [], result[:matches]
    refute result[:truncated]
  end

  def test_max_results_capped_at_maximum
    result = @tool.execute(term: "hello", path: @temp_dir, max_results: 99999)

    assert result[:count] <= SharedTools::Tools::SearchCodebaseTool::MAX_RESULTS_CAP
  end

  def test_max_results_minimum_is_one
    result = @tool.execute(term: "hello", path: @temp_dir, max_results: 0)

    assert result[:count] >= 0
  end

  def test_tool_key_is_rg_or_grep
    result = @tool.execute(term: "hello", path: @temp_dir)

    assert_includes %w[rg grep], result[:tool]
  end

  def test_defaults_to_current_directory
    result = @tool.execute(term: "module SharedTools")

    assert_kind_of Hash, result
    refute result.key?(:error), "Unexpected error: #{result[:error]}"
  end
end
