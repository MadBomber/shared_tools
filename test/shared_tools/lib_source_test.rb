# frozen_string_literal: true

require 'test_helper'

# Checks on the source files under lib/ themselves.
class LibSourceTest < Minitest::Test
  LIB = File.expand_path('../../lib', __dir__)

  def test_no_raw_nul_bytes_in_lib
    binary = Dir.glob("#{LIB}/**/*.rb").select { |path| File.binread(path).include?("\0") }

    assert_empty binary, 'raw NUL byte found; write it as "\0" so git and grep treat the file as text'
  end
end
