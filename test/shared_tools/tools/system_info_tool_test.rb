# frozen_string_literal: true

require "test_helper"

class SystemInfoToolTest < Minitest::Test
  def setup
    @tool = SharedTools::Tools::SystemInfoTool.new
  end

  def test_tool_name
    assert_equal 'system_info', SharedTools::Tools::SystemInfoTool.name
  end

  def test_inherits_from_ruby_llm_tool
    assert_kind_of ::RubyLLM::Tool, @tool
  end

  def test_can_instantiate_without_arguments
    tool = SharedTools::Tools::SystemInfoTool.new
    assert_instance_of SharedTools::Tools::SystemInfoTool, tool
  end

  def test_all_category_returns_complete_info
    result = @tool.execute(category: 'all')

    assert result[:success]
    assert result[:os]
    assert result[:cpu]
    assert result[:memory]
    assert result[:disk]
    assert result[:network]
    assert result[:ruby]
  end

  def test_default_category_is_all
    result = @tool.execute

    assert result[:success]
    assert result[:os]
    assert result[:cpu]
    assert result[:memory]
  end

  def test_os_category_returns_os_info
    result = @tool.execute(category: 'os')

    assert result[:success]
    assert result[:os]
    assert result[:os][:hostname]
    assert result[:os][:architecture]

    # Should not include other categories at top level
    refute result[:cpu]
    refute result[:memory]
  end

  def test_cpu_category_returns_cpu_info
    result = @tool.execute(category: 'cpu')

    assert result[:success]
    assert result[:cpu]
    assert result[:cpu][:cores]
    assert result[:cpu][:architecture]

    # Should not include other categories
    refute result[:os]
    refute result[:memory]
  end

  def test_memory_category_returns_memory_info
    result = @tool.execute(category: 'memory')

    assert result[:success]
    assert result[:memory]
    assert result[:memory][:total]
    assert result[:memory][:available]
    assert result[:memory][:used]
    assert result[:memory][:percent_used]

    # Should not include other categories
    refute result[:os]
    refute result[:cpu]
  end

  def test_disk_category_returns_disk_info
    result = @tool.execute(category: 'disk')

    assert result[:success]
    assert result[:disk]
    assert_kind_of Array, result[:disk]

    # Should have at least one disk
    assert result[:disk].length >= 1

    # Each disk should have expected fields
    disk = result[:disk].first
    assert disk[:filesystem] || disk[:mount_point]
    assert disk[:size]
  end

  def test_network_category_returns_network_info
    result = @tool.execute(category: 'network')

    assert result[:success]
    assert result[:network]
    assert_kind_of Array, result[:network]

    # Should have at least one interface with addresses
    if result[:network].length > 0
      interface = result[:network].first
      assert interface[:name]
      assert interface[:addresses]
    end
  end

  def test_unknown_category_returns_error
    result = @tool.execute(category: 'unknown')

    refute result[:success]
    assert_includes result[:error], "Unknown category: unknown"
    assert_includes result[:error], "Valid categories are"
  end

  def test_category_is_case_insensitive
    result_lower = @tool.execute(category: 'memory')
    result_upper = @tool.execute(category: 'MEMORY')
    result_mixed = @tool.execute(category: 'Memory')

    assert result_lower[:success]
    assert result_upper[:success]
    assert result_mixed[:success]
  end

  def test_memory_values_are_reasonable
    result = @tool.execute(category: 'memory')

    assert result[:success]

    # Total memory should be greater than 0
    assert result[:memory][:total_bytes] > 0

    # Used should be less than or equal to total
    assert result[:memory][:used_bytes] <= result[:memory][:total_bytes]

    # Percent used should be between 0 and 100
    assert result[:memory][:percent_used] >= 0
    assert result[:memory][:percent_used] <= 100
  end

  def test_cpu_cores_is_positive
    result = @tool.execute(category: 'cpu')

    assert result[:success]
    assert result[:cpu][:cores] > 0
  end

  def test_ruby_info_matches_current_version
    result = @tool.execute(category: 'all')

    assert result[:success]
    assert_equal RUBY_VERSION, result[:ruby][:version]
    assert_equal RUBY_PLATFORM, result[:ruby][:platform]
    assert_equal RUBY_ENGINE, result[:ruby][:engine]
  end

  def test_hostname_is_present
    result = @tool.execute(category: 'os')

    assert result[:success]
    refute_empty result[:os][:hostname]
  end

  def test_architecture_is_present
    result = @tool.execute(category: 'os')

    assert result[:success]
    refute_empty result[:os][:architecture]
  end
end
