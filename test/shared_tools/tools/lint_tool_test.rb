# frozen_string_literal: true

require "test_helper"

class LintToolTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @tool = SharedTools::Tools::LintTool.new(root: @dir)
    SharedTools.auto_execute(true)
  end

  def teardown
    FileUtils.rm_rf(@dir) if @dir && File.exist?(@dir)
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "lint", SharedTools::Tools::LintTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_unknown_linter_returns_error
    result = @tool.execute(linter: "bogus")

    assert result.is_a?(Hash)
    assert_includes result[:error], "unknown linter"
  end

  def test_detects_standard_when_config_present
    File.write(File.join(@dir, ".standard.yml"), "---\n")

    tool = SharedTools::Tools::LintTool.new(root: @dir)
    tool.stub(:run_in_project, ["", "", instance_status(0)]) do
      result = tool.execute
      assert_includes result, "LINT CLEAN"
    end
  end

  def test_defaults_to_rubocop
    tool = SharedTools::Tools::LintTool.new(root: @dir)
    tool.stub(:run_in_project, ["", "", instance_status(0)]) do
      result = tool.execute
      assert_includes result, "LINT CLEAN"
    end
  end

  def test_offenses_are_a_normal_result_not_an_error
    tool = SharedTools::Tools::LintTool.new(root: @dir)
    tool.stub(:run_in_project, ["offense found", "", instance_status(1)]) do
      result = tool.execute
      assert_includes result, "LINT: offenses found"
    end
  end

  def test_path_traversal_rejected
    result = @tool.execute(path: "../../etc/passwd")

    assert result.is_a?(Hash)
    assert_includes result[:error], "escapes"
  end

  def test_respects_auto_execute_false
    SharedTools.auto_execute(false)

    with_stdin_input("n") do
      result = @tool.execute
      assert result.is_a?(Hash)
      assert_includes result[:error], "declined"
    end
  end

  private

  def instance_status(code)
    Struct.new(:exitstatus) { def success? = exitstatus.zero? }.new(code)
  end
end
