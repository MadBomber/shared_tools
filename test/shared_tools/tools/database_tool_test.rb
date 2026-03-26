# frozen_string_literal: true

require "test_helper"

class DatabaseToolTest < Minitest::Test
  class MockDriver
    attr_reader :executed_statements

    def initialize
      @executed_statements = []
    end

    def perform(statement:)
      @executed_statements << statement

      # Simulate successful execution
      {
        status: :ok,
        result: "Query executed successfully"
      }
    end
  end

  def setup
    @driver = MockDriver.new
    @tool = SharedTools::Tools::DatabaseTool.new(driver: @driver)
  end

  def test_tool_name
    assert_equal 'database_tool', SharedTools::Tools::DatabaseTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_requires_driver_at_execute_time
    # Tool can be instantiated without driver (for RubyLLM tool discovery)
    tool = SharedTools::Tools::DatabaseTool.new(driver: nil)
    assert_instance_of SharedTools::Tools::DatabaseTool, tool

    # But execute raises ArgumentError when driver is missing
    error = assert_raises(ArgumentError) do
      tool.execute(statements: ["SELECT 1"])
    end
    assert_includes error.message, "driver is required"
  end

  def test_driver_can_be_set_after_instantiation
    tool = SharedTools::Tools::DatabaseTool.new
    tool.driver = @driver
    result = tool.execute(statements: ["SELECT 1"])
    assert_equal :ok, result[0][:status]
  end

  def test_executes_single_statement
    statements = ["SELECT * FROM users"]
    result = @tool.execute(statements: statements)

    assert_kind_of Array, result
    assert_equal 1, result.length
    assert_equal :ok, result[0][:status]
    assert_equal "SELECT * FROM users", result[0][:statement]
  end

  def test_executes_multiple_statements
    statements = [
      "CREATE TABLE users (id INTEGER PRIMARY KEY)",
      "INSERT INTO users (id) VALUES (1)",
      "SELECT * FROM users"
    ]
    result = @tool.execute(statements: statements)

    assert_equal 3, result.length
    assert_equal 3, @driver.executed_statements.length

    result.each do |execution|
      assert_equal :ok, execution[:status]
      assert execution.key?(:statement)
      assert execution.key?(:result)
    end
  end

  def test_perform_method
    result = @tool.perform(statement: "SELECT 1")

    assert_kind_of Hash, result
    assert_equal :ok, result[:status]
  end

  def test_stops_execution_on_first_error
    error_driver = Class.new do
      attr_reader :executed_count

      def initialize
        @executed_count = 0
      end

      def perform(statement:)
        @executed_count += 1
        if @executed_count == 2
          { status: :error, result: "Error occurred" }
        else
          { status: :ok, result: "Success" }
        end
      end
    end.new

    tool = SharedTools::Tools::DatabaseTool.new(driver: error_driver)
    statements = ["STMT1", "STMT2", "STMT3"]
    result = tool.execute(statements: statements)

    # Should stop after the second statement (which errors)
    assert_equal 2, result.length
    assert_equal :ok, result[0][:status]
    assert_equal :error, result[1][:status]
  end
end
