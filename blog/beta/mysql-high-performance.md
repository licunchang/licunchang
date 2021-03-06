**File Name** mysql-high-performance.md    

**Description** 高性能 MySQL 读书笔记  
**Author** LiCunchang(printf@live.com)  
**Version** 1.0.20130429  

------

## 1 MySQL 架构和历史

MySQL 最与众不同的特性是它的存储引擎架构，这种架构的设计将查询处理（Query Processing）及其他系统任务（Server Task）和数据的存储/提取相分离。

服务器通过API与存储引擎进行通信，这些接口屏蔽了不同存储引擎之间的差异，使得这些差异对上层的查询过程透明，存储引擎API包含了几十个底层函数，但是存储引擎不会去解析SQL（InnoDB是一个例外，它会解析外键定义，因为MySQL服务器本身没有实现该功能），不同的存储引擎之间也不会相互通信。

MYSQL 5.5 企业版提供了一个API支持线程池（thread-polling）插件，可以使用池中少量的线程来服务大量的连接。

优化器并不关系表使用的是什么存储引擎，但是存储引擎对于优化查询是有影响的。

对于SELECT语句，在解析之前，服务器先检查查询缓存。

在处理并发读或者写时，可以通过实现一个由两种类型的锁组成的锁系统来解决问题，这两种类型的锁通常被称为共享锁（shared lock）和排它锁（exclusive lock），也叫做读锁（read lock）或者写锁（write lock）。

表锁（table lock）是最基本的所策略，并且是开销最小的策略。尽管存储引擎可以管理自己的锁，MySQL本身还是会使用各种有效的表锁来实现不同的目的。例如，服务器会为诸如later table之类的语句使用表锁，而忽略存储引擎的锁机制。

行级锁可以最大程度的并发处理（同时也带来了最大的所开销），行级锁只在存储引擎层实现，而MySQL服务器层没有实现。

SQL标准中定义了四种隔离级别，较低级别的隔离通常可以执行更高的并发，系统的开销也更低。

READ UNCOMMITTED（未提交读） 出现脏读现象，性能不会比其他级别好太多，实际应用中一般很少使用。

READ COMMITED（提交读）大多数数据库系统的默认隔离级别。

REPEATABLE READ（可重复读）MySQL默认事务隔离级别。

SERIALIZABLE（可串行化）可能会导致大量的超时和锁争用的问题，实际应用中也很少用到这个隔离级别。


1.更新丢失（Lost update）：两个事务同时更新，但是第二个事务却中途失败退出，导致对数据的两个修改都失效了。

2.脏读（Dirty Reads）：一个事务开始读取了某行数据，但是另外一个事务已经更新了此数据但没有能够及时提交。这是相当危险的，因为很可能所有的操作都被回滚。

3.不可重复读取（Non-repeatable Reads）：一个事务两次读取，但在第二次读取前另一事务已经更新了。

4.虚读（Phantom Reads）：一个事务两次读取，第二次读取到了另一事务插入的数据。

5.两次更新问题（Second lost updates problem）：两个事务都读取了数据，并同时更新，第一个事务更新失败。





InnoDB 目前处理死锁的方式是，将持有最少行级排它锁的事务进行回滚（这是相对比较简单的死锁回滚算法）。

锁的行为和顺序是和存储引擎相关的，死锁的产生有双重原因：有些是因为真正的数据冲突，这种情况通常很难避免，但有些则完全是由于存储引擎的实现方式导致的。

事务日志，顺序IO，修改数据需要写两次磁盘？

MySQL中默认采用自动提交模式（AUTOCOMMIT），同时有一些命令在执行之前会强制COMMIT提交当前的活动事务。

MySQL中服务器层不管理事务，事务是由下层的存储引擎实现的，所以在同一个事务中，使用多种存储引擎是不可靠的。

MVCC的实现是通过保存数据在某个时间点的快照来实现的。

不同的存储引擎的MVCC实现是不同的，典型的有乐观并发控制和悲观并发控制。

InnoDB的MVCC，是通过在每行记录后面保存两个隐藏的列来实现的。这两个列，一个保存了行的创建时间，一个保存了行的过期时间（或删除时间）。当然，这两个字段存储的并不是实际的时间值，而是系统版本号。

MVCC只能在REPETABLE READ 和 READ COMMITED 两个隔离级别下工作，其他两个隔离级别都和MVCC不兼容。

不同的存储引擎保存数和索引的方式是不同的，但表的定义则是在MySQL服务层统一处理的。

InnoDB表是基于聚簇索引建立的，聚簇索引对逐渐查询有很高的性能，不过他的二级索引中必须包含主键列，所以如果主键列很大的话，其他的所有索引都会很大，因此，若表上的索引较多的话，主键应当尽可能的小。InnoDB的存储格式是平台独立的。

## 2 MySQL 基准测试

TPC-C

测试何种指标

* 吞吐量：单位时间内的事务处理数
* 响应时间或者延迟：用户测试任务所需的整体时间
* 并发性：在任意时间有多少同时发生的并发请求
* 可扩展性

基准测试工具

集成式测试工具

* ab
* http_load
* JMeter

单组件式测试工具

* mysqlslap
* MySQL Benchmark Suite(sql-bench)
* Super Smack
* Database Test Suite
* Percona's TPCC-MySQL Tool
* sysbench


## 3 服务器性能剖析


## 4 Schema与数据类型优化

* 更小的通常更好
* 简单就好
* 尽量避免 NULL

### 4.1 整数类型

TINYINT SMALLINT MEDIUMINT INT BIGINT
分别使用 8 16 24 32 64 

整数类型有可选的 UNSIGNED 属性，表示不允许负值，有符号和无符号类型使用相同的存储空间，并具有相同的性能。

### 4.2 实数类型

不止是为了存储小数部分，也可以使用DECIMAL存储比BIGINT还大的整数。



### 4.3 字符串类型











































