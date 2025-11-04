require 'minitest/autorun'
require 'sysinfo'

class TestMemoryUsage < Minitest::Test
  def test_format_byte_size
    assert_equal '0', format_byte_size(0)
    assert_equal '999', format_byte_size(999)
    assert_equal '1000', format_byte_size(1000)
    assert_equal '1023', format_byte_size(1023)
    assert_equal '1 K', format_byte_size(1024)
    assert_equal '-1 K', format_byte_size(-1024)
    assert_equal '1.5 K', format_byte_size(1536)
    assert_equal '4.9 K', format_byte_size(5000)
    assert_equal '24 M', format_byte_size(25_000_000)
    assert_equal '8 G', format_byte_size(8_589_934_592)
    assert_equal '8.0 G', format_byte_size(8_590_000_000)
  end

  def test_to_s
    assert_equal '0/0 (0%)', MemoryUsage.new(0, 0).to_s
    assert_equal '24/48 (50%)', MemoryUsage.new(48, 24).to_s
    assert_equal '228 M/459 M (49%)', MemoryUsage.new(481231286, 242134623).to_s
    assert_equal '2.2 G/4.5 G (49%)', MemoryUsage.new(4812312860, 2421346230).to_s
  end
end

class TestSysInfo < Minitest::Test
  def test_memory_stats
    s = SysInfo.new.memory_stats PROC_MEMINFO
    assert_equal 'RAM: 5.9 G/58 G (10%), SWAP: 0/8.0 G (0%)', s.to_s
  end
end

PROC_MEMINFO=<<EOF
MemTotal:       60432620 kB
MemFree:        34851344 kB
MemAvailable:   54292748 kB
Buffers:           18852 kB
Cached:         19671048 kB
SwapCached:            0 kB
Active:          7395780 kB
Inactive:       16769528 kB
Active(anon):    4268016 kB
Inactive(anon):        0 kB
Active(file):    3127764 kB
Inactive(file): 16769528 kB
Unevictable:       17916 kB
Mlocked:           17916 kB
SwapTotal:       8388604 kB
SwapFree:        8388604 kB
Zswap:                 0 kB
Zswapped:              0 kB
Dirty:              3364 kB
Writeback:           148 kB
AnonPages:       4494000 kB
Mapped:          1524448 kB
Shmem:            320344 kB
KReclaimable:     213328 kB
Slab:             651168 kB
SReclaimable:     213328 kB
SUnreclaim:       437840 kB
KernelStack:       30512 kB
PageTables:        63836 kB
SecPageTables:      4332 kB
NFS_Unstable:          0 kB
Bounce:                0 kB
WritebackTmp:          0 kB
CommitLimit:    38604912 kB
Committed_AS:   16070836 kB
VmallocTotal:   34359738367 kB
VmallocUsed:      118656 kB
VmallocChunk:          0 kB
Percpu:            23104 kB
HardwareCorrupted:     0 kB
AnonHugePages:         0 kB
ShmemHugePages:        0 kB
ShmemPmdMapped:        0 kB
FileHugePages:         0 kB
FilePmdMapped:         0 kB
CmaTotal:              0 kB
CmaFree:               0 kB
Unaccepted:            0 kB
Balloon:               0 kB
HugePages_Total:       0
HugePages_Free:        0
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:       2048 kB
Hugetlb:               0 kB
DirectMap4k:      598804 kB
DirectMap2M:    20146176 kB
DirectMap1G:    42991616 kB
EOF

