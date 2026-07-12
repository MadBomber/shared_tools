# frozen_string_literal: true

require "test_helper"

class GitLogToolTest < Minitest::Test
  def setup
    @repo = Dir.mktmpdir
    init_git_repo(@repo)
    File.write(File.join(@repo, "file.txt"), "v1\n")
    git_commit_all(@repo, "first commit")
    File.write(File.join(@repo, "file.txt"), "v2\n")
    git_commit_all(@repo, "second commit")

    @tool = SharedTools::Tools::Git::LogTool.new(repo_root: @repo)
  end

  def teardown
    FileUtils.rm_rf(@repo) if @repo && File.exist?(@repo)
  end

  def test_tool_name
    assert_equal "git_log", SharedTools::Tools::Git::LogTool.name
  end

  def test_shows_recent_commits
    result = @tool.execute

    assert_includes result, "first commit"
    assert_includes result, "second commit"
  end

  def test_respects_count
    result = @tool.execute(count: 1)

    assert_includes result, "second commit"
    refute_includes result, "first commit"
  end

  def test_no_commits_message
    empty_repo = Dir.mktmpdir
    init_git_repo(empty_repo)
    tool = SharedTools::Tools::Git::LogTool.new(repo_root: empty_repo)

    assert_equal "no commits", tool.execute
  ensure
    FileUtils.rm_rf(empty_repo) if empty_repo
  end
end
