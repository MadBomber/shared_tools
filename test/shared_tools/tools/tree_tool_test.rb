# frozen_string_literal: true

require "test_helper"

class TreeToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::TreeTool.new
    @dir = Dir.mktmpdir
    File.write(File.join(@dir, "alpha.rb"), "x")
    File.write(File.join(@dir, "beta.rb"), "x")
    File.write(File.join(@dir, ".hidden"), "x")
    Dir.mkdir(File.join(@dir, "sub"))
    File.write(File.join(@dir, "sub", "gamma.rb"), "x")
    Dir.mkdir(File.join(@dir, "node_modules"))
    File.write(File.join(@dir, "node_modules", "ignored.js"), "x")
  end

  def teardown
    FileUtils.rm_rf(@dir) if @dir && File.exist?(@dir)
  end

  def test_tool_name
    assert_equal "tree", SharedTools::Tools::TreeTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_lists_files_and_directories
    result = @tool.execute(path: @dir)

    assert_includes result, "alpha.rb"
    assert_includes result, "beta.rb"
    assert_includes result, "sub/"
  end

  def test_descends_into_subdirectories
    result = @tool.execute(path: @dir)

    assert_includes result, "gamma.rb"
  end

  def test_respects_max_depth
    result = @tool.execute(path: @dir, max_depth: 1)

    assert_includes result, "sub/"
    refute_includes result, "gamma.rb"
  end

  def test_hides_dotfiles_by_default
    result = @tool.execute(path: @dir)

    refute_includes result, ".hidden"
  end

  def test_shows_dotfiles_when_requested
    result = @tool.execute(path: @dir, show_hidden: true)

    assert_includes result, ".hidden"
  end

  def test_skips_ignored_directories
    result = @tool.execute(path: @dir)

    refute_includes result, "ignored.js"
  end

  def test_not_a_directory_returns_error
    result = @tool.execute(path: File.join(@dir, "alpha.rb"))

    assert result.is_a?(Hash)
    assert_includes result[:error], "not a directory"
  end

  def test_defaults_to_current_directory
    result = @tool.execute

    refute result.is_a?(Hash) && result.key?(:error)
  end
end
