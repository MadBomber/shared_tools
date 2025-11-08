# frozen_string_literal: true

require "test_helper"

class DatabaseQueryToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::DatabaseQueryTool.new

    # Use temporary file-based SQLite database for testing
    # This avoids in-memory database sharing issues
    @db_file = "/tmp/test_db_#{Process.pid}_#{Time.now.to_i}.sqlite"
    @db_url = "sqlite://#{@db_file}"
    ENV['DEFAULT_DATABASE_URL'] = @db_url
    ENV['TEST_DATABASE_URL'] = @db_url

    # Set up test database with sample data
    @test_db = setup_test_database
  end

  def teardown
    @test_db&.disconnect
    File.delete(@db_file) if File.exist?(@db_file)
    ENV.delete('DEFAULT_DATABASE_URL')
    ENV.delete('TEST_DATABASE_URL')
  end

  def test_tool_name
    assert_equal 'database_query', SharedTools::Tools::DatabaseQueryTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  # Basic query execution
  def test_simple_select_query
    result = @tool.execute(query: "SELECT * FROM users")

    assert result[:success]
    assert_equal 3, result[:row_count]
    assert result[:data].is_a?(Array)
    assert result[:execution_time]
    assert result[:executed_at]
  end

  def test_select_with_where_clause
    result = @tool.execute(query: "SELECT * FROM users WHERE active = 1")

    assert result[:success]
    assert_equal 2, result[:row_count]
  end

  def test_count_query
    result = @tool.execute(query: "SELECT COUNT(*) as count FROM users")

    assert result[:success]
    assert_equal 1, result[:row_count]
    assert result[:data][0][:count] == 3
  end

  def test_query_with_limit
    result = @tool.execute(query: "SELECT * FROM users", limit: 2)

    assert result[:success]
    assert_equal 2, result[:row_count]
    assert_includes result[:query], "LIMIT 2"
  end

  # Parameterized queries
  def test_parameterized_query
    result = @tool.execute(
      query: "SELECT * FROM users WHERE id = ?",
      params: [1]
    )

    assert result[:success]
    assert_equal 1, result[:row_count]
    assert_equal "Alice", result[:data][0][:name]
  end

  def test_parameterized_query_with_multiple_params
    result = @tool.execute(
      query: "SELECT * FROM users WHERE active = ? AND id > ?",
      params: [1, 0]
    )

    assert result[:success]
    assert_equal 2, result[:row_count]
  end

  def test_parameterized_query_prevents_sql_injection
    # Attempt SQL injection through parameter
    result = @tool.execute(
      query: "SELECT * FROM users WHERE name = ?",
      params: ["Alice' OR '1'='1"]
    )

    assert result[:success]
    # Should return 0 rows since the parameter is properly escaped
    assert_equal 0, result[:row_count]
  end

  # Default parameter values
  def test_default_database_name
    result = @tool.execute(query: "SELECT 1")

    assert result[:success]
    assert_equal "default", result[:database]
  end

  def test_default_limit_is_100
    # Query should have LIMIT 100 added automatically
    result = @tool.execute(query: "SELECT * FROM users")

    assert result[:success]
    assert_includes result[:query], "LIMIT 100"
  end

  # Custom database configuration
  def test_custom_database_name
    result = @tool.execute(
      query: "SELECT * FROM users",
      database: "test"
    )

    assert result[:success]
    assert_equal "test", result[:database]
  end

  # Security validations
  def test_rejects_insert_query
    result = @tool.execute(query: "INSERT INTO users (name) VALUES ('Bob')")

    refute result[:success]
    assert_includes result[:error], "forbidden keyword"
    assert_equal "ArgumentError", result[:error_type]
  end

  def test_rejects_update_query
    result = @tool.execute(query: "UPDATE users SET active = 0 WHERE id = 1")

    refute result[:success]
    assert_includes result[:error], "forbidden keyword"
  end

  def test_rejects_delete_query
    result = @tool.execute(query: "DELETE FROM users WHERE id = 1")

    refute result[:success]
    assert_includes result[:error], "forbidden keyword"
  end

  def test_rejects_drop_query
    result = @tool.execute(query: "DROP TABLE users")

    refute result[:success]
    assert_includes result[:error], "forbidden keyword"
  end

  def test_rejects_alter_query
    result = @tool.execute(query: "ALTER TABLE users ADD COLUMN email VARCHAR(255)")

    refute result[:success]
    assert_includes result[:error], "forbidden keyword"
  end

  def test_rejects_create_query
    result = @tool.execute(query: "CREATE TABLE new_table (id INT)")

    refute result[:success]
    assert_includes result[:error], "Only SELECT queries are allowed"
  end

  def test_rejects_truncate_query
    result = @tool.execute(query: "TRUNCATE TABLE users")

    refute result[:success]
    assert_includes result[:error], "forbidden keyword"
  end

  def test_rejects_empty_query
    result = @tool.execute(query: "")

    refute result[:success]
    assert_includes result[:error], "cannot be empty"
  end

  def test_rejects_nil_query
    result = @tool.execute(query: nil)

    refute result[:success]
    assert_includes result[:error], "cannot be empty"
  end

  # Limit validation
  def test_limit_minimum_is_one
    result = @tool.execute(query: "SELECT * FROM users", limit: 0)

    assert result[:success]
    assert_includes result[:query], "LIMIT 1"
  end

  def test_limit_maximum_is_10000
    result = @tool.execute(query: "SELECT * FROM users", limit: 20000)

    assert result[:success]
    assert_includes result[:query], "LIMIT 10000"
  end

  def test_negative_limit_adjusted_to_one
    result = @tool.execute(query: "SELECT * FROM users", limit: -5)

    assert result[:success]
    assert_includes result[:query], "LIMIT 1"
  end

  # Timeout validation
  def test_timeout_minimum_is_one
    result = @tool.execute(query: "SELECT * FROM users", timeout: 0)

    assert result[:success]
  end

  def test_timeout_maximum_is_300
    result = @tool.execute(query: "SELECT * FROM users", timeout: 500)

    assert result[:success]
  end

  def test_negative_timeout_adjusted
    result = @tool.execute(query: "SELECT * FROM users", timeout: -5)

    assert result[:success]
  end

  # LIMIT clause detection
  def test_does_not_add_limit_if_present_lowercase
    result = @tool.execute(query: "SELECT * FROM users limit 5")

    assert result[:success]
    # Should not have LIMIT 100 added
    refute_includes result[:query], "LIMIT 100"
    assert_includes result[:query].downcase, "limit 5"
  end

  def test_does_not_add_limit_if_present_uppercase
    result = @tool.execute(query: "SELECT * FROM users LIMIT 10")

    assert result[:success]
    refute_includes result[:query], "LIMIT 100"
    assert_includes result[:query], "LIMIT 10"
  end

  def test_handles_query_with_semicolon
    result = @tool.execute(query: "SELECT * FROM users;")

    assert result[:success]
    # Semicolon should be removed and LIMIT added
    refute result[:query].end_with?(";")
    assert_includes result[:query], "LIMIT"
  end

  # WITH clause support (CTE)
  def test_allows_with_clause
    result = @tool.execute(
      query: "WITH active_users AS (SELECT * FROM users WHERE active = 1) SELECT * FROM active_users"
    )

    assert result[:success]
    assert_equal 2, result[:row_count]
  end

  # SQL comment handling
  def test_ignores_sql_line_comments
    result = @tool.execute(
      query: "-- This is a comment\nSELECT * FROM users -- another comment\nWHERE active = 1"
    )

    assert result[:success]
    assert_equal 2, result[:row_count]
  end

  def test_ignores_sql_block_comments
    result = @tool.execute(
      query: "/* Block comment */ SELECT * FROM users /* another */ WHERE active = 1"
    )

    assert result[:success]
    assert_equal 2, result[:row_count]
  end

  # Error handling
  def test_handles_invalid_sql_syntax
    result = @tool.execute(query: "SELECT * FROM")

    refute result[:success]
    assert result[:error]
    assert_equal "database_error", result[:error_type]
  end

  def test_handles_nonexistent_table
    result = @tool.execute(query: "SELECT * FROM nonexistent_table")

    refute result[:success]
    assert result[:error]
  end

  def test_handles_missing_database_config
    ENV.delete('MISSING_DATABASE_URL')

    result = @tool.execute(
      query: "SELECT * FROM users",
      database: "missing"
    )

    refute result[:success]
    assert_includes result[:error], "not configured"
    assert_includes result[:error], "MISSING_DATABASE_URL"
  end

  # Data retrieval verification
  def test_returns_correct_data_structure
    result = @tool.execute(query: "SELECT * FROM users WHERE id = 1")

    assert result[:success]
    user = result[:data][0]

    assert user[:id]
    assert user[:name]
    assert user.key?(:active)
  end

  def test_returns_all_columns
    result = @tool.execute(query: "SELECT id, name, active FROM users WHERE id = 1")

    assert result[:success]
    user = result[:data][0]

    assert_equal 1, user[:id]
    assert_equal "Alice", user[:name]
    assert_equal 1, user[:active]
  end

  # Edge cases
  def test_handles_empty_result_set
    result = @tool.execute(query: "SELECT * FROM users WHERE id = 999")

    assert result[:success]
    assert_equal 0, result[:row_count]
    assert_empty result[:data]
  end

  def test_handles_complex_where_clause
    result = @tool.execute(
      query: "SELECT * FROM users WHERE (active = 1 OR id = 3) AND id > 0"
    )

    assert result[:success]
    assert result[:row_count] >= 1
  end

  def test_handles_order_by_clause
    result = @tool.execute(query: "SELECT * FROM users ORDER BY name DESC")

    assert result[:success]
    assert_equal 3, result[:row_count]
    # Charlie should be first when ordered DESC by name
    assert_equal "Charlie", result[:data][0][:name]
  end

  def test_handles_join_query
    result = @tool.execute(
      query: "SELECT u.name, COUNT(o.id) as order_count
              FROM users u
              LEFT JOIN orders o ON u.id = o.user_id
              GROUP BY u.name"
    )

    assert result[:success]
    assert_equal 3, result[:row_count]
  end

  private

  def setup_test_database
    db = Sequel.connect(@db_url)

    # Create users table
    db.create_table! :users do
      primary_key :id
      String :name
      Integer :active
    end

    # Create orders table for join tests
    db.create_table! :orders do
      primary_key :id
      Integer :user_id
      Float :amount
    end

    # Insert test data
    db[:users].insert(name: "Alice", active: 1)
    db[:users].insert(name: "Bob", active: 1)
    db[:users].insert(name: "Charlie", active: 0)

    db[:orders].insert(user_id: 1, amount: 50.0)
    db[:orders].insert(user_id: 1, amount: 75.0)
    db[:orders].insert(user_id: 2, amount: 100.0)

    # Return connection without disconnecting to keep in-memory database alive
    db
  end
end
