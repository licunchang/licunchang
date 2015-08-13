**File Name** linux-performance-analysis-tools.md  

**Description** Linux 性能分析工具    
**Author** LiCunchang(printf@live.com)  
**Version** 2.0.20131218  

------

## Chapter 1. General Notes on System Tuning

### 1.1 Be Sure What Problem to Solve


### 1.2 Rule Out Common Problems
















## 基本工具

* uptime    

        [root@localhost /]# uptime
        16:56:47 up 22 days,  4:53,  1 user,  load average: 0.00, 0.00, 0.00

    从左到右，分别是

        [当前时间] up [系统运行时间], [当前登录用户数], load average: [过去 1 分钟系统负载], [过去 5 分钟系统负载], [过去 15 分钟系统负载]

    SEE ALSO 

        [root@localhost /]# w
         16:59:57 up 22 days,  4:56,  1 user,  load average: 0.00, 0.00, 0.00
        USER     TTY      FROM              LOGIN@   IDLE   JCPU   PCPU WHAT
        yanfa    pts/0    10.10.10.102     08:56    0.00s  0.01s  0.00s sshd: yanfa [priv]

    如果 system load averages 超过 CPU 数目，说明 CPU 使用率超过 100%，当然也可能是磁盘 I/O 问题。

* top

        top - 17:03:50 up 22 days,  5:00,  1 user,  load average: 0.00, 0.00, 0.00
        Tasks: 192 total,   1 running, 191 sleeping,   0 stopped,   0 zombie
        Cpu(s):  0.0%us,  0.0%sy,  0.0%ni,100.0%id,  0.0%wa,  0.0%hi,  0.0%si,  0.0%st
        Mem:   7861884k total,  7711996k used,   149888k free,   473780k buffers
        Swap:  9895928k total,      132k used,  9895796k free,  5085192k cached

          PID USER      PR  NI  VIRT  RES  SHR S %CPU %MEM    TIME+  COMMAND                                                                                                                                                                        
        13909 root      15   0 12756 1160  812 R  0.3  0.0   0:00.01 top
            1 root      15   0 10372  696  584 S  0.0  0.0   0:03.90 init
            2 root      RT  -5     0    0    0 S  0.0  0.0   0:00.07 migration/0
            3 root      34  19     0    0    0 S  0.0  0.0   0:02.75 ksoftirqd/0
            4 root      RT  -5     0    0    0 S  0.0  0.0   0:00.00 watchdog/0
            5 root      RT  -5     0    0    0 S  0.0  0.0   0:00.15 migration/1
            6 root      34  19     0    0    0 S  0.0  0.0   0:00.42 ksoftirqd/1
            7 root      RT  -5     0    0    0 S  0.0  0.0   0:00.00 watchdog/1 

* iostat

        yum install sysstat

        [root@localhost /]# iostat
        Linux 2.6.32-358.el6.x86_64 (localhost.localdomain)     12/18/2013      _x86_64_        (8 CPU)

        avg-cpu:  %user   %nice %system %iowait  %steal   %idle
                   0.01    0.00    0.04    0.01    0.00   99.95

        Device:            tps   Blk_read/s   Blk_wrtn/s   Blk_read   Blk_wrtn
        scd0              0.02         1.24         0.00      28844          0
        sda               0.34         6.86        34.47     159920     803836
        dm-0              4.48         6.42        34.47     149738     803784
        dm-1              0.01         0.10         0.00       2376          0
        dm-2              0.01         0.05         0.00       1098         24

* mpstat

        [root@localhost /]# mpstat -P ALL 1
        Linux 2.6.32-358.el6.x86_64 (localhost.localdomain)     12/18/2013      _x86_64_        (8 CPU)

        05:12:27 PM  CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest   %idle
        05:12:28 PM  all    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
        05:12:28 PM    0    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
        05:12:28 PM    1    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
        05:12:28 PM    2    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
        05:12:28 PM    3    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
        05:12:28 PM    4    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
        05:12:28 PM    5    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
        05:12:28 PM    6    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
        05:12:28 PM    7    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00

* vmstat

        [root@localhost /]# vmstat -n 1
        procs -----------memory---------- ---swap-- -----io---- --system-- -----cpu-----
         r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
         1 18   6164 5117004  17796 27089716    0    0    46    43    9    6  5  0 94  0  0
         2 17   6164 5117144  17800 27089724    0    0     0 86916  819  969  0  0 92  8  0
         0 18   6164 5117216  17804 27089732    0    0     0 93308  843  962  0  0 92  8  0
         0 18   6164 5117580  17804 27089732    0    0     0 94208  829 1788  0  0 92  8  0
         0 18   6164 5117704  17808 27089740    0    0     0 90112  836  974  0  0 92  8  0
         1 18   6164 5117704  17816 27089732    0    0     0 98304  887  897  0  0 92  8  0
         0 18   6164 5117852  17820 27089756    0    0     0 102400  931 1788  0  0 88 12  0
         0 18   6164 5118100  17828 27089772    0    0     4 100736  959 1155  0  0 86 14  0
         0 18   6164 5118596  17832 27089780    0    0     0 94208 1239 2782  0  0 89 10  0
         1 18   6164 5118348  17832 27089780    0    0     0 81920 1002 1740  0  0 88 12  0
         0 18   6164 5118480  17836 27089788    0    0     0 86016 1179 1782  0  0 88 12  0
         0 18   6164 5118604  17836 27089788    0    0     0 94464 1318 1775  0  0 88 12  0
         0 18   6164 5118696  17840 27089796    0    0     0 94208 1360 3283  0  0 88 12  0
         1 18   6164 5118572  17844 27089804    0    0     0 92928 1444 1202  0  0 85 14  0
         6 12   6164 4991196  17844 27213580    0    0     0 100208 3525 2151  7  2 79 13  0
         9  9   6164 4077400  17848 28102380    0    0     0 89164 8332 3392 22  6 61 11  0
         0  7   6164 2917900  17860 29230100    0    0  6976 86836 9844 5010 23  7 45 24  0
         0 18   6164 2794768  17864 29349736    0    0  8064 104600 3693 3445  6  2 73 19  0
         3 15   6164 2664816  17864 29476596    0    0  2432 86016 3506 1963  6  1 76 16  0
         3 15   6164 2571088  17876 29567548    0    0  3456 94208 2981 2551  4  1 75 19  0
         2 16   6164 2474584  17896 29661836    0    0  3968 106496 3092 3383  4  1 71 24  0
         4 15   6164 2368192  17896 29766056    0    0  1548 92160 3165 2983  5  1 72 22  0


* free 

        [root@localhost /]# free -m
                     total       used       free     shared    buffers     cached
        Mem:          7865        633       7231          0         15        443
        -/+ buffers/cache:        174       7690
        Swap:         3967          0       3967

* ping

        [root@localhost /]# ping www.baidu.com
        PING www.baidu.com (119.75.217.56) 56(84) bytes of data.
        64 bytes from 119.75.217.56: icmp_seq=1 ttl=54 time=2.35 ms
        64 bytes from 119.75.217.56: icmp_seq=2 ttl=54 time=59.9 ms
        64 bytes from 119.75.217.56: icmp_seq=3 ttl=54 time=2.10 ms
        64 bytes from 119.75.217.56: icmp_seq=4 ttl=54 time=2.40 ms


* dstat

