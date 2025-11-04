require 'virt'
require 'window'
require 'sysinfo'
require 'tty-cursor'

virt = VirtCmd.new

# Clears the TTY screen
def clear_screen
  print TTY::Cursor.move_to(0, 0), TTY::Cursor.clear_screen
end

domains = virt.domains

clear_screen
lines = []
lines << SysInfo.new.memory_stats.to_s
domains.each do |domain|
  lines << domain
  lines << virt.dominfo(domain)
  lines << virt.memstat(domain) if domain.running?
end

w = Window.new('VMs')
w.rect = Rect.new(4, 2, 150, 16)
w.content = lines

sleep 1

