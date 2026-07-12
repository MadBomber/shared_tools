# frozen_string_literal: true

require "test_helper"

class GitShowToolTest < Minitest::Test
  def setup
    @repo = Dir.mktmpdir
    init_git_repo(@repo)
    File.write(File.join(@repo, "file.txt"), "hello\n")
    git_commit_all(@repo, "add file")

    @tool = SharedTools::Tools::Git::ShowTool.new(repo_root: @repo)
  end

  def teardown
    FileUtils.rm_rf(@repo) if @repo && File.exist?(@repo)
  end

  def test_tool_name
    assert_equal "git_show", SharedTools::Tools::Git::ShowTool.name
  end

  def test_shows_head_commit_by_default
    result = @tool.execute

    assert_includes result, "add file"
  end

  def test_shows_file_contents_at_ref
    result = @tool.execute(path: "file.txt")

    assert_equal "hello", result.strip
  end

  def test_invalid_ref_rejected
    result = @tool.execute(ref: "--evil")

    assert result.is_a?(Hash)
    assert_includes result[:error], "invalid ref"
  end
end
