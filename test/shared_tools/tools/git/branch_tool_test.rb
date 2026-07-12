# frozen_string_literal: true

require "test_helper"

class GitBranchToolTest < Minitest::Test
  def setup
    @repo = Dir.mktmpdir
    init_git_repo(@repo)
    File.write(File.join(@repo, "file.txt"), "hello\n")
    git_commit_all(@repo, "initial commit")

    @tool = SharedTools::Tools::Git::BranchTool.new(repo_root: @repo)
  end

  def teardown
    FileUtils.rm_rf(@repo) if @repo && File.exist?(@repo)
  end

  def test_tool_name
    assert_equal "git_branch", SharedTools::Tools::Git::BranchTool.name
  end

  def test_lists_current_branch
    result = @tool.execute

    assert_includes result, "main"
    assert_includes result, "*"
  end

  def test_no_commits_message
    empty_repo = Dir.mktmpdir
    init_git_repo(empty_repo)
    tool = SharedTools::Tools::Git::BranchTool.new(repo_root: empty_repo)

    assert_equal "no branches yet (no commits?)", tool.execute
  ensure
    FileUtils.rm_rf(empty_repo) if empty_repo
  end
end
