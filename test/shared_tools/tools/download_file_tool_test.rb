# frozen_string_literal: true

require "test_helper"

class DownloadFileToolTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @tool = SharedTools::Tools::DownloadFileTool.new(root: @dir)
    SharedTools.auto_execute(true)
  end

  def teardown
    FileUtils.rm_rf(@dir) if @dir && File.exist?(@dir)
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "download_file", SharedTools::Tools::DownloadFileTool.name
  end

  def test_downloads_a_file
    result = @tool.execute(url: "https://example.com", path: "page.html")

    assert_includes result, "Downloaded"
    path = File.join(@dir, "page.html")
    assert File.exist?(path)
    assert File.size(path) > 0
  end

  def test_creates_missing_parent_directories
    @tool.execute(url: "https://example.com", path: "nested/deep/page.html")

    assert File.exist?(File.join(@dir, "nested", "deep", "page.html"))
  end

  def test_path_traversal_rejected
    result = @tool.execute(url: "https://example.com", path: "../../etc/passwd")

    assert result.is_a?(Hash)
    assert_includes result[:error], "escapes"
  end

  def test_blocks_ssrf_target
    result = @tool.execute(url: "http://127.0.0.1:1/", path: "x.html")

    assert result.is_a?(Hash)
    assert result.key?(:error)
  end

  def test_respects_auto_execute_false
    SharedTools.auto_execute(false)

    with_stdin_input("n") do
      result = @tool.execute(url: "https://example.com", path: "page.html")
      assert result.is_a?(Hash)
      assert_includes result[:error], "declined"
    end

    refute File.exist?(File.join(@dir, "page.html"))
  end
end
