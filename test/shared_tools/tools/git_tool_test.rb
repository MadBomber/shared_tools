# frozen_string_literal: true

require "test_helper"

class GitToolTest < Minitest::Test
  def setup
    @repo = Dir.mktmpdir
    init_git_repo(@repo)
    File.write(File.join(@repo, "file.txt"), "hello\n")
    git_commit_all(@repo, "initial commit")

    @tool = SharedTools::Tools::GitTool.new(repo_root: @repo)
    SharedTools.auto_execute(true)
  end

  def teardown
    FileUtils.rm_rf(@repo) if @repo && File.exist?(@repo)
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "git_tool", SharedTools::Tools::GitTool.name
  end

  def test_status_action
    assert_equal "working tree clean", @tool.execute(action: "status")
  end

  def test_log_action
    result = @tool.execute(action: "log", count: 1)

    assert_includes result, "initial commit"
  end

  def test_branch_action
    result = @tool.execute(action: "branch")

    assert_includes result, "main"
  end

  def test_commit_action_requires_message
    File.write(File.join(@repo, "file.txt"), "changed\n")

    result = @tool.execute(action: "commit")

    assert result.is_a?(Hash)
    assert_includes result[:error], "message param is required"
  end

  def test_commit_action_with_message
    File.write(File.join(@repo, "file.txt"), "changed\n")

    result = @tool.execute(action: "commit", message: "Update file", all: true)

    assert_includes result, "Update file"
  end

  def test_unsupported_action
    result = @tool.execute(action: "bogus")

    assert result.is_a?(Hash)
    assert_includes result[:error], "Unsupported action"
  end
end
