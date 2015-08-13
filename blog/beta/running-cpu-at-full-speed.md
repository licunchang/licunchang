**File Name** running-cpu-at-full-speed.md  

**Description** 让服务器的 CPU 跑在高性能模式    
**Author** LiCunchang(printf@live.com)   
**Version** 3.0.20130728  

------

	processor       : 7
	vendor_id       : GenuineIntel
	cpu family      : 6
	model           : 58
	model name      :         Intel(R) Core(TM) i7-3770 CPU @ 3.40GHz
	stepping        : 9
	cpu MHz         : 1600.000

	processor       : 7
	vendor_id       : GenuineIntel
	cpu family      : 6
	model           : 58
	model name      :         Intel(R) Core(TM) i7-3770 CPU @ 3.40GHz
	stepping        : 9
	cpu MHz         : 3401.000

	----------------------------------------------------------------------------

	processor       : 3
	vendor_id       : AuthenticAMD
	cpu family      : 18
	model           : 1
	model name      : AMD Athlon(tm) II X4 641 Quad-Core Processor
	stepping        : 0
	cpu MHz         : 800.000

	processor       : 3
	vendor_id       : AuthenticAMD
	cpu family      : 18
	model           : 1
	model name      : AMD Athlon(tm) II X4 641 Quad-Core Processor
	stepping        : 0
	cpu MHz         : 2800.000

How to disable on-demand cpu scaling on Linux
	
	/sbin/service cpuspeed stop

How to (re) enable on-demand cpu scaling on Linux

	/sbin/service cpuspeed start

http://www.mysqlperformanceblog.com/2013/12/07/linux-performance-tuning-tips-mysql/    
https://www.centos.org/forums/viewtopic.php?t=11818    
http://tech.gaeatimes.com/index.php/archive/how-to-disable-on-demand-cpu-scaling-on-linux/    
http://www.servernoobs.com/avoiding-cpu-speed-scaling-in-modern-linux-distributions-running-cpu-at-full-speed-tips/    