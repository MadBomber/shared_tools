# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  add_filter "/vendor/"

  add_group "Core", "lib/shared_tools.rb"
  add_group "RubyLLM Tools", "lib/shared_tools/ruby_llm"

  minimum_coverage 20
end

require "minitest/autorun"
require "minitest/mock"
require "minitest/pride"
require "stringio"
require "ruby_llm"
require "shared_tools"

# Load optional dependencies for tests
begin
  require "nokogiri"
rescue LoadError
  # Nokogiri not available - some tests will be skipped
end

begin
  require "pdf-reader"
rescue LoadError
  # pdf-reader not available - some tests will be skipped
end

module Minitest
  class Test
    # Stub STDIN.getch to return +char+ for the duration of the block.
    # Used by tests that exercise the human-in-the-loop execute? prompt.
    def with_stdin_input(char)
      STDIN.stub(:getch, char) { yield }
    end

    # Initialize an empty git repo at +dir+ with a deterministic identity, so
    # commits work without relying on the host's global git config.
    def init_git_repo(dir)
      Dir.chdir(dir) do
        system("git", "init", "-q", "-b", "main", out: File::NULL, err: File::NULL)
        system("git", "config", "user.email", "test@example.com", out: File::NULL)
        system("git", "config", "user.name", "Test User", out: File::NULL)
        system("git", "config", "commit.gpgsign", "false", out: File::NULL)
      end
    end

    # Stage and commit everything in +dir+ (a git repo) with +message+.
    def git_commit_all(dir, message)
      Dir.chdir(dir) do
        system("git", "add", "-A", out: File::NULL, err: File::NULL)
        system("git", "commit", "-q", "-m", message, out: File::NULL, err: File::NULL)
      end
    end
  end
end
