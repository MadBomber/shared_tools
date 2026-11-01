# frozen_string_literal: true

require "test_helper"
require "shared_tools/mcp"

# Class-level checks only: nothing here starts a server, spawns npx or opens
# a connection (RubyLLM::MCP connects on the first request for tools).
class MCPClientsTest < Minitest::Test
  STDIO_SERVERS = {
    SharedTools::MCP::BraveSearch        => %w[npx -y @modelcontextprotocol/server-brave-search],
    SharedTools::MCP::Chart              => %w[npx -y @antv/mcp-server-chart],
    SharedTools::MCP::GitHub             => %w[github-mcp-server stdio],
    SharedTools::MCP::HuggingFace        => %w[hf-mcp-server],
    SharedTools::MCP::Memory             => %w[npx -y @modelcontextprotocol/server-memory],
    SharedTools::MCP::Notion             => %w[notion-mcp-server],
    SharedTools::MCP::Playwright         => %w[npx -y @playwright/mcp],
    SharedTools::MCP::SequentialThinking => %w[npx -y @modelcontextprotocol/server-sequential-thinking],
    SharedTools::MCP::Slack              => %w[slack-mcp-server]
  }.freeze

  def all_servers
    STDIO_SERVERS.keys + [SharedTools::MCP::Tavily]
  end

  def with_env(values)
    saved = values.keys.to_h { |k| [k, ENV.fetch(k, nil)] }
    values.each { |k, v| v.nil? ? ENV.delete(k) : ENV.store(k, v) }
    yield
  ensure
    saved.each { |k, v| v.nil? ? ENV.delete(k) : ENV.store(k, v) }
  end

  # Resolve a declared setting the way RubyLLM::MCP does when it connects.
  def resolved(klass, value)
    klass.new.send(:resolve, value)
  end

  def test_every_client_is_a_ruby_llm_mcp_subclass
    all_servers.each { |klass| assert_operator klass, :<, ::RubyLLM::MCP }
  end

  def test_registry_lists_every_client
    assert_equal all_servers.map(&:to_s).sort, SharedTools::MCP.clients.map(&:to_s).sort
  end

  def test_stdio_commands
    STDIO_SERVERS.each do |klass, argv|
      assert_equal argv, klass.command, klass.to_s
      assert_nil klass.url, klass.to_s
    end
  end

  def test_names_are_symbol_friendly
    all_servers.each { |klass| assert_match(/\A[a-z_]+\z/, klass.new.name, klass.to_s) }
    assert_equal "github", SharedTools::MCP::GitHub.new.name
    assert_equal "brave_search", SharedTools::MCP::BraveSearch.new.name
  end

  def test_tavily_is_a_remote_streamable_http_server
    klass = SharedTools::MCP::Tavily

    assert_equal "https://mcp.tavily.com/mcp/", klass.url
    assert_nil klass.command
    assert_equal 30, klass.timeout
    with_env("TAVILY_API_KEY" => "tvly-test") do
      assert_equal "tvly-test", resolved(klass, klass.bearer_token)
    end
  end

  def test_env_values_are_read_when_the_server_starts
    klass = SharedTools::MCP::GitHub

    with_env("GITHUB_PERSONAL_ACCESS_TOKEN" => "ghp-one") do
      assert_equal "ghp-one", resolved(klass, klass.env["GITHUB_PERSONAL_ACCESS_TOKEN"])
    end
    with_env("GITHUB_PERSONAL_ACCESS_TOKEN" => nil) do
      assert_equal "", resolved(klass, klass.env["GITHUB_PERSONAL_ACCESS_TOKEN"])
    end
  end

  def test_hugging_face_env_mapping
    klass = SharedTools::MCP::HuggingFace

    with_env("HF_TOKEN" => "hf-test") do
      assert_equal "stdio",   resolved(klass, klass.env["TRANSPORT"])
      assert_equal "hf-test", resolved(klass, klass.env["DEFAULT_HF_TOKEN"])
    end
  end

  def test_required_envars_and_availability
    with_env("NOTION_TOKEN" => nil) do
      assert_equal ["NOTION_TOKEN"], SharedTools::MCP::Notion.missing_envars
      refute SharedTools::MCP::Notion.available?
      assert_raises(LoadError) { SharedTools::MCP::Notion.verify! }
      refute_includes SharedTools::MCP.available, SharedTools::MCP::Notion
    end
    with_env("NOTION_TOKEN" => "ntn-test") do
      assert SharedTools::MCP::Notion.available?
      assert_equal SharedTools::MCP::Notion, SharedTools::MCP::Notion.verify!
      assert_includes SharedTools::MCP.available, SharedTools::MCP::Notion
    end
  end

  def test_keyless_clients_are_always_available
    [SharedTools::MCP::Chart, SharedTools::MCP::Memory,
     SharedTools::MCP::Playwright, SharedTools::MCP::SequentialThinking].each do |klass|
      assert klass.available?, klass.to_s
    end
  end

  def test_slack_needs_either_token
    with_env("SLACK_MCP_XOXP_TOKEN" => nil, "SLACK_MCP_XOXB_TOKEN" => nil) do
      refute SharedTools::MCP::Slack.available?
    end
    with_env("SLACK_MCP_XOXP_TOKEN" => nil, "SLACK_MCP_XOXB_TOKEN" => "xoxb-test") do
      assert SharedTools::MCP::Slack.available?
    end
  end

  def test_required_packages
    assert_equal ["github-mcp-server"], SharedTools::MCP::GitHub.requires_packages
    assert_equal [], SharedTools::MCP::Memory.requires_packages
  end

  def test_install_packages_delegates_to_package_install
    calls = []
    SharedTools.stub(:package_install, ->(*pkgs) { calls << pkgs }) do
      SharedTools::MCP::GitHub.install_packages!
      SharedTools::MCP::Chart.install_packages!
    end
    assert_equal [["github-mcp-server"]], calls
  end

  def test_loading_mcp_records_status_per_client
    SharedTools::MCP_LOG_MUTEX.synchronize { SharedTools.instance_variable_set(:@mcp_load_log, {}) }
    with_env("NOTION_TOKEN" => nil) do
      load File.expand_path("../../../lib/shared_tools/mcp.rb", __dir__)
    end

    assert_equal all_servers.map(&:default_name).sort,
                 (SharedTools.mcp_loaded + SharedTools.mcp_failed.keys).sort
    assert_equal "Missing envars: NOTION_TOKEN", SharedTools.mcp_failed["notion"]
    assert_includes SharedTools.mcp_loaded, "chart"
  ensure
    SharedTools::MCP_LOG_MUTEX.synchronize { SharedTools.instance_variable_set(:@mcp_load_log, {}) }
  end
end
