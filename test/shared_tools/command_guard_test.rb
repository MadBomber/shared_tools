# frozen_string_literal: true

require "test_helper"

class CommandGuardTest < Minitest::Test
  def test_allows_listed_command
    guard = SharedTools::CommandGuard.new(["echo", "ls"])

    assert_equal "echo", guard.check!("echo")
  end

  def test_rejects_unlisted_command
    guard = SharedTools::CommandGuard.new(["echo"])

    assert_raises(SharedTools::CommandGuard::Blocked) { guard.check!("rm") }
  end

  def test_rejects_empty_allowlist_by_default
    guard = SharedTools::CommandGuard.new([])

    assert_raises(SharedTools::CommandGuard::Blocked) { guard.check!("echo") }
  end

  def test_rejects_empty_command
    guard = SharedTools::CommandGuard.new(["echo"])

    assert_raises(SharedTools::CommandGuard::Blocked) { guard.check!("") }
  end

  def test_rejects_path_in_command
    guard = SharedTools::CommandGuard.new(["/bin/echo"])

    assert_raises(SharedTools::CommandGuard::Blocked) { guard.check!("/bin/echo") }
    assert_raises(SharedTools::CommandGuard::Blocked) { guard.check!("../echo") }
  end

  def test_rejects_shell_metacharacters
    guard = SharedTools::CommandGuard.new(["echo"])

    assert_raises(SharedTools::CommandGuard::Blocked) { guard.check!("echo;rm") }
    assert_raises(SharedTools::CommandGuard::Blocked) { guard.check!("echo|cat") }
    assert_raises(SharedTools::CommandGuard::Blocked) { guard.check!("echo`whoami`") }
    assert_raises(SharedTools::CommandGuard::Blocked) { guard.check!("$(echo)") }
  end
end
