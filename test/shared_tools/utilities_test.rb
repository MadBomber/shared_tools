# frozen_string_literal: true

require "test_helper"

class UtilitiesTest < Minitest::Test

  # -------------------------------------------------------------------------
  # Helpers
  # -------------------------------------------------------------------------

  # Temporarily set / unset environment variables and restore afterwards.
  def with_env(vars)
    old = vars.each_key.with_object({}) { |k, h| h[k] = ENV[k] }
    vars.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    old.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  # Define a temporary singleton method named +name+ on +SharedTools+,
  # yield, then remove it. Used to override private Kernel methods such as
  # +system+ and <tt>`</tt> that are called without an explicit receiver
  # inside the utilities methods.
  def stub_kernel_method(name, return_value)
    SharedTools.define_singleton_method(name) { |*| return_value }
    yield
  ensure
    SharedTools.singleton_class.remove_method(name)
  end

  # Stub +system+ with a callable so successive calls can return different values.
  def stub_system_callable(callable)
    SharedTools.define_singleton_method(:system) { |*args| callable.call(*args) }
    yield
  ensure
    SharedTools.singleton_class.remove_method(:system)
  end

  # -------------------------------------------------------------------------
  # MCP load tracking
  # -------------------------------------------------------------------------

  def setup
    # Reset the load log before every test
    SharedTools::MCP_LOG_MUTEX.synchronize { SharedTools.instance_variable_set(:@mcp_load_log, {}) }
  end

  def test_mcp_loaded_returns_empty_array_when_nothing_recorded
    assert_equal [], SharedTools.mcp_loaded
  end

  def test_mcp_failed_returns_empty_hash_when_nothing_recorded
    assert_equal({}, SharedTools.mcp_failed)
  end

  def test_record_mcp_result_records_success
    SharedTools.record_mcp_result("tavily")
    assert_includes SharedTools.mcp_loaded, "tavily"
    assert_empty SharedTools.mcp_failed
  end

  def test_record_mcp_result_records_failure_with_reason
    err = LoadError.new("Missing envars: TAVILY_API_KEY")
    SharedTools.record_mcp_result("tavily", error: err)

    assert_empty SharedTools.mcp_loaded
    assert_equal "Missing envars: TAVILY_API_KEY", SharedTools.mcp_failed["tavily"]
  end

  def test_mcp_loaded_returns_only_successful_clients
    SharedTools.record_mcp_result("github")
    SharedTools.record_mcp_result("tavily", error: LoadError.new("missing key"))
    SharedTools.record_mcp_result("memory")

    assert_equal %w[github memory].sort, SharedTools.mcp_loaded.sort
  end

  def test_mcp_failed_returns_only_failed_clients
    SharedTools.record_mcp_result("github")
    SharedTools.record_mcp_result("tavily", error: LoadError.new("missing key"))
    SharedTools.record_mcp_result("notion", error: LoadError.new("missing token"))

    assert_equal %w[tavily notion].sort, SharedTools.mcp_failed.keys.sort
    assert_equal "missing key",   SharedTools.mcp_failed["tavily"]
    assert_equal "missing token", SharedTools.mcp_failed["notion"]
  end

  def test_mcp_status_outputs_summary_and_returns_log
    SharedTools.record_mcp_result("github")
    SharedTools.record_mcp_result("tavily", error: LoadError.new("Missing envars: TAVILY_API_KEY"))

    out, _ = capture_io { SharedTools.mcp_status }

    assert_match "github",         out
    assert_match "tavily",         out
    assert_match "TAVILY_API_KEY", out
    assert_match "1 loaded",       out
    assert_match "1 skipped",      out
  end

  def test_mcp_status_returns_empty_message_when_nothing_loaded
    out, _ = capture_io { SharedTools.mcp_status }
    assert_match "No MCP clients", out
  end

  def test_record_mcp_result_is_thread_safe
    threads = 20.times.map do |i|
      Thread.new { SharedTools.record_mcp_result("client-#{i}") }
    end
    threads.each(&:join)

    assert_equal 20, SharedTools.mcp_loaded.size
  end

  # -------------------------------------------------------------------------
  # verify_envars
  # -------------------------------------------------------------------------

  def test_verify_envars_passes_when_all_vars_present
    with_env("SHARED_TOOLS_TEST_A" => "hello", "SHARED_TOOLS_TEST_B" => "world") do
      # Should not raise
      SharedTools.verify_envars("SHARED_TOOLS_TEST_A", "SHARED_TOOLS_TEST_B")
    end
  end

  def test_verify_envars_raises_load_error_when_var_missing
    with_env("SHARED_TOOLS_TEST_A" => nil) do
      error = assert_raises(LoadError) do
        SharedTools.verify_envars("SHARED_TOOLS_TEST_A")
      end
      assert_match "SHARED_TOOLS_TEST_A", error.message
    end
  end

  def test_verify_envars_raises_with_all_missing_var_names_in_message
    with_env("SHARED_TOOLS_TEST_A" => nil, "SHARED_TOOLS_TEST_B" => nil) do
      error = assert_raises(LoadError) do
        SharedTools.verify_envars("SHARED_TOOLS_TEST_A", "SHARED_TOOLS_TEST_B")
      end
      assert_match "SHARED_TOOLS_TEST_A", error.message
      assert_match "SHARED_TOOLS_TEST_B", error.message
    end
  end

  def test_verify_envars_treats_empty_string_as_missing
    with_env("SHARED_TOOLS_TEST_A" => "") do
      assert_raises(LoadError) do
        SharedTools.verify_envars("SHARED_TOOLS_TEST_A")
      end
    end
  end

  def test_verify_envars_only_reports_missing_vars_not_present_ones
    with_env("SHARED_TOOLS_TEST_A" => "present", "SHARED_TOOLS_TEST_B" => nil) do
      error = assert_raises(LoadError) do
        SharedTools.verify_envars("SHARED_TOOLS_TEST_A", "SHARED_TOOLS_TEST_B")
      end
      refute_match "SHARED_TOOLS_TEST_A", error.message
      assert_match "SHARED_TOOLS_TEST_B", error.message
    end
  end

  def test_verify_envars_passes_with_single_var_present
    with_env("SHARED_TOOLS_TEST_A" => "value") do
      SharedTools.verify_envars("SHARED_TOOLS_TEST_A")  # should not raise
    end
  end

  def test_verify_envars_raises_load_error_which_is_a_script_error_not_standard_error
    # LoadError < ScriptError < Exception — NOT a StandardError.
    # This matters in mcp.rb where `rescue => e` (StandardError only) would let
    # the LoadError escape the thread, triggering "terminated with exception".
    # The loader must use `rescue Exception => e` to catch it.
    with_env("SHARED_TOOLS_TEST_A" => nil) do
      error = assert_raises(LoadError) do
        SharedTools.verify_envars("SHARED_TOOLS_TEST_A")
      end
      assert_kind_of ScriptError, error
      refute_kind_of StandardError, error
    end
  end

  # -------------------------------------------------------------------------
  # brew_install
  # -------------------------------------------------------------------------

  def test_brew_install_raises_load_error_when_brew_not_found
    stub_kernel_method(:system, false) do
      error = assert_raises(LoadError) do
        SharedTools.brew_install("some-package")
      end
      assert_match "Homebrew", error.message
    end
  end

  def test_brew_install_skips_already_installed_package
    # system("which brew") → true; brew list --versions → non-empty (installed)
    stub_kernel_method(:system, true) do
      stub_kernel_method(:`, "some-package 1.0.0") do
        # Must not raise
        SharedTools.brew_install("some-package")
      end
    end
  end

  def test_brew_install_raises_when_package_install_fails
    # First system call is "which brew" → true; second is "brew install" → false
    calls = 0
    callable = ->(*) { calls += 1; calls == 1 }
    stub_system_callable(callable) do
      stub_kernel_method(:`, "") do           # brew list returns empty → not installed
        error = assert_raises(LoadError) do
          SharedTools.brew_install("bad-package")
        end
        assert_match "bad-package", error.message
        assert_match "could not be installed", error.message
      end
    end
  end

  def test_brew_install_succeeds_when_package_installs_cleanly
    stub_kernel_method(:system, true) do     # which brew → true; brew install → true
      stub_kernel_method(:`, "") do          # brew list returns empty → not yet installed
        SharedTools.brew_install("new-package")  # should not raise
      end
    end
  end

  # -------------------------------------------------------------------------
  # npm_install
  # -------------------------------------------------------------------------

  def test_npm_install_raises_when_npm_not_found
    stub_kernel_method(:system, false) do
      error = assert_raises(LoadError) do
        SharedTools.npm_install("some-npm-package")
      end
      assert_match "npm", error.message
    end
  end

  def test_npm_install_skips_already_installed_package
    stub_kernel_method(:system, true) do
      # system("which pkg") returns true → already in PATH → skip
      SharedTools.npm_install("some-npm-package")
    end
  end

  def test_npm_install_raises_when_package_install_fails
    # npm present (first call true); package not in PATH (second call false); install fails (third false)
    calls = 0
    callable = ->(*) { calls += 1; [true, false, false][calls - 1] }
    stub_system_callable(callable) do
      error = assert_raises(LoadError) do
        SharedTools.npm_install("bad-npm-package")
      end
      assert_match "bad-npm-package", error.message
      assert_match "could not be installed", error.message
    end
  end

  # -------------------------------------------------------------------------
  # gem_install
  # -------------------------------------------------------------------------

  def test_gem_install_raises_when_gem_binary_not_found
    stub_kernel_method(:system, false) do
      error = assert_raises(LoadError) do
        SharedTools.gem_install("some-gem")
      end
      assert_match "gem", error.message
    end
  end

  def test_gem_install_skips_already_installed_gem
    # gem present (true) and gem list -i returns true → already installed
    stub_kernel_method(:system, true) do
      SharedTools.gem_install("already-installed-gem")
    end
  end

  def test_gem_install_raises_when_install_fails
    # gem present; gem list -i returns false (not installed); gem install returns false
    calls = 0
    callable = ->(*) { calls += 1; [true, false, false][calls - 1] }
    stub_system_callable(callable) do
      error = assert_raises(LoadError) do
        SharedTools.gem_install("bad-gem")
      end
      assert_match "bad-gem", error.message
      assert_match "could not be installed", error.message
    end
  end

  # -------------------------------------------------------------------------
  # package_install — platform delegation
  # -------------------------------------------------------------------------

  def test_package_install_delegates_to_brew_install_on_darwin
    # Verify that on darwin the brew_install path is followed — if brew is
    # absent it should raise the Homebrew-specific error, not a platform error.
    skip "Only relevant on macOS" unless RUBY_PLATFORM =~ /darwin/

    stub_kernel_method(:system, false) do
      error = assert_raises(LoadError) do
        SharedTools.package_install("any-package")
      end
      assert_match "Homebrew", error.message
    end
  end

  def test_package_install_raises_for_unsupported_platform
    # Temporarily override RUBY_PLATFORM by stubbing package_install itself
    # to exercise the else branch; instead, test via the constant directly.
    # Since we cannot change the constant at runtime we verify the error message
    # format by pattern-matching against the actual platform string.
    skip "Skipped on darwin and linux — tested via integration" if RUBY_PLATFORM =~ /darwin|linux/

    assert_raises(LoadError) do
      SharedTools.package_install("any-package")
    end
  end

end
