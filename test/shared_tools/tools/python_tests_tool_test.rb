# frozen_string_literal: true

require "test_helper"

class PythonTestsToolTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
    @tool = SharedTools::Tools::PythonTestsTool.new(root: @dir)
    SharedTools.auto_execute(true)
  end

  def teardown
    FileUtils.rm_rf(@dir) if @dir && File.exist?(@dir)
    SharedTools.auto_execute(false)
  end

  def test_tool_name
    assert_equal "python_tests", SharedTools::Tools::PythonTestsTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_unknown_framework_returns_error
    result = @tool.execute(framework: "bogus")

    assert result.is_a?(Hash)
    assert_includes result[:error], "unknown framework"
  end

  def test_defaults_to_pytest
    skip "pytest not installed" unless system("which pytest", out: File::NULL, err: File::NULL)

    File.write(File.join(@dir, "test_sample.py"), "def test_ok():\n    assert True\n")
    result = @tool.execute

    assert_includes result, "TESTS PASSED"
  end

  def test_unittest_framework
    skip "python3 not installed" unless system("which python3", out: File::NULL, err: File::NULL)

    File.write(File.join(@dir, "test_sample.py"), <<~PY)
      import unittest

      class SampleTest(unittest.TestCase):
          def test_ok(self):
              self.assertTrue(True)
    PY

    result = @tool.execute(framework: "unittest")

    assert_includes result, "TESTS PASSED"
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
end
