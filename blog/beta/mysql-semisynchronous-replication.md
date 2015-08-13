**File Name** mysql-semisynchronous-replication.md  

**Description** MySQL 半同步复制    
**Author** LiCunchang(printf@live.com)   
**Version** 3.0.20131211  

------

MySQL 的 `replication` 默认是异步的。主库将事件写入到 binlog 之后，不知道从库是否接收并处理了这些事件日志，在这种情况下，如果主库 crash 掉，而从库的延迟又很大，则已经提交的事务可能没有传送给任何一台备库，因此，如果使用备库来替代主库，可能无法保持数据一致性。

Semisynchronous replication 可以提供 asynchronous replication 之外的一种选择，基于半同步复制，有以下优点：







