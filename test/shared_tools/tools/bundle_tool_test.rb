# frozen_string_literal: true

require "test_helper"

class BundleToolTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @tool = SharedTools::Tools::BundleTool.new(root: @dir)
    SharedTools.auto_execute(true)
  end

  def teardown
    FileUtils.rm_rf(@dir) if @dir && File.exist?(@dir)
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "bundle", SharedTools::Tools::BundleTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_unknown_action_returns_error
    result = @tool.execute(action: "bogus")

    assert result.is_a?(Hash)
    assert_includes result[:error], "unknown action"
  end

  def test_requires_gemfile
    result = @tool.execute(action: "check")

    assert result.is_a?(Hash)
    assert_includes result[:error], "Gemfile is required"
  end

  def test_add_requires_gem_name
    File.write(File.join(@dir, "Gemfile"), "source 'https://rubygems.org'\n")

    result = @tool.execute(action: "add")

    assert result.is_a?(Hash)
    assert_includes result[:error], "valid gem name"
  end

  def test_check_runs_when_gemfile_present
    File.write(File.join(@dir, "Gemfile"), "source 'https://rubygems.org'\n")

    result = @tool.execute(action: "check")

    assert_kind_of String, result
  end

  def test_respects_auto_execute_false
    SharedTools.auto_execute(false)
    File.write(File.join(@dir, "Gemfile"), "source 'https://rubygems.org'\n")

    with_stdin_input("n") do
      result = @tool.execute(action: "check")
      assert result.is_a?(Hash)
      assert_includes result[:error], "declined"
    end
  end
end
