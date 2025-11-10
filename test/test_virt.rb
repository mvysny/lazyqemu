# frozen_string_literal: true

require 'minitest/autorun'
require 'virt'

VIRSH_DOMAINS = <<~EOF
   Id   Name                 State
  -------------------------------------
   5    Flow                 running
   -    BASE                 shut off
   -    win11                shut off
EOF

VIRSH_DOMMEMSTAT = <<~EOF
  actual 4194304
  swap_in 0
  swap_out 0
  major_fault 1469
  minor_fault 952105
  unused 519476
  available 3390244
  usable 2029636
  last_update 1762236063
  disk_caches 1813252
  hugetlb_pgalloc 0
  hugetlb_pgfail 0
  rss 3663796
EOF

VIRSH_DOMMEMSTAT_WIN = <<~EOF
  actual 8388608
  last_update 0
  rss 1598808
EOF

VIRSH_DOMINFO = <<~EOF
  Id:             -
  Name:           Flow
  UUID:           709f69ce-37d4-4eb6-a218-69617d2388ba
  OS Type:        hvm
  State:          shut off
  CPU(s):         8
  Max memory:     8388608 KiB
  Used memory:    4194304 KiB
  Persistent:     yes
  Autostart:      disable
  Autostart Once: disable
  Managed save:   no
  Security model: apparmor
  Security DOI:   0
EOF

VIRSH_NODEINFO = <<~EOF
  CPU model:           x86_64
  CPU(s):              16
  CPU frequency:       1397 MHz
  CPU socket(s):       1
  Core(s) per socket:  8
  Thread(s) per core:  2
  NUMA cell(s):        1
  Memory size:         29987652 KiB
EOF

class TestVirt < Minitest::Test
  def initialize(arg)
    super(arg)
    @dummy_domain = Domain.new(DomainId.new(5, 'dummy'), :running)
  end

  def test_domains
    d = VirtCmd.new.domains VIRSH_DOMAINS
    assert_equal '5: Flow: running, BASE: shut_off, win11: shut_off', d.join(', ')
  end

  def test_memstat
    m = VirtCmd.new.memstat(@dummy_domain, VIRSH_DOMMEMSTAT)
    assert_equal '4G(rss=3.5G); guest: 1.3G/3.2G (40%) (unused=507M, disk_caches=1.7G)', m.to_s
  end

  def test_memstat_win
    m = VirtCmd.new.memstat(@dummy_domain, VIRSH_DOMMEMSTAT_WIN)
    assert_equal '8G(rss=1.5G)', m.to_s
  end

  def test_dominfo
    info = VirtCmd.new.dominfo(@dummy_domain, VIRSH_DOMINFO)
    assert_equal 'hvm: shut_off; CPUs: 8; configured mem: 4G/8G (50%)', info.to_s
  end

  def test_hostinfo
    info = VirtCmd.new.hostinfo(VIRSH_NODEINFO)
    assert_equal 'x86_64: 1/8/2', info.to_s
  end

  def test_domain_data_parse
    result = VirtCmd.new.domain_data(File.read('test/domstats0.txt'), 0)
    assert_equal 2, result.size
    assert_equal ': running; CPUs: 8; configured mem: 12G/12G (100%), 12G(rss=3.4G); guest: 241M/11G (2%) (unused=11G, disk_caches=37M)',
                 result['ubuntu'].to_s
    assert_equal ': shut_off; CPUs: 4; configured mem: 8G/8G (100%), 8G(rss=0)', result['win11'].to_s
    assert_equal 'sda: 18G/128G (13.99%); physical 18G (2.88% overhead)', result['win11'].disk_stat.join(',')
    assert_equal 'vda: 23G/64G (36.02%); physical 25G (9.31% overhead)', result['ubuntu'].disk_stat.join(',')
  end

  def test_domain_data_cpu_usage
    millis_since_epoch = 1_762_378_459_933
    result0 = VirtCmd.new.domain_data(File.read('test/domstats0.txt'), millis_since_epoch)['ubuntu']
    result1 = VirtCmd.new.domain_data(File.read('test/domstats1.txt'), millis_since_epoch + 10 * 1000)['ubuntu']
    assert_equal 22.51, result1.cpu_usage(result0).round(2)
    result2 = VirtCmd.new.domain_data(File.read('test/domstats2.txt'), millis_since_epoch + 20 * 1000)['ubuntu']
    assert_equal 181.43, result2.cpu_usage(result1).round(2)
  end
end

class TestDiskStat < Minitest::Test
  def test_to_s
    ds = DiskStat.new('vda', 20_348_669_952, 68_719_476_736, 20_452_605_952)
    assert_equal 'vda: 19G/64G (29.61%); physical 19G (0.51% overhead)', ds.to_s
    ds = DiskStat.new('sda', 18_022_993_920, 137_438_953_472, 23_508_287_488)
    assert_equal 'sda: 17G/128G (13.11%); physical 22G (30.43% overhead)', ds.to_s
  end
end
