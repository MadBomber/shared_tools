# frozen_string_literal: true

require "test_helper"

class SystemInfoToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::SystemInfoTool.new
  end

  def test_tool_name
    assert_equal 'system_info_tool', SharedTools::Tools::SystemInfoTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  # 'all' category (default)
  def test_default_returns_all_categories
    result = @tool.execute
    assert result[:success]
    # Each sub-info merges flat keys; verify at least one from each group
    assert result.key?(:os_platform)
    assert result.key?(:cpu_model)
    assert result.key?(:memory_total_gb)
    assert result.key?(:ruby_version)
  end

  def test_category_all_explicit
    result = @tool.execute(category: 'all')
    assert result[:success]
    assert result.key?(:os_platform)
    assert result.key?(:cpu_model)
  end

  # Individual categories
  def test_category_os
    result = @tool.execute(category: 'os')
    assert result[:success]
    assert result.key?(:os_platform)
    assert result.key?(:hostname)
    refute result.key?(:cpu_model)
  end

  def test_category_cpu
    result = @tool.execute(category: 'cpu')
    assert result[:success]
    assert result.key?(:cpu_model)
    assert result.key?(:cpu_cores)
    refute result.key?(:os_platform)
  end

  def test_category_memory
    result = @tool.execute(category: 'memory')
    assert result[:success]
    assert result.key?(:memory_total_gb)
    assert result.key?(:memory_available_gb)
    refute result.key?(:os_platform)
  end

  def test_category_disk
    result = @tool.execute(category: 'disk')
    assert result[:success]
    assert result.key?(:disks)
    assert_kind_of Array, result[:disks]
    refute result.key?(:os_platform)
  end

  def test_category_ruby
    result = @tool.execute(category: 'ruby')
    assert result[:success]
    assert result.key?(:ruby_version)
    assert result.key?(:ruby_engine)
    assert result.key?(:rubygems_version)
    refute result.key?(:os_platform)
  end

  def test_unknown_category_falls_back_to_all
    result = @tool.execute(category: 'bogus')
    assert result[:success]
    assert result.key?(:os_platform)
    assert result.key?(:cpu_model)
  end

  def test_ruby_version_matches_current
    result = @tool.execute(category: 'ruby')
    assert result[:success]
    assert_equal RUBY_VERSION, result[:ruby_version]
  end

  def test_os_platform_is_a_string
    result = @tool.execute(category: 'os')
    assert result[:success]
    assert_kind_of String, result[:os_platform]
    refute result[:os_platform].empty?
  end

  def test_hostname_is_present
    result = @tool.execute(category: 'os')
    assert result[:success]
    assert result[:hostname]
    assert_kind_of String, result[:hostname]
  end

  def test_cpu_cores_is_positive_integer
    result = @tool.execute(category: 'cpu')
    assert result[:success]
    assert_kind_of Integer, result[:cpu_cores]
    assert result[:cpu_cores] > 0
  end

  def test_memory_total_is_positive
    result = @tool.execute(category: 'memory')
    assert result[:success]
    assert result[:memory_total_gb] > 0
  end
end
