# frozen_string_literal: true

require "test_helper"

class ParseRubyToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::ParseRubyTool.new
    @dir = Dir.mktmpdir
    @path = File.join(@dir, "sample.rb")
    File.write(@path, <<~RUBY)
      module Foo
        class Bar
          BAZ = 1

          def qux
            42
          end

          def self.class_method
            1
          end
        end
      end
    RUBY
  end

  def teardown
    FileUtils.rm_rf(@dir) if @dir && File.exist?(@dir)
  end

  def test_tool_name
    assert_equal "parse_ruby", SharedTools::Tools::ParseRubyTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_outlines_structure
    result = @tool.execute(path: @path)

    assert_includes result, "module Foo"
    assert_includes result, "class Bar"
    assert_includes result, "def qux"
  end

  def test_filters_by_kind
    result = @tool.execute(path: @path, kind: "method")

    assert_includes result, "qux"
    refute_includes result, "class Bar"
  end

  def test_filters_by_query
    result = @tool.execute(path: @path, query: "qux")

    assert_includes result, "qux"
    refute_includes result, "class_method"
  end

  def test_unknown_kind_returns_error
    result = @tool.execute(path: @path, kind: "bogus")

    assert result.is_a?(Hash)
    assert_includes result[:error], "unknown kind"
  end

  def test_missing_file_returns_error
    result = @tool.execute(path: File.join(@dir, "nope.rb"))

    assert result.is_a?(Hash)
    assert_includes result[:error], "not found"
  end

  def test_syntax_error_returns_error
    bad_path = File.join(@dir, "bad.rb")
    File.write(bad_path, "def broken(\n")

    result = @tool.execute(path: bad_path)

    assert result.is_a?(Hash)
    assert result.key?(:error)
  end

  def test_no_definitions
    empty_path = File.join(@dir, "empty.rb")
    File.write(empty_path, "# just a comment\n")

    result = @tool.execute(path: empty_path)

    assert_includes result, "no definitions"
  end
end
