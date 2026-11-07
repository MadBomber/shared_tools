# frozen_string_literal: true

require "test_helper"
require "open3"
require "rbconfig"

class DefaultDriverTest < Minitest::Test
  def driver_selector = SharedTools::Tools::Browser::DefaultDriver

  def test_prefers_ferrum
    driver_selector.stub(:gem_loaded?, true) do
      assert_equal SharedTools::Tools::Browser::FerrumDriver, driver_selector.driver_class
    end
  end

  def test_falls_back_to_watir
    driver_selector.stub(:gem_loaded?, ->(name) { name == "watir" }) do
      assert_equal SharedTools::Tools::Browser::WatirDriver, driver_selector.driver_class
    end
  end

  def test_build_raises_load_error_without_a_driver_gem
    driver_selector.stub(:gem_loaded?, false) do
      assert_nil driver_selector.driver_class
      error = assert_raises(LoadError) { driver_selector.build(logger: Logger.new(IO::NULL)) }
      assert_match(/ferrum/, error.message)
    end
  end

  def test_gem_loaded_reports_missing_gems
    refute driver_selector.gem_loaded?("shared_tools_no_such_gem")
  end

  # Issue #3: under aia, `SharedTools.load_all_tools` loads BrowserTool but
  # nothing requires ferrum or watir, so `defined?(Watir)` was false even with
  # the gem installed. Run in a fresh process so this suite's own requires
  # can't hide that.
  def test_browser_tool_finds_an_installed_driver_gem_in_a_fresh_process
    skip "neither ferrum nor watir is installed" unless %w[ferrum watir].any? { |name| Gem::Specification.find_all_by_name(name).any? }

    script = <<~RUBY
      require "shared_tools"
      SharedTools.load_all_tools
      exit(SharedTools::Tools::BrowserTool.new.available? ? 0 : 1)
    RUBY
    lib = File.expand_path("../../../../lib", __dir__)
    _out, err, status = Open3.capture3(RbConfig.ruby, "-I", lib, "-e", script)

    assert status.success?, "BrowserTool#available? was false with a driver gem installed\n#{err}"
  end
end
