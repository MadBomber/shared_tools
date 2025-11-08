# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  module Tools
    # @example
    #   db = Sqlite3::Database.new("./db.sqlite")
    #   driver = SharedTools::Tools::Database::SqliteDriver.new(db:)
    #   tool = SharedTools::Tools::DatabaseTool.new(driver:)
    #   tool.execute(statements: ["SELECT * FROM people"])
    class DatabaseTool < ::RubyLLM::Tool
      def self.name = 'database_tool' 
      description <<~TEXT
        Executes SQL commands (INSERT / UPDATE / SELECT / etc) on a database.

        Example:

        STATEMENTS:

            [
              'CREATE TABLE people (id INTEGER PRIMARY KEY, name TEXT NOT NULL)',
              'INSERT INTO people (name) VALUES ('John')',
              'INSERT INTO people (name) VALUES ('Paul')',
              'SELECT * FROM people',
              'DROP TABLE people'
            ]

        RESULT:

            [
              {
                "status": "OK",
                "statement": "CREATE TABLE people (id INTEGER PRIMARY KEY, name TEXT NOT NULL)",
                "result": "..."
              },
              {
                "status": "OK",
                "statement": "INSERT INTO people (name) VALUES ('John')"
                "result": "..."
              },
              {
                "status": "OK",
                "statement": "INSERT INTO people (name) VALUES ('Paul')",
                "result": "..."
              },
              {
                "status": "OK",
                "statement": "SELECT * FROM people",
                "result": "..."
              },
              {
                "status": "OK",
                "statement": "DROP TABLE people",
                "result": "..."
              }
            ]
      TEXT

      params do
        array :statements, of: :string, description: "A list of SQL statements to run sequentially (e.g. ['SELECT * FROM users', 'INSERT INTO ...'])"
      end


      # @param driver [SharedTools::Tools::Database::BaseDriver] required database driver (SqliteDriver, PostgresDriver, etc.)
      # @param logger [Logger] optional logger
      def initialize(driver:, logger: nil)
        raise ArgumentError, "driver is required for DatabaseTool" if driver.nil?
        @driver = driver
        @logger = logger || RubyLLM.logger
      end

      # @example
      #   tool = SharedTools::Tools::Database::BaseTool.new
      #   tool.execute(statements: ["SELECT * FROM people"])
      #
      # @param statements [Array<String>]
      #
      # @return [Array<Hash>]
      def execute(statements:)
        [].tap do |executions|
          statements.map do |statement|
            execution = perform(statement:).merge(statement:)
            executions << execution
            break unless execution[:status].eql?(:ok)
          end
        end
      end

      def perform(statement:)
        @logger&.info("#perform statement=#{statement.inspect}")

        @driver.perform(statement:).tap do |result|
          @logger&.info(JSON.generate(result))
        end
      end
    end
  end
end
