**File Name** mysql-server-options-optimization.md  

**Description** MySQL 5.5 配置项优化    
**Author** LiCunchang(printf@live.com)  
**Version** 2.0.20130419  

------

## max\_connections

允许的最大并行客户端连接数目。默认值为 151 ，增大该值则增加 mysqld 需要的文件描述符的数量。

如果系统经常出现 **Too many connections** 的错误，意味着所有可用的连接都正在被使用，那么就应该尝试增大该值。

mysqld 实际上允许 max_connections + 1 个客户端连接，额外的那一个连接被超级管理员用户使用。

在Linux下一般来说支持 500 - 1000 个连接，如果有更大的内存，而且每个连接的负载都不大，查询很简单的话，最大 10000 也不是问题。增大该值一般要同时增加 `open-files-limit` 的数值。

## open\_files\_limit

max\_connections*5或max\_connections + table\_cache*2(取较大者)个文件

操作系统允许 mysqld 能够打开的文件的数量。系统真正允许的数值可能和参数给定的数值有所不同，选项值传递给 ulimit -n。请注意你需要用root启动mysqld_safe来保证正确工作！

如果系统经常出现 **Too many open files** 的错误，可以尝试增大该值。

On Unix, the value cannot be set less than ulimit -n.

open_files_limit = 65535
tmp_table_size                 = 32M
max_heap_table_size            = 32M
query_cache_type               = 0
query_cache_size               = 32M
max_connections                = 500
thread_cache_size              = 50
open_files_limit               = 65535
table_definition_cache         = 4096
table_open_cache               = 4096

## table_open_cache












