# frozen_string_literal: true

# Controls the memory for one VM. The VM must support ballooning otherwise nothing is done.
# The memory upgrade is instant, but the memory downgrade happens only once awhile.
#
# - `virt_cache` {VirtCache}
# - `vmid` {DomainId}
class Ballooning < Data.create(:virt_cache, :vmid)
  # Call every 2 seconds, to control the VM
  def update
    mem_stat = virt_cache.memstat(vmid)
    if mem_stat.nil?
      # VM is shut off. mark as back_off - we don't want to downgrade the memory
      # while the VM is booting up.
      back_off
      return
    end

    # If the VM has no support for ballooning, do nothing
    return unless mem_stat.guest_data_available?

    # 0..100
    percent_used = mem_stat.guest_mem.percent_used

    # 0..100
    memory_delta = 0

    if percent_used >= 80
      # Increase memory immediately
      memory_delta = 20
    elsif percent_used <= 60
      # decrease memory if not in back_off period
      memory_delta = -10 unless backing_off?
    end

    # Return early if nothing to do
    return if memory_delta.zero?

    info = virt_cache.info(vmid)
    return if info.nil?

    # calculate min/max memory
    max_memory = info.max_memory
    min_memory = (max_memory * 0.25).to_i
    # don't go below 1GB, or above max_memory
    min_memory_floor = 1 * 1024 * 1024 * 1024
    return if min_memory_floor > max_memory

    min_memory = min_memory.clamp(1 * 1024 * 1024 * 1024, max_memory)
    new_active = mem_stat.active * (memory_delta + 100) / 100
    new_active = new_active.clamp(min_memory..max_memory)
    return if new_active == mem_stat.active

    back_off
    virt_cache.set_active(vmid, new_active)
  end

  private

  # Back off from this VM - don't downgrade the memory for at least 10 seconds
  def back_off
    @back_off_since = Time.now
  end

  # @return [Boolean]
  def backing_off?
    return false if @back_off_since.nil?

    Time.now - @back_off_since >= 20
  end
end
