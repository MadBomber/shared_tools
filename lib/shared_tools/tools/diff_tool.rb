# frozen_string_literal: true

require_relative '../../shared_tools'

module SharedTools
  module Tools
    # Compares two blocks of text and returns a readable line diff. In-process,
    # read-only — no filesystem or git access. For diffing files already on
    # disk, see Git::DiffTool.
    #
    # @example
    #   tool = SharedTools::Tools::DiffTool.new
    #   tool.execute(old: "a\nb\n", new: "a\nc\n")
    class DiffTool < ::RubyLLM::Tool
      def self.name = 'diff'

      description "Compare two blocks of text and return a readable line-by-line diff " \
                  "(removed lines prefixed -, added lines prefixed +). In-process."

      params do
        string :old,       description: "The original text."
        string :new,       description: "The changed text."
        string :old_label, description: "Label for the original side. Default 'old'.", required: false
        string :new_label, description: "Label for the changed side. Default 'new'.", required: false
      end

      # @param logger [Logger] optional logger
      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      # @param old [String]
      # @param new [String]
      # @param old_label [String]
      # @param new_label [String]
      #
      # @return [String]
      def execute(old:, new:, old_label: "old", new_label: "new")
        @logger.info("#{self.class.name}#execute old_label=#{old_label} new_label=#{new_label}")

        SharedTools::TextDiff.unified(old.to_s, new.to_s, old_label: old_label.to_s, new_label: new_label.to_s)
      rescue => e
        @logger.error("#{self.class.name} failed: #{e.message}")
        { error: e.message }
      end
    end
  end
end
