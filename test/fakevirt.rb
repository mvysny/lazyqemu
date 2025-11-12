require 'virt'

class Integer
  def GB
    self * 1024 * 1024 * 1024
  end
end

class FakeVirt
  def initialize
    @vms = {}
    @next_id = 1
  end

  # @return [CpuInfo]
  def hostinfo
    CpuInfo.new('fake', 1, 4, 2)
  end

  # Adds new running VM with given memory characteristics.
  # @return [String] VM name
  def dummy_vm_mem(actual, max, available, usable)
    raise 'invalid args' unless actual > max && max >= available && available > unused

    info = DomainInfo.new(1, max)
    disk_cache = 1.GB
    unused = usable - disk_cache
    rss = actual
    mem = MemStat.new(actual, unused, available, usable, disk_cache, rss)
    data = DomainData.new(info, :running, 1, 1, mem, [])
    add_vm(data)
  end

  private def generate_name
    name = "fake#{@next_id}"
    @next_id += 1
    name
  end

  private def add_vm(data)
    @vms[data.info.name] = data
    data.info.name
  end

  def dummy_stopped(cpus: 1)
    info = DomainInfo.new(generate_name, cpus, 1.GB)
    add_vm DomainData.new(info, :shut_off, 1, 1, nil, [])
  end

  def domain_data
    @vms
  end
end
