# frozen_string_literal: true

require "test_helper"

class GitGrepToolTest < Minitest::Test
  def setup
    @repo = Dir.mktmpdir
    init_git_repo(@repo)
    File.write(File.join(@repo, "file.txt"), "hello world\ngoodbye\n")
    git_commit_all(@repo, "add file")

    @tool = SharedTools::Tools::Git::GrepTool.new(repo_root: @repo)
  end

  def teardown
    FileUtils.rm_rf(@repo) if @repo && File.exist?(@repo)
  end

  def test_tool_name
    assert_equal "git_grep", SharedTools::Tools::Git::GrepTool.name
  end

  def test_finds_matches
    result = @tool.execute(pattern: "hello")

    assert_includes result, "file.txt"
    assert_includes result, "hello world"
  end

  def test_no_matches
    result = @tool.execute(pattern: "zzz_nonexistent_zzz")

    assert_equal "no matches", result
  end

  def test_empty_pattern_returns_error
    result = @tool.execute(pattern: "")

    assert result.is_a?(Hash)
    assert_includes result[:error], "must not be empty"
  end

  def test_ignore_case
    result = @tool.execute(pattern: "HELLO", ignore_case: true)

    assert_includes result, "hello world"
  end
end
