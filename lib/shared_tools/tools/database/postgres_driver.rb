# frozen_string_literal: true

module SharedTools
  module Tools
    module Database
      # @example
      #   connection = PG.connect(dbname: "testdb")
      #   driver = SharedTools::Tools::Database::PostgresDriver.new
      #   driver.perform(statement: "SELECT * FROM people")
      class PostgresDriver < BaseDriver
        # @param connection [Sqlite3::Database]
        def initialize(connection:)
          super()
          @connection = connection
        end

        # @param statement [String]
        #
        # @return [Hash]
        def perform(statement:)
          @connection.exec(statement) do |result|
            { status: :ok, result: [result.fields] + result.values }
          end
        rescue ::PG::Error => e
          { status: :error, message: e.message }
        end
      end
    end
  end
end
