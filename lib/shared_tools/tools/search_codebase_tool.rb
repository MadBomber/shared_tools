# frozen_string_literal: true

require "open3"

module SharedTools
  module Tools
    # Search for a term across files using ripgrep (rg) with grep as fallback.
    # Read-only — no authorization prompt required.
    #
    # @example
    #   tool = SharedTools::Tools::SearchCodebaseTool.new
    #   tool.execute(term: "def execute")
    #   tool.execute(term: "RubyLLM", extension: "rb", max_results: 20)
    class SearchCodebaseTool < ::RubyLLM::Tool
      MAX_RESULTS_CAP = 500

      def self.name = 'search_codebase'

      description "Search for a term or pattern across files. Uses ripgrep (rg) when available, falls back to grep. Returns matching lines with file path and line number."

      params do
        string  :term,        description: "The search term or regex pattern to find"
        string  :path,        description: "Directory to search in (default: current directory)", required: false
        string  :extension,   description: "File extension to restrict the search to, without the dot (e.g. 'rb', 'js')", required: false
        integer :max_results, description: "Maximum number of matching lines to return (default: 50, max: 500)", required: false
      end

      def initialize(logger: nil)
        @logger = logger || RubyLLM.logger
      end

      def execute(term:, path: ".", extension: nil, max_results: 50)
        @logger.info("SearchCodebaseTool#execute term=#{term.inspect} path=#{path} extension=#{extension.inspect}")

        return { error: "Search term cannot be empty" } if term.strip.empty?

        max_results = [[max_results.to_i, 1].max, MAX_RESULTS_CAP].min
        search_path = File.expand_path(path)

        return { error: "Path not found: #{path}" } unless File.exist?(search_path)

        stdout, _stderr, _status = run_search(term: term, path: search_path, extension: extension)

        all_lines  = stdout.lines.map(&:chomp).reject(&:empty?)
        matches    = all_lines.first(max_results)
        truncated  = all_lines.size > max_results

        {
          matches:   matches,
          count:     matches.size,
          truncated: truncated,
          tool:      ripgrep_available? ? "rg" : "grep"
        }
      rescue => e
        @logger.error("SearchCodebaseTool error: #{e.message}")
        { error: e.message }
      end

      private

      def run_search(term:, path:, extension:)
        if ripgrep_available?
          run_ripgrep(term: term, path: path, extension: extension)
        else
          run_grep(term: term, path: path, extension: extension)
        end
      end

      def run_ripgrep(term:, path:, extension:)
        args = ["rg", "--no-heading", "-n"]
        args += ["-g", "*.#{extension}"] if extension
        args << term
        args << path
        Open3.capture3(*args)
      end

      def run_grep(term:, path:, extension:)
        args = ["grep", "-r", "-n"]
        args += ["--include=*.#{extension}"] if extension
        args << term
        args << path
        Open3.capture3(*args)
      end

      def ripgrep_available?
        return @ripgrep_available unless @ripgrep_available.nil?
        @ripgrep_available = system("which", "rg", out: File::NULL, err: File::NULL)
      end
    end
  end
end
