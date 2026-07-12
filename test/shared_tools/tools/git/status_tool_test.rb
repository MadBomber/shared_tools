# frozen_string_literal: true

require "test_helper"

class GitStatusToolTest < Minitest::Test
  def setup
    @repo = Dir.mktmpdir
    init_git_repo(@repo)
    File.write(File.join(@repo, "committed.txt"), "hello\n")
    git_commit_all(@repo, "initial commit")

    @tool = SharedTools::Tools::Git::StatusTool.new(repo_root: @repo)
  end

  def teardown
    FileUtils.rm_rf(@repo) if @repo && File.exist?(@repo)
  end

  def test_tool_name
    assert_equal "git_status", SharedTools::Tools::Git::StatusTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_clean_working_tree
    assert_equal "working tree clean", @tool.execute
  end

  def test_reports_untracked_files
    File.write(File.join(@repo, "new_file.txt"), "content\n")

    result = @tool.execute

    assert_includes result, "new_file.txt"
  end

  def test_reports_modified_files
    File.write(File.join(@repo, "committed.txt"), "changed\n")

    result = @tool.execute

    assert_includes result, "committed.txt"
  end

  def test_not_a_git_repo_returns_error
    non_repo = Dir.mktmpdir
    tool = SharedTools::Tools::Git::StatusTool.new(repo_root: non_repo)

    result = tool.execute

    assert result.is_a?(Hash)
    assert result.key?(:error)
  ensure
    FileUtils.rm_rf(non_repo) if non_repo
  end
end
