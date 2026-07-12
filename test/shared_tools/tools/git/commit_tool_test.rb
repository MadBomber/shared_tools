# frozen_string_literal: true

require "test_helper"

class GitCommitToolTest < Minitest::Test
  def setup
    @repo = Dir.mktmpdir
    init_git_repo(@repo)
    File.write(File.join(@repo, "committed.txt"), "hello\n")
    git_commit_all(@repo, "initial commit")

    @tool = SharedTools::Tools::Git::CommitTool.new(repo_root: @repo)
    SharedTools.auto_execute(true)
  end

  def teardown
    FileUtils.rm_rf(@repo) if @repo && File.exist?(@repo)
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "git_commit", SharedTools::Tools::Git::CommitTool.name
  end

  def test_commits_staged_changes
    File.write(File.join(@repo, "new.txt"), "content\n")
    Dir.chdir(@repo) { system("git", "add", "-A", out: File::NULL, err: File::NULL) }

    result = @tool.execute(message: "Add new file")

    assert_includes result, "Add new file"
  end

  def test_commit_all_stages_tracked_files_first
    File.write(File.join(@repo, "committed.txt"), "changed\n")

    result = @tool.execute(message: "Update file", all: true)

    assert_includes result, "Update file"
  end

  def test_empty_message_returns_error
    result = @tool.execute(message: "")

    assert result.is_a?(Hash)
    assert_includes result[:error], "must not be empty"
  end

  def test_nothing_to_commit_returns_error
    result = @tool.execute(message: "nothing changed")

    assert result.is_a?(Hash)
    assert_includes result[:error], "nothing to commit"
  end

  def test_respects_auto_execute_false
    SharedTools.auto_execute(false)
    File.write(File.join(@repo, "new.txt"), "content\n")
    Dir.chdir(@repo) { system("git", "add", "-A", out: File::NULL, err: File::NULL) }

    with_stdin_input("n") do
      result = @tool.execute(message: "declined commit")
      assert result.is_a?(Hash)
      assert_includes result[:error], "declined"
    end
  end
end
