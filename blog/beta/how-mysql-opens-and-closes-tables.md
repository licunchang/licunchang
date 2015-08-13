**File Name** how-mysql-opens-and-closes-tables.md

**Description** MySQL 怎样打开关闭表  
**Author** LiCunchang(printf@live.com)  
**Version** 1.0.20130327  

------

使用 `mysqladmin status -u{user} -p{password}` 命令查看 MySQL 状态，得到结果如下：

    Uptime: 1310183  Threads: 1  Questions: 2155090  Slow queries: 852  Opens: 262  Flush tables: 1  Open tables: 249  Queries per second avg: 1.644

其中 `Open tables` 有 249 个，但是数据库中的表数目远远小于这个数字。

MySQL 是多线程的工作模式，所以同一时刻可能有许多客户端对同一个表发起查询操作，为了减少多客户端会话在同一个表上的所产生的影响，系统为每一个会话单独打开一张表。这样的方式增加了内存使用但是提升了性能。MyISAM 引擎下，每次为一个会话打开一张表就需要额外的一个文件描述符（索引文件则是对所有会话共享的）。

`table_open_cache` 和 `max_connections` 这两个系统变量影响 MySQL 能打开文件的最大值。如果你增加其中一个或者两个变量的值，就可能使得单进程打开文件的最大数达到系统预设的最大值，这时候你就必须考虑增加系统的这个限制。`table_open_cache` 和 `max_connections` 是有一定关系的，比如，对200个正在运行的连接，table_open_cache 的大小最少需要 200 * N ，这个 N 就是你执行的表连接操作中涉及的表数目的最大值，除此之外，你还需要为临时文件和临时表开销额外的文件描述符。

如果 `table_open_cache` 设置的太大，MySQL就会耗光文件描述符然后拒绝连接，系统就无法正常提供服务，你还必须考虑到 MyISAM 引擎在每个不同的打开的表消费两个文件描述符。你可以使用 `open_files_limit` 来增加 MySQL 能使用的文件描述符。`table_open_cache` 的默认值是400，但是 MySQL 可能偶尔会打开更多的表来执行查询。

MySQL 关闭一个无用的表并且把它从cache里面移除的规则如下：

* 当 cache 已满，并且一个线程试图打开一个不在cache里面的表时    
* 当 cache 包含了多于 table_open_cahe 定义的表，并且这个表不再被任何线程使用时    
* 当一个表执行 flush 操作时，`mysqladmin flush-tables`  `mysqladmin refresh` 命令或 `FLUSH TABLES` 语句都能引发这样的操作    

当表缓存被填满的时候，服务器使用下面的规则定位一个表来使用：

* 当前不被使用的表释放    
* 如果缓存已经满了并且没有表可以释放，但是需要打开一张新表，则临时扩充缓存，当表使用完毕之后，则立即从缓存中释放    

MyISAM 表需要为每一次请求打开一次，这就意味着如果有两个线程请求或者一个线程中相同的查询中两次使用同一张表，这张表就必须打开两次，第一次打开任意的 MyISAM表都需要两个文件描述符：一个打开数据，另一个打开索引。每一个额外的请求只需要一个文件描述符打开数据文件，而索引文件则共享文件描述符。























