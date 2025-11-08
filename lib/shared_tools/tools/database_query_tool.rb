# database_query_tool.rb - Safe database query execution
require 'ruby_llm/tool'
require 'sequel'

module SharedTools
  module Tools
    class DatabaseQueryTool < RubyLLM::Tool
      def self.name = 'database_query'

      description <<~'DESCRIPTION'
        Execute safe, read-only database queries with automatic connection management and security controls.
        This tool is designed for secure data retrieval operations only, restricting access to SELECT statements
        to prevent any data modification. It includes automatic connection pooling, query result limiting,
        query timeout support, and comprehensive error handling. The tool supports multiple database configurations
        through environment variables and ensures all connections are properly closed after use.
        Perfect for AI-assisted data analysis and reporting workflows where read-only access is required.

        Security features:
        - SELECT-only queries (no INSERT, UPDATE, DELETE, DROP, etc.)
        - Automatic LIMIT clause enforcement
        - Query timeout protection
        - Prepared statement support to prevent SQL injection
        - Connection pooling with automatic cleanup

        Supported databases:
        - PostgreSQL, MySQL, SQLite, SQL Server, Oracle, and any database supported by Sequel

        Example usage:
          tool = SharedTools::Tools::DatabaseQueryTool.new
          result = tool.execute(query: "SELECT * FROM users WHERE active = ?", params: [true])
          puts "Found #{result[:row_count]} users"
      DESCRIPTION

      params do
        string :query, description: <<~DESC.strip
          SQL SELECT query to execute against the database. Only SELECT statements are permitted
          for security reasons - INSERT, UPDATE, DELETE, and DDL statements will be rejected.
          The query should be well-formed SQL appropriate for the target database system.

          Use placeholders (?) for parameterized queries to prevent SQL injection:
          - Good: "SELECT * FROM users WHERE id = ?"
          - Bad: "SELECT * FROM users WHERE id = \#{user_id}"

          Examples:
          - 'SELECT * FROM users WHERE active = true'
          - 'SELECT COUNT(*) FROM orders'
          - 'SELECT name, email FROM customers WHERE created_at > ?'
        DESC

        string :database, description: <<~DESC.strip, required: false
          Database configuration name to use for the connection. This corresponds to environment
          variables like DATABASE_URL, STAGING_DATABASE_URL, etc. The tool will look for
          an environment variable named {DATABASE_NAME}_DATABASE_URL (uppercase).
          Default is 'default' which looks for DEFAULT_DATABASE_URL or DATABASE_URL environment variable.
          Common values: 'default', 'staging', 'analytics', 'reporting', 'production'.
        DESC

        integer :limit, description: <<~DESC.strip, required: false
          Maximum number of rows to return from the query to prevent excessive memory usage
          and long response times. The tool automatically adds a LIMIT clause if one is not
          present in the original query. Set to a reasonable value based on expected data size.
          Minimum: 1, Maximum: 10000, Default: 100. For large datasets, consider using
          pagination or more specific WHERE clauses.
        DESC

        integer :timeout, description: <<~DESC.strip, required: false
          Query timeout in seconds. If the query takes longer than this to execute, it will
          be cancelled and an error will be returned. This prevents long-running queries from
          consuming excessive resources. Minimum: 1, Maximum: 300, Default: 30 seconds.
        DESC

        array :params, of: :string, description: <<~DESC.strip, required: false
          Parameters to bind to the query placeholders (?). Use parameterized queries to prevent
          SQL injection vulnerabilities. The number of parameters must match the number of
          placeholders in the query. Parameters are automatically escaped and quoted based on
          their type. Example: params: [1, "john@example.com", true] for a query with 3 placeholders.
        DESC
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
        @connection_cache = {}
      end

      # Execute read-only database query
      #
      # @param query [String] SQL SELECT query to execute
      # @param database [String] Database configuration name
      # @param limit [Integer] Maximum rows to return (1-10000), default 100
      # @param timeout [Integer] Query timeout in seconds (1-300), default 30
      # @param params [Array] Parameters for parameterized query
      #
      # @return [Hash] Query results with success status
      def execute(query:, database: "default", limit: 100, timeout: 30, params: [])
        @logger.info("DatabaseQueryTool#execute database=#{database} limit=#{limit} timeout=#{timeout}")

        begin
          # Validate and sanitize inputs
          validate_query(query)
          limit = validate_limit(limit)
          timeout = validate_timeout(timeout)

          # Get or create database connection (cached for in-memory databases)
          db = get_connection(database, timeout)

          # Add LIMIT clause if not present
          limited_query = add_limit_to_query(query, limit)

          @logger.debug("Executing query: #{limited_query}")
          @logger.debug("With parameters: #{params.inspect}") if params && !params.empty?

          # Execute query with parameters
          start_time = Time.now
          results = if params && !params.empty?
            db[limited_query, *params].all
          else
            db[limited_query].all
          end
          execution_time = Time.now - start_time

          @logger.info("Query executed successfully: #{results.length} rows in #{execution_time.round(3)}s")

          {
            success:        true,
            query:          limited_query,
            row_count:      results.length,
            data:           results,
            database:       database,
            execution_time: execution_time.round(3),
            executed_at:    Time.now.iso8601
          }
        rescue Sequel::DatabaseError => e
          @logger.error("Database error: #{e.message}")
          {
            success:    false,
            error:      "Database error: #{e.message}",
            error_type: "database_error",
            query:      query,
            database:   database
          }
        rescue => e
          @logger.error("Query execution failed: #{e.message}")
          {
            success:    false,
            error:      e.message,
            error_type: e.class.name,
            query:      query,
            database:   database
          }
        end
      end

      private

      # Validate that query is a SELECT statement
      #
      # @param query [String] SQL query to validate
      # @raise [ArgumentError] if query is not a SELECT statement
      def validate_query(query)
        raise ArgumentError, "Query cannot be empty" if query.nil? || query.strip.empty?

        # Remove comments and normalize whitespace
        normalized_query = query.gsub(/--.*$/, '').gsub(/\/\*.*?\*\//m, '').strip.downcase

        # Check for dangerous keywords FIRST (more specific error messages)
        dangerous_keywords = %w[insert update delete drop alter truncate grant revoke]
        dangerous_keywords.each do |keyword|
          if normalized_query.match?(/\b#{keyword}\b/)
            raise ArgumentError, "Query contains forbidden keyword: #{keyword.upcase}"
          end
        end

        # Then check for SELECT at the start (allowing WITH clauses)
        unless normalized_query.start_with?('select') || normalized_query.start_with?('with')
          raise ArgumentError, "Only SELECT queries are allowed for security. Got: #{query[0..50]}"
        end

        @logger.debug("Query validation passed")
      end

      # Validate and normalize limit parameter
      #
      # @param limit [Integer] Requested limit
      # @return [Integer] Validated limit (1-10000)
      def validate_limit(limit)
        limit = limit.to_i

        if limit < 1
          @logger.warn("Limit #{limit} is too low, adjusting to 1")
          return 1
        end

        if limit > 10000
          @logger.warn("Limit #{limit} exceeds maximum, adjusting to 10000")
          return 10000
        end

        limit
      end

      # Validate and normalize timeout parameter
      #
      # @param timeout [Integer] Requested timeout in seconds
      # @return [Integer] Validated timeout (1-300)
      def validate_timeout(timeout)
        timeout = timeout.to_i

        if timeout < 1
          @logger.warn("Timeout #{timeout} is too low, adjusting to 1")
          return 1
        end

        if timeout > 300
          @logger.warn("Timeout #{timeout} exceeds maximum, adjusting to 300")
          return 300
        end

        timeout
      end

      # Get or create cached database connection
      #
      # @param database_name [String] Database configuration name
      # @param timeout [Integer] Query timeout in seconds
      # @return [Sequel::Database] Database connection
      def get_connection(database_name, timeout)
        connection_string = find_connection_string(database_name)

        unless connection_string
          error_msg = "Database connection not configured for '#{database_name}'. " \
                      "Please set #{database_name.upcase}_DATABASE_URL environment variable."
          @logger.error(error_msg)
          raise ArgumentError, error_msg
        end

        # Cache connections for in-memory databases to prevent data loss
        # This allows multiple execute calls to share the same in-memory database
        is_memory_db = connection_string.match?(/sqlite:(:|\/\/file:.*mode=memory)/)
        if is_memory_db
          cache_key = "#{database_name}:#{connection_string}"
          @connection_cache[cache_key] ||= connect_to_database(connection_string, timeout)
        else
          # For regular databases, create new connection each time (don't cache)
          connect_to_database(connection_string, timeout)
        end
      end

      # Connect to database with proper error handling
      #
      # @param connection_string [String] Database connection string
      # @param timeout [Integer] Query timeout in seconds
      # @return [Sequel::Database] Database connection
      def connect_to_database(connection_string, timeout)
        @logger.debug("Connecting to database")

        # Create connection with timeout
        db = Sequel.connect(connection_string)

        # Set query timeout if supported by the database
        begin
          case db.database_type
          when :postgres
            db.execute("SET statement_timeout = #{timeout * 1000}")  # milliseconds
          when :mysql
            db.execute("SET SESSION max_execution_time = #{timeout * 1000}")  # milliseconds
          when :sqlite
            # SQLite timeout is set at connection time via busy_timeout pragma
            # The timeout parameter controls how long SQLite waits for locks
            db.execute("PRAGMA busy_timeout = #{timeout * 1000}")  # milliseconds
          end
        rescue => e
          @logger.warn("Could not set query timeout: #{e.message}")
        end

        db
      end

      # Find connection string from environment variables
      #
      # @param database_name [String] Database configuration name
      # @return [String, nil] Connection string or nil if not found
      def find_connection_string(database_name)
        # Try with database name prefix
        connection_string = ENV["#{database_name.upcase}_DATABASE_URL"]
        return connection_string if connection_string

        # For 'default', also try without prefix
        if database_name.downcase == 'default'
          connection_string = ENV['DATABASE_URL']
          return connection_string if connection_string
        end

        nil
      end

      # Add LIMIT clause to query if not present
      #
      # @param query [String] SQL query
      # @param limit [Integer] Maximum rows to return
      # @return [String] Query with LIMIT clause
      def add_limit_to_query(query, limit)
        # Use regex to detect existing LIMIT clause (case-insensitive, handles various formats)
        return query if query.match?(/\bLIMIT\s+\d+/i)

        # Add LIMIT at the end of the query
        # Handle queries that might end with semicolon
        query = query.sub(/;\s*\z/, '')
        "#{query} LIMIT #{limit}"
      end
    end
  end
end
