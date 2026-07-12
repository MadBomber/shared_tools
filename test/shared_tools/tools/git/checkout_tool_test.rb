# frozen_string_literal: true

require "test_helper"

class GitCheckoutToolTest < Minitest::Test
  def setup
    @repo = Dir.mktmpdir
    init_git_repo(@repo)
    File.write(File.join(@repo, "file.txt"), "hello\n")
    git_commit_all(@repo, "initial commit")

    @tool = SharedTools::Tools::Git::CheckoutTool.new(repo_root: @repo)
    SharedTools.auto_execute(true)
  end

  def teardown
    FileUtils.rm_rf(@repo) if @repo && File.exist?(@repo)
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "git_checkout", SharedTools::Tools::Git::CheckoutTool.name
  end

  def test_creates_and_switches_to_new_branch
    @tool.execute(ref: "feature/x", create: true)

    branch = Dir.chdir(@repo) { `git rev-parse --abbrev-ref HEAD`.strip }
    assert_equal "feature/x", branch
  end

  def test_switches_to_existing_branch
    Dir.chdir(@repo) { system("git", "branch", "other", out: File::NULL, err: File::NULL) }

    @tool.execute(ref: "other")

    branch = Dir.chdir(@repo) { `git rev-parse --abbrev-ref HEAD`.strip }
    assert_equal "other", branch
  end

  def test_invalid_ref_rejected
    result = @tool.execute(ref: "--evil")

    assert result.is_a?(Hash)
    assert_includes result[:error], "invalid ref"
  end

  def test_respects_auto_execute_false
    SharedTools.auto_execute(false)

    with_stdin_input("n") do
      result = @tool.execute(ref: "feature/x", create: true)
      assert result.is_a?(Hash)
      assert_includes result[:error], "declined"
    end
  end
end
