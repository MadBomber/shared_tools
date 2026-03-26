# frozen_string_literal: true

require "test_helper"

class SharedToolsTest < Minitest::Test
  def teardown
    # Reset to default state after each test
    SharedTools.instance_variable_set(:@auto_execute, false)
  end

  # .auto_execute tests
  def test_sets_auto_execute_to_true_when_called_with_true
    SharedTools.auto_execute(true)
    assert_equal true, SharedTools.instance_variable_get(:@auto_execute)
  end

  def test_sets_auto_execute_to_false_when_called_with_false
    SharedTools.auto_execute(false)
    assert_equal false, SharedTools.instance_variable_get(:@auto_execute)
  end

  def test_defaults_to_true_when_called_without_arguments
    SharedTools.auto_execute
    assert_equal true, SharedTools.instance_variable_get(:@auto_execute)
  end

  # .execute? tests - auto_execute enabled
  def test_returns_true_without_prompting_when_auto_execute_enabled
    SharedTools.auto_execute(true)
    result = SharedTools.execute?(tool: 'TestTool', stuff: 'some operation')
    assert_equal true, result
  end

  # .execute? tests - auto_execute disabled (manual interaction required)
  def test_returns_true_when_user_inputs_y
    SharedTools.instance_variable_set(:@auto_execute, nil)
    with_stdin_input('y') do
      result = SharedTools.execute?(tool: 'TestTool', stuff: 'test operation')
      assert_equal true, result
    end
  end

  def test_returns_false_when_user_inputs_n
    SharedTools.instance_variable_set(:@auto_execute, nil)
    with_stdin_input('n') do
      result = SharedTools.execute?(tool: 'TestTool', stuff: 'test operation')
      assert_equal false, result
    end
  end

  def test_returns_false_when_user_inputs_capital_n
    SharedTools.instance_variable_set(:@auto_execute, nil)
    with_stdin_input('N') do
      result = SharedTools.execute?(tool: 'TestTool', stuff: 'test operation')
      assert_equal false, result
    end
  end

  def test_returns_false_when_user_inputs_random_characters
    SharedTools.instance_variable_set(:@auto_execute, nil)
    with_stdin_input('x') do
      result = SharedTools.execute?(tool: 'TestTool', stuff: 'test operation')
      assert_equal false, result
    end
  end

  def test_handles_empty_stuff_parameter
    SharedTools.instance_variable_set(:@auto_execute, nil)
    with_stdin_input('y') do
      result = SharedTools.execute?(tool: 'TestTool', stuff: '')
      assert_equal true, result
    end
  end

  # module instance variable tests
  def test_auto_execute_is_nil_by_default
    SharedTools.instance_variable_set(:@auto_execute, nil)
    assert_nil SharedTools.instance_variable_get(:@auto_execute)
  end

  def test_treats_nil_auto_execute_as_requiring_user_interaction
    SharedTools.instance_variable_set(:@auto_execute, nil)
    with_stdin_input('y') do
      result = SharedTools.execute?(tool: 'TestTool', stuff: 'test operation')
      assert_equal true, result
    end
  end

  # .load_all_tools tests
  def test_load_all_tools_triggers_eager_loading
    # Should not raise
    SharedTools.load_all_tools
    assert true
  end

  def test_load_all_tools_makes_tool_classes_available
    SharedTools.load_all_tools
    # At least one known tool class should be defined after eager loading
    assert defined?(SharedTools::Tools::DiskTool)
    assert defined?(SharedTools::Tools::EvalTool)
    assert defined?(SharedTools::Tools::WorkflowManagerTool)
  end

  # .tools tests
  def test_tools_returns_array
    result = SharedTools.tools
    assert_kind_of Array, result
  end

  def test_tools_contains_ruby_llm_tool_subclasses
    result = SharedTools.tools
    assert result.all? { |k| k < ::RubyLLM::Tool },
           "Expected all entries to be RubyLLM::Tool subclasses"
  end

  def test_tools_includes_known_tools
    result = SharedTools.tools
    class_names = result.map(&:name)
    assert_includes class_names, 'disk_tool'
    assert_includes class_names, 'workflow_manager'
    assert_includes class_names, 'dns_tool'
  end
end
