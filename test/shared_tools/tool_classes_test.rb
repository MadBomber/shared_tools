# frozen_string_literal: true

require "test_helper"

# Guards the ruby_llm 2.x tool contract for every tool SharedTools ships.
#
# Under ruby_llm 2.x a class that still used the 1.x `params do ... end` macro
# raised NoMethodError part-way through its body. The constant already existed,
# so a half-built class loaded, but every `def` after the macro (including
# #execute) was never defined and calls failed with
# "NotImplementedError: Subclasses must implement #execute".
class ToolClassesTest < Minitest::Test
  def tool_classes
    @tool_classes ||= SharedTools.tools.select do |klass|
      klass.name.to_s.start_with?("SharedTools::")
    end
  end

  # Some tools need an optional external dependency in #initialize (e.g. the
  # browser tools need the ferrum gem or an injected driver). The schema and
  # the #execute definition are class-level facts, so fall back to allocate.
  def instance_of(klass)
    klass.new
  rescue LoadError
    klass.allocate
  end

  def test_ships_tool_classes
    assert_operator tool_classes.size, :>=, 80
  end

  def test_every_tool_defines_its_own_execute
    inherited = tool_classes.select { |klass| klass.instance_method(:execute).owner == ::RubyLLM::Tool }
    assert_empty inherited.map(&:name),
                 "these tools do not define #execute (a class body probably failed to load)"
  end

  def test_every_tool_has_an_object_parameters_schema
    tool_classes.each do |klass|
      schema = instance_of(klass).parameters_schema
      label  = klass.name

      assert_kind_of Hash, schema, "#{label} has no parameters schema"
      assert_equal "object", schema["type"], "#{label} schema type"
      assert_kind_of Hash, schema["properties"], "#{label} schema properties"
      assert_kind_of Array, schema["required"], "#{label} schema required list"
      assert_empty schema["required"] - schema["properties"].keys, "#{label} requires undeclared properties"
    end
  end

  def test_every_schema_property_is_accepted_by_execute
    tool_classes.each do |klass|
      label  = klass.name
      params = klass.instance_method(:execute).parameters
      next if params.any? { |kind, _| kind == :keyrest }

      keywords = params.filter_map { |kind, name| name.to_s if %i[key keyreq].include?(kind) }
      schema   = instance_of(klass).parameters_schema

      assert_empty schema["properties"].keys - keywords, "#{label}#execute does not accept every schema property"
    end
  end

  def test_every_tool_has_a_description_and_name
    tool_classes.each do |klass|
      label = klass.name

      refute_empty klass.description.to_s.strip, "#{label} has no description"
      refute_empty klass.tool_name.to_s, "#{label} has no tool name"
    end
  end

  # ruby_llm 2.1 derives the model-visible name from ::tool_name. Overriding
  # Class#name instead breaks inspect and constant-lookup error messages.
  def test_no_tool_overrides_class_name
    overriders = tool_classes.select { |klass| klass.singleton_class.instance_methods(false).include?(:name) }
    assert_empty overriders.map(&:to_s), "override ::tool_name, not ::name"
  end

  def test_tool_names_are_unique_and_valid
    names = tool_classes.map(&:tool_name)

    assert_empty names.tally.select { |_, count| count > 1 }.keys, "duplicate tool names"
    names.each { |name| assert_match(/\A[a-z0-9_]{1,64}\z/, name) }
  end

  def test_no_ruby_llm_1x_dsl_left_in_lib
    lib   = File.expand_path("../../lib", __dir__)
    stale = Dir.glob("#{lib}/**/*.rb").select do |path|
      File.read(path, encoding: "UTF-8").match?(/^\s*(params\s+do\b|param\s+:)/)
    end

    assert_empty stale, "ruby_llm 1.x `params do` / `param :` found"
  end

  # docs/development/changelog.md is release history and keeps the old APIs.
  def test_docs_do_not_teach_removed_ruby_llm_apis
    docs  = File.expand_path("../../docs", __dir__)
    pages = Dir.glob("#{docs}/**/*.md") - ["#{docs}/development/changelog.md"]
    stale = pages.select do |path|
      File.read(path, encoding: "UTF-8").match?(/^\s*(params\s+do\b|param\s+:)|RubyLLM::Agent\.new\(\s*tools:/)
    end

    assert_empty stale, "ruby_llm 1.x `param :` DSL or `RubyLLM::Agent.new(tools:)` found in docs"
  end
end

# The tools aia's demo 18 hands to a model. Call them the way a chat does
# (Tool#call validates the arguments against #execute) and check real data.
class AiaDemoToolsTest < Minitest::Test
  def test_current_date_time_returns_the_current_date
    result = SharedTools::Tools::CurrentDateTimeTool.new.call(format: "iso8601")

    assert result[:success]
    assert_equal Date.today.year, result[:year] if result.key?(:year)
    assert_match(/\A\d{4}-\d{2}-\d{2}T/, result[:iso8601])
  end

  def test_system_info_returns_host_data
    result = SharedTools::Tools::SystemInfoTool.new.call(category: "all")

    assert result[:success]
    assert_equal RUBY_PLATFORM, result[:os_platform]
    refute_empty result[:hostname].to_s
  end

  def test_dns_resolves_localhost
    result = SharedTools::Tools::DnsTool.new.call(action: "a", host: "localhost")

    assert result[:success], result.inspect
    assert_includes result[:records], "127.0.0.1"
  end

  def test_call_rejects_unknown_arguments_instead_of_raising
    result = SharedTools::Tools::DnsTool.new.call(action: "a", hostname: "localhost")

    assert_match(/unknown keyword: hostname/, result[:error])
  end
end
