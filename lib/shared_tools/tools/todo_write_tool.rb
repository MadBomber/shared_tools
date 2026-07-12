# frozen_string_literal: true

require_relative "../../shared_tools"

module SharedTools
  module Tools
    # Tracks a task list for multi-step work. Each call replaces the whole
    # list (the standard agent pattern) and renders it back. State lives on
    # the tool instance, so it persists across calls within a single chat
    # session (when one instance is registered with the chat). Read-only in
    # the sense that it never touches the filesystem or network — no
    # authorization prompt required.
    #
    # @example
    #   tool = SharedTools::Tools::TodoWriteTool.new
    #   tool.execute(todos: [
    #     { content: "Write the tool", status: "completed" },
    #     { content: "Write the tests", status: "in_progress" }
    #   ])
    class TodoWriteTool < ::RubyLLM::Tool
      STATUSES = %w[pending in_progress completed].freeze
      MARKS = { "pending" => "[ ]", "in_progress" => "[~]", "completed" => "[x]" }.freeze

      def self.name = 'todo_write'

      description "Maintain a task list for multi-step work. Pass the full list of todos; each call " \
                  "replaces the previous list. Each todo has a content string and a status of " \
                  "pending, in_progress, or completed."

      params do
        array :todos, description: "The full task list, replacing the previous one." do
          object do
            string :content, description: "The task description."
            string :status,  description: "One of: pending, in_progress, completed."
          end
        end
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @todos = []
        @logger = logger || RubyLLM.logger
      end

      # @param todos [Array<Hash>]
      #
      # @return [String, Hash]
      def execute(todos:)
        @logger.info("#{self.class.name}#execute todos=#{Array(todos).size}")

        return { error: "todos must be an array" } unless todos.is_a?(Array)

        normalized = todos.map { |todo| normalize(todo) }
        invalid = normalized.find { |todo| !STATUSES.include?(todo[:status]) }
        return { error: "invalid status: #{invalid[:status].inspect} (use #{STATUSES.join(', ')})" } if invalid

        @todos = normalized
        render
      end

      private

      def normalize(todo)
        hash = todo.is_a?(Hash) ? todo : {}
        {
          content: (hash["content"] || hash[:content]).to_s,
          status: (hash["status"] || hash[:status] || "pending").to_s.strip.downcase
        }
      end

      def render
        return "Task list is empty." if @todos.empty?

        done = @todos.count { |todo| todo[:status] == "completed" }
        lines = ["Tasks (#{done}/#{@todos.size} complete):"]
        @todos.each { |todo| lines << "#{MARKS[todo[:status]]} #{todo[:content]}" }
        lines.join("\n")
      end
    end
  end
end
