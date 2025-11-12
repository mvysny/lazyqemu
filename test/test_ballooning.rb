# frozen_string_literal: true

require 'minitest/autorun'
require 'ballooning'
require 'virt'
require 'virtcache'
require 'timecop'
require_relative 'fakevirt'

class TestBallooningVM < Minitest::Test
  def test_ballooning_does_nothing_on_stopped_machine
    virt = FakeVirt.new
    id = virt.dummy_stopped
    virt_cache = VirtCache.new(FakeVirt.new)

    b = BallooningVM.new(virt_cache, id)
    b.update
    Timecop.travel(Time.now + 200) do
      b.update
    end
  end
end
