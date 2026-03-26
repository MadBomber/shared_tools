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
