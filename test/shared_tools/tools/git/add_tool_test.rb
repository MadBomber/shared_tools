# frozen_string_literal: true

require "test_helper"

class GitAddToolTest < Minitest::Test
  def setup
    @repo = Dir.mktmpdir
    init_git_repo(@repo)
    File.write(File.join(@repo, "committed.txt"), "hello\n")
    git_commit_all(@repo, "initial commit")

    @tool = SharedTools::Tools::Git::AddTool.new(repo_root: @repo)
    SharedTools.auto_execute(true)
  end

  def teardown
    FileUtils.rm_rf(@repo) if @repo && File.exist?(@repo)
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "git_add", SharedTools::Tools::Git::AddTool.name
  end

  def test_stages_specific_paths
    File.write(File.join(@repo, "new.txt"), "content\n")

    result = @tool.execute(paths: ["new.txt"])

    assert_includes result, "new.txt"
    status = git_status(@repo)
    assert_includes status, "A  new.txt"
  end

  def test_stages_all_changes
    File.write(File.join(@repo, "new.txt"), "content\n")

    result = @tool.execute(all: true)

    assert_equal "Staged all changes", result
    status = git_status(@repo)
    assert_includes status, "A  new.txt"
  end

  def test_no_paths_and_no_all_returns_error
    result = @tool.execute

    assert result.is_a?(Hash)
    assert_includes result[:error], "provide paths"
  end

  def test_respects_auto_execute_false
    SharedTools.auto_execute(false)
    File.write(File.join(@repo, "new.txt"), "content\n")

    with_stdin_input("n") do
      result = @tool.execute(paths: ["new.txt"])
      assert result.is_a?(Hash)
      assert_includes result[:error], "declined"
    end
  end

  private

  def git_status(dir)
    Dir.chdir(dir) { `git status --short` }
  end
end
