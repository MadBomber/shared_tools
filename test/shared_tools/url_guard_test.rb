# frozen_string_literal: true

require "test_helper"

class UrlGuardTest < Minitest::Test
  def setup
    @guard = SharedTools::UrlGuard.new
  end

  def test_allows_public_https_url
    resolution = @guard.resolve!("https://example.com")

    assert_equal "example.com", resolution.uri.host
    refute_nil resolution.address
  end

  def test_rejects_non_http_scheme
    assert_raises(SharedTools::UrlGuard::Blocked) { @guard.check!("ftp://example.com/file") }
  end

  def test_rejects_url_without_host
    assert_raises(SharedTools::UrlGuard::Blocked) { @guard.check!("http:///path") }
  end

  def test_rejects_embedded_credentials
    assert_raises(SharedTools::UrlGuard::Blocked) { @guard.check!("http://user:pass@example.com") }
  end

  def test_rejects_invalid_url
    assert_raises(SharedTools::UrlGuard::Blocked) { @guard.check!("not a url") }
  end

  def test_rejects_loopback_address
    assert_raises(SharedTools::UrlGuard::Blocked) { @guard.check!("http://127.0.0.1/") }
  end

  def test_rejects_cloud_metadata_address
    assert_raises(SharedTools::UrlGuard::Blocked) { @guard.check!("http://169.254.169.254/latest/meta-data/") }
  end

  def test_rejects_private_network_address
    assert_raises(SharedTools::UrlGuard::Blocked) { @guard.check!("http://10.0.0.5/") }
    assert_raises(SharedTools::UrlGuard::Blocked) { @guard.check!("http://192.168.1.1/") }
  end

  def test_rejects_ipv6_loopback
    assert_raises(SharedTools::UrlGuard::Blocked) { @guard.check!("http://[::1]/") }
  end

  def test_denylist_blocks_matching_host
    guard = SharedTools::UrlGuard.new(denylist: ["example.com"])

    assert_raises(SharedTools::UrlGuard::Blocked) { guard.check!("https://example.com") }
  end

  def test_denylist_blocks_subdomain
    guard = SharedTools::UrlGuard.new(denylist: ["example.com"])

    assert_raises(SharedTools::UrlGuard::Blocked) { guard.check!("https://sub.example.com") }
  end

  def test_allowlist_permits_only_listed_hosts
    guard = SharedTools::UrlGuard.new(allowlist: ["example.com"])

    guard.check!("https://example.com")
    assert_raises(SharedTools::UrlGuard::Blocked) { guard.check!("https://other-host-xyz.com") }
  end

  def test_resolve_returns_pinnable_address
    resolution = @guard.resolve!("https://example.com")

    assert_kind_of String, resolution.address
  end
end
