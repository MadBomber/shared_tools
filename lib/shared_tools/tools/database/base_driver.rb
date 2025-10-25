# frozen_string_literal: true

module SharedTools
  module Tools
    module Database
      # Base class for database drivers (e.g. sqlite, postgres, mysql, etc).
      class BaseDriver
        # @param statement [String] e.g. "SELECT * FROM people"
        #
        # @return [Hash] e.g. { status: :ok, result: [["id", "name"], [1, "John"], [2, "Paul"], ...] }
        def perform(statement:)
          raise NotImplementedError, "#{self.class}##{__method__} undefined"
        end
      end
    end
  end
end
