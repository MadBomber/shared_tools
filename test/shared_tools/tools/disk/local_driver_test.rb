# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"

class LocalDriverTest < Minitest::Test
  def setup
    @temp_dir = Dir.mktmpdir
    @root = File.join(@temp_dir, "root")
    FileUtils.mkdir_p(File.join(@root, "sub"))
    @outside = File.join(@temp_dir, "outside.txt")
    File.write(@outside, "outside")
    @driver = SharedTools::Tools::Disk::LocalDriver.new(root: @root)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
  end

  def test_resolve_normalizes_dot_dot_segments_for_read
    assert_raises(SecurityError) { @driver.file_read(path: "sub/../../outside.txt") }
  end

  def test_resolve_normalizes_dot_dot_segments_for_write
    assert_raises(SecurityError) { @driver.file_write(path: "sub/../../outside.txt", text: "changed") }
    assert_equal "outside", File.read(@outside)
  end

  def test_resolve_allows_dot_dot_segments_that_stay_inside_root
    @driver.file_write(path: "sub/../ok.txt", text: "inside")

    assert_equal "inside", File.read(File.join(@root, "ok.txt"))
    assert_equal "inside", @driver.file_read(path: "sub/../ok.txt")
  end

  def test_root_with_dot_dot_segments_still_resolves
    driver = SharedTools::Tools::Disk::LocalDriver.new(root: File.join(@root, "sub", ".."))
    driver.file_write(path: "ok.txt", text: "inside")

    assert_equal "inside", File.read(File.join(@root, "ok.txt"))
  end

  def test_resolve_checks_absolute_paths_against_root
    @driver.file_write(path: File.join(@root, "ok.txt"), text: "inside")

    assert_equal "inside", File.read(File.join(@root, "ok.txt"))
    assert_raises(SecurityError) { @driver.file_read(path: @outside) }
  end

  def test_relative_root_resolves_against_working_directory
    driver = Dir.chdir(@root) { SharedTools::Tools::Disk::LocalDriver.new(root: ".") }
    driver.file_write(path: "ok.txt", text: "inside")

    assert_equal "inside", File.read(File.join(@root, "ok.txt"))
    assert_raises(SecurityError) { driver.file_read(path: "../outside.txt") }

    driver = Dir.chdir(File.join(@root, "sub")) { SharedTools::Tools::Disk::LocalDriver.new(root: "..") }
    assert_raises(SecurityError) { driver.file_read(path: "../outside.txt") }
  end

  def test_resolve_normalizes_root_set_by_subclass
    # Mirrors the custom-driver example in docs/tools/disk.md, which sets @root without super.
    driver_class = Class.new(SharedTools::Tools::Disk::BaseDriver) do
      def initialize(root:) # rubocop:disable Lint/MissingSuper
        @root = Pathname.new(root)
      end
    end
    driver = driver_class.new(root: "#{@root}/")

    assert_equal Pathname(File.join(@root, "ok.txt")), driver.send(:resolve!, path: "ok.txt")
    assert_raises(SecurityError) { driver.send(:resolve!, path: "sub/../../outside.txt") }
  end
end
