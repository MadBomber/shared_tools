# frozen_string_literal: true

require "test_helper"

class GitBlameToolTest < Minitest::Test
  def setup
    @repo = Dir.mktmpdir
    init_git_repo(@repo)
    File.write(File.join(@repo, "file.txt"), "line1\nline2\nline3\n")
    git_commit_all(@repo, "add file")

    @tool = SharedTools::Tools::Git::BlameTool.new(repo_root: @repo)
  end

  def teardown
    FileUtils.rm_rf(@repo) if @repo && File.exist?(@repo)
  end

  def test_tool_name
    assert_equal "git_blame", SharedTools::Tools::Git::BlameTool.name
  end

  def test_blames_every_line
    result = @tool.execute(path: "file.txt")

    assert_equal 3, result.lines.size
  end

  def test_respects_line_range
    result = @tool.execute(path: "file.txt", start_line: 2, end_line: 2)

    assert_equal 1, result.lines.size
    assert_includes result, "line2"
  end

  def test_missing_file_returns_git_error
    result = @tool.execute(path: "nope.txt")

    assert result.is_a?(Hash)
    assert result.key?(:error)
  end
end
