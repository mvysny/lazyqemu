# frozen_string_literal: true

require 'minitest/autorun'
require 'virtcache'
require_relative 'fakevirt'

class TestVirtCache < Minitest::Test
  def test_smoke
    fv = FakeVirt.new
    fv.dummy_stopped
    VirtCache.new(fv)
  end
end
