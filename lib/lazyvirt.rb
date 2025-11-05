require 'virt'
require 'window'
require 'sysinfo'
require 'tty-cursor'
require 'tty-screen'
require 'rufus-scheduler'
require 'io/console'

scheduler = Rufus::Scheduler.new

virt = VirtCmd.new
#virt = LibVirtClient.new

class Formatter
  def initialize
    @p = Pastel.new
  end
  def format(what)
    return format_cpu(what) if what.is_a? CpuInfo
    return format_memory_stat(what) if what.is_a? MemoryStat
    return format_memory_usage(what) if what.is_a? MemoryUsage
    what.to_s
  end
  def format_cpu(cpu)
    "#{@p.cyan.bold(cpu.model)}: #{@p.cyan(cpu.cpus)}:#{cpu.sockets}/#{cpu.cores_per_socket}/#{cpu.threads_per_core} sockets/cores/threads"
  end
  def format_memory_stat(ms)
    "#{@p.bright_red('RAM')}: #{format(ms.ram)}; #{@p.bright_blue('SWAP')}: #{format(ms.swap)}"
  end
  def format_memory_usage(mu)
    "#{@p.cyan(format_byte_size(mu.used))}/#{@p.cyan(format_byte_size(mu.total))} (#{@p.cyan(mu.percent_used)}%)"
  end
  def format_domain(domain, virt)
  end
end

class SystemWindow < Window
  # @param virt [VirtCmd | LibVirtClient]
  def initialize(virt)
    super('System')
    @f = Formatter.new
    @cpu = @f.format(virt.hostinfo)
    update
  end
  
  def update
    content do |lines|
      lines << @cpu
      stats = SysInfo.new.memory_stats
      lines << @f.format(stats)
    end
  end
end

class VMWindow < Window
  # @param virt [VirtCmd | LibVirtClient]
  def initialize(virt)
    super('[1]-VMs')
    @f = Formatter.new
    @virt = virt
    update
  end
  
  def update
    domains = @virt.domains.sort_by(&:name)    # Array<Domain>
    content do |lines|
      domains.each do |domain|
        lines << domain.name
        lines << @virt.dominfo(domain)
        lines << @virt.memstat(domain) if domain.running?
      end
    end
  end
end

class Screen
  def initialize(virt)
    @f = Formatter.new
    @virt = virt
    @system = SystemWindow.new(virt)
    @vms = VMWindow.new(virt)
  end
  
  # Clears the TTY screen
  def clear
    print TTY::Cursor.move_to(0, 0), TTY::Cursor.clear_screen
  end
  
  def calculate_window_sizes
    clear
    sh, sw = TTY::Screen.size
    left_pane_w = sw / 2
    @system.rect = Rect.new(0, 0, left_pane_w, 4)
    @vms.rect = Rect.new(0, 4, left_pane_w, 10)
  end
  
  def update_data
    @system.update
    @vms.update
  end
end

screen = Screen.new(virt)
screen.calculate_window_sizes

# Trap the WINCH signal (sent on terminal resize)
trap("WINCH") do
  screen.calculate_window_sizes
end

# https://github.com/jmettraux/rufus-scheduler
scheduler.every '3s' do
  screen.update_data
end

loop do
  char = STDIN.getch
  break if char == 'q'

  # Show the code point (helps debug escape sequences)
  printf "Got: %p (ord: %d)\n", char, char.ord
end

scheduler.shutdown
screen.clear
