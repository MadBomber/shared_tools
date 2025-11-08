# frozen_string_literal: true

module SharedTools
  module Tools
    module Database
      # @example
      #   driver = SharedTools::Tools::Database::SqliteDriver.new
      #   driver.perform(statement: "SELECT * FROM people")
      class SqliteDriver < BaseDriver
        # @param db [Sqlite3::Database]
        def initialize(db:)
          super()
          @db = db
        end

        # @param statement [String]
        #
        # @return [Hash]
        def perform(statement:)
          result = @db.execute2(statement)

          { status: :ok, result: }
        rescue ::SQLite3::Exception => e
          { status: :error, message: e.message }
        end
      end
    end
  end
end
