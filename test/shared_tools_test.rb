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
    STDIN.stub :getch, 'y' do
      result = SharedTools.execute?(tool: 'TestTool', stuff: 'test operation')
      assert_equal true, result
    end
  end

  def test_returns_false_when_user_inputs_n
    SharedTools.instance_variable_set(:@auto_execute, nil)
    STDIN.stub :getch, 'n' do
      result = SharedTools.execute?(tool: 'TestTool', stuff: 'test operation')
      assert_equal false, result
    end
  end

  def test_returns_false_when_user_inputs_capital_n
    SharedTools.instance_variable_set(:@auto_execute, nil)
    STDIN.stub :getch, 'N' do
      result = SharedTools.execute?(tool: 'TestTool', stuff: 'test operation')
      assert_equal false, result
    end
  end

  def test_returns_false_when_user_inputs_random_characters
    SharedTools.instance_variable_set(:@auto_execute, nil)
    STDIN.stub :getch, 'x' do
      result = SharedTools.execute?(tool: 'TestTool', stuff: 'test operation')
      assert_equal false, result
    end
  end

  def test_handles_empty_stuff_parameter
    SharedTools.instance_variable_set(:@auto_execute, nil)
    STDIN.stub :getch, 'y' do
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
    STDIN.stub :getch, 'y' do
      result = SharedTools.execute?(tool: 'TestTool', stuff: 'test operation')
      assert_equal true, result
    end
  end
end
