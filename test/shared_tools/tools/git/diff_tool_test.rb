# frozen_string_literal: true

require "test_helper"

class GitDiffToolTest < Minitest::Test
  def setup
    @repo = Dir.mktmpdir
    init_git_repo(@repo)
    File.write(File.join(@repo, "file.txt"), "line1\n")
    git_commit_all(@repo, "initial commit")

    @tool = SharedTools::Tools::Git::DiffTool.new(repo_root: @repo)
  end

  def teardown
    FileUtils.rm_rf(@repo) if @repo && File.exist?(@repo)
  end

  def test_tool_name
    assert_equal "git_diff", SharedTools::Tools::Git::DiffTool.name
  end

  def test_no_changes
    assert_equal "no changes", @tool.execute
  end

  def test_unstaged_diff
    File.write(File.join(@repo, "file.txt"), "line1\nline2\n")

    result = @tool.execute

    assert_includes result, "line2"
  end

  def test_staged_diff_only_shown_with_staged_true
    File.write(File.join(@repo, "file.txt"), "line1\nline2\n")
    Dir.chdir(@repo) { system("git", "add", "-A", out: File::NULL, err: File::NULL) }

    assert_equal "no changes", @tool.execute(staged: false)
    assert_includes @tool.execute(staged: true), "line2"
  end

  def test_invalid_ref_rejected
    result = @tool.execute(ref: "--evil")

    assert result.is_a?(Hash)
    assert_includes result[:error], "invalid ref"
  end

  def test_path_traversal_rejected
    result = @tool.execute(path: "../../etc/passwd")

    assert result.is_a?(Hash)
    assert_includes result[:error], "escapes"
  end
end
