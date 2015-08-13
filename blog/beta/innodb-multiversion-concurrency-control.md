**File Name** innodb-multiversion-concurrency-control.md  

**Description**  InnoDB MVCC 实现原理概述  
**Author** licunchang  
**Version** 1.0.20121221  

------

InnoDB 多版本并发控制

先说几个概念

* 事务 id(transaction identifier)    
    在 MySQL 中，每开始一个事务，系统中有一个变量自动递增加 1 ，然后将事务开始时刻的这个变量值作为整个事务的 id。

InnoDB 是多版本存储的引擎，为了支持事务的特性，比如：并发和回滚，它将被更新的行原有旧版本的信息存储在表空间中一段叫做回滚段的空间中。利用回滚段中存储的信息，InnoDB 能在事务操作中提供回滚操作，同时也可以为事务未提交前其他同一时间的读操作提供旧有版本的数据。

在内部，InnoDB 在数据库中的每一行都添加了三个字段(《高性能MySQL》第三版 p13 写的是两个字段，此处为官方文档说明)：

* DB_TRX_ID 
    6 byte 长度，保存了最近一次执行插入或者更新操作事务的事务 id，删除操作在内部被理解成更新操作，因为 InnoDB 每一行都有 1bit 的标识位来标识当前行是否被删除。

* DB_ROLL_PTR 
    7 byte 长度，保存了当前行在回滚段中的 undo log 的指针，可以叫它“回滚指针”。如果行被更新，回滚段中的 undo log 就存储了还原当前记录行至旧版本所需要的全部信息。

* DB_ROW_ID 
    6 byte 长度，保存了当前行的 ROW_ID，因为
    
















http://blog.csdn.net/chen77716/article/details/6742128
http://hedengcheng.com/?p=148
