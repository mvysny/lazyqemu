require 'pastel'
require_relative 'virt'
require_relative 'sysinfo'

# Formats
class Formatter
  def initialize
    @p = Pastel.new
  end

  # Pretty-formats given object
  # @param what the object to format
  # @return [String] a Pastel-formatted object
  def format(what)
    return format_cpu(what) if what.is_a? CpuInfo
    return format_memory_stat(what) if what.is_a? MemoryStat
    return format_mem_stat(what) if what.is_a? MemStat
    return format_memory_usage(what) if what.is_a? MemoryUsage

    what.to_s # Fallback to :to_s
  end

  # @param cpu [CpuInfo]
  def format_cpu(cpu)
    r = "#{@p.bright_blue('CPU')}: #{@p.bright_blue(cpu.model)}: "
    r += "#{@p.cyan(cpu.cpus)}:#{cpu.sockets}/#{cpu.cores_per_socket}/#{cpu.threads_per_core} sockets/cores/threads"
    r
  end

  # @param memory_stat [MemoryStat]
  def format_memory_stat(memory_stat)
    "#{@p.bright_red('RAM')}: #{format(memory_stat.ram)}; #{@p.bright_red('SWAP')}: #{format(memory_stat.swap)}"
  end

  # @param memory_usage [MemoryUsage]
  def format_memory_usage(memory_usage)
    r = "#{@p.cyan(format_byte_size(memory_usage.used))}/#{@p.cyan(format_byte_size(memory_usage.total))}"
    r += " (#{@p.cyan(memory_usage.percent_used)}%)"
    r
  end

  # @param state [Symbol] one of `:running`, `:shut_off`, `:paused`
  def format_domain_state(state)
    case state
    when :running then @p.green('running')
    when :shut_off then @p.red('shut_off')
    else; @p.yellow(state)
    end
  end

  # @param mem_stat [MemStat]
  def format_mem_stat(mem_stat)
    result = "Host:#{format(mem_stat.host_mem)}"
    result += " Guest:#{format(mem_stat.guest_mem)}" unless mem_stat.guest_mem.nil?
    result
  end
end
