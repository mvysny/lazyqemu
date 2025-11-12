# frozen_string_literal: true

require 'minitest/autorun'
require 'vm_emulator'
require 'timecop'

class TestVM < Minitest::Test
  def test_new_vm_not_running
    vm = VMEmulator::VM.simple('a')
    assert !vm.running?
    assert_nil vm.to_mem_stat
  end

  def test_started_vm_is_running
    vm = VMEmulator::VM.simple('a')
    vm.start
    assert vm.running?
  end

  def test_memory_usage_during_startup
    vm = VMEmulator::VM.simple('a')
    now = Time.now
    Timecop.freeze(now) do
      vm.start
      ms = vm.to_mem_stat
      assert_equal 'actual 2G(rss=1.1G); guest: 0/1.9G (0.0%) (unused=896M, disk_caches=1G)', ms.to_s
    end
    # the middle of guest OS startup
    Timecop.freeze(now + 5) do
      ms = vm.to_mem_stat
      assert_equal 'actual 2G(rss=1.6G); guest: 512M/1.9G (26.67%) (unused=384M, disk_caches=1G)', ms.to_s
    end
    # the end of guest OS startup
    Timecop.freeze(now + 10) do
      ms = vm.to_mem_stat
      assert_equal 'actual 2G(rss=2G); guest: 1G/1.9G (53.33%) (unused=0, disk_caches=896M)', ms.to_s
    end
    # guest OS is started for 5 seconds already
    Timecop.freeze(now + 15) do
      ms = vm.to_mem_stat
      assert_equal 'actual 2G(rss=2G); guest: 1G/1.9G (53%) (unused=0, disk_caches=896M)', ms.to_s
    end
  end

  def test_still_running_right_after_shutdown
    # shutdown takes 5 seconds
    vm = VMEmulator::VM.simple('a')
    now = Time.now
    Timecop.freeze(now) do
      vm.start
      vm.shut_down
      assert vm.running?
    end
    Timecop.freeze(now + 3) do
      assert vm.running?
    end
  end

  def test_not_running_when_fully_shutdown
    # shutdown takes 5 seconds
    vm = VMEmulator::VM.simple('a')
    now = Time.now
    Timecop.freeze(now) do
      vm.start
      vm.shut_down
    end
    Timecop.freeze(now + 5) do
      assert !vm.running?
    end
  end

  def test_mem_usage_during_shutdown
    # shutdown takes 5 seconds
    vm = VMEmulator::VM.simple('a')
    now = Time.now
    Timecop.freeze(now) do
      vm.start
    end
    Timecop.freeze(now + 20) do
      vm.shut_down
      ms = vm.to_mem_stat
      assert_equal 'actual 2G(rss=2G); guest: 1G/1.9G (53.33%) (unused=0, disk_caches=896M)', ms.to_s
    end
    Timecop.freeze(now + 22.5) do
      ms = vm.to_mem_stat
      assert_equal 'actual 2G(rss=1.6G); guest: 512M/1.9G (26.67%) (unused=384M, disk_caches=1G)', ms.to_s
    end
    Timecop.freeze(now + 25) do
      ms = vm.to_mem_stat
      assert_nil ms
    end
  end
end
