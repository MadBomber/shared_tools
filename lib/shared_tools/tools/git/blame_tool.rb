# frozen_string_literal: true

require_relative "helpers"

module SharedTools
  module Tools
    module Git
      # Read-only. Shows line-by-line authorship (commit, author, date) for a
      # file in the repo at repo_root.
      #
      # @example
      #   tool = SharedTools::Tools::Git::BlameTool.new
      #   tool.execute(path: "lib/foo.rb", start_line: 10, end_line: 20)
      class BlameTool < ::RubyLLM::Tool
        include Helpers

        def self.name = 'git_blame'

        description "Show git blame for a file in the repository: which commit, author, and date " \
                    "last touched each line. Optionally limit to a line range. Read-only."

        params do
          string  :path,        description: "File to blame, relative to the repo root."
          integer :start_line,  description: "First line of the range to blame. Optional.", required: false
          integer :end_line,    description: "Last line of the range to blame. Optional.", required: false
        end

        # @param repo_root [String] optional, defaults to the current directory
        # @param logger [Logger] optional logger
        def initialize(repo_root: nil, logger: nil)
          @repo_root = repo_root || Dir.pwd
          @logger = logger || RubyLLM.logger
        end

        # @param path [String]
        # @param start_line [Integer, nil]
        # @param end_line [Integer, nil]
        #
        # @return [String, Hash]
        def execute(path:, start_line: nil, end_line: nil)
          @logger.info("#{self.class.name}#execute path=#{path.inspect} start_line=#{start_line.inspect} end_line=#{end_line.inspect}")

          rel = repo_relative(path, repo_root: @repo_root)
          return { error: "path must be provided" } if rel.nil?

          args = ["blame", "--date=short"]
          if (range = line_range(start_line, end_line))
            args += ["-L", range]
          end
          args += ["--", rel]

          out, err, status = run_git(*args, repo_root: @repo_root)
          result = git_result(out, err, status)
          return result if result.is_a?(Hash)

          result.strip.empty? ? "no blame output (empty file?)" : result
        rescue SecurityError => e
          @logger.error("#{self.class.name} path denied: #{e.message}")
          { error: e.message }
        rescue => e
          @logger.error("#{self.class.name} failed: #{e.message}")
          { error: e.message }
        end

        private

        def line_range(start_line, end_line)
          return nil if start_line.nil? && end_line.nil?

          first = [start_line.to_i, 1].max
          last  = end_line.nil? ? "" : [end_line.to_i, first].max
          "#{first},#{last}"
        end
      end
    end
  end
end
