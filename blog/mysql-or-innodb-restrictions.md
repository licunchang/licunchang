**File Name** mysql-or-innodb-restrictions.md  

**Description**  MySQL 或 InnoDB 中的约束限制  
**Author** licunchang  
**Version** 1.0.20130908  

------

> 不要将 MySQL 系统中 mysql 数据库中的系统表从 myisam 引擎 升级到 InnoDB

> 在 NFS 设备上不推荐使用 InnoDB 引擎来存储数据或者日志文件

## 最大值 & 最小值

* MySQL 对数据库数量没有限制，不过，操作系统的文件系统可能对文件夹的数目有限制
* MySQL 对数据库表的数量也没有限制，同样的，操作系统的文件系统可能对文件的数据有限制，而 InnoDB 引擎最多限制 40 亿表
* InnoDB 引擎单表最多能有 1000 个字段，而 MySQL 对单表字段数的最大硬限制是 4096 个，具体的最大值依赖很多其他因素
* InnoDB 引擎单表最多能有 64 个二级索引
* 默认情况下，InnoDB 引擎单一字段索引的长度最大为 767 字节(TODO:为什么是767？)，同样的，前缀索引也有同样的限制。当使用 UTF-8 字符集，每一个字符使用 3 字节来存储，在 TEXT 或者 VARCHAR 类型的字段上建立一个超过 255 字符数的前缀索引时就会遇到问题。你可以启用服务器选项 `innodb_large_prefix` 使得这个限制增加到 3072 字节(TODO:为什么是3072？)，而且表的 row_format 需要使用 compressed 或者 dynamic
* InnoDB 引擎内部索引最大的长度为 3500 字节，但是 MySQL 将其限制到了 3072 字节。由多个字段组成的联合主键适用这个限制
* InnoDB 中，不考虑变长类型(VARBINARY, VARCHAR, BLOB, TEXT)InnoDB 引擎单行最大长度略小于数据页的一半，也就是 8000 字节，LONGBLOB 和 LONGTEXT 类型字段必须小于 4GB ，并且，算上 BLOB 和 TEXT 类型的字段，单行的长度必须小于 4GB 。如果一行数据大小远小于页的一半，那么行内的所有数据都存储在页中，如果超过了页的一半，变长字段则将前面768字节放在行内，剩余的放在其他页，同时存储一个20字节的长度用来记录真实的长度和剩余部分的指针
* 尽管 InnoDB 内部行的最大长度可以超过 65535 字节，但是 MySQL 将这个限制降到了 65535 字节
* InnoDB 日志文件大小加起来不应该超过 4GB
* InnoDB 表空间最小默认10MB，最大是数据页大小的40亿倍，也就是 64TB 这也是单表最大值。
* InnoDB 中默认的数据库页大小是 16KB 。不建议更改数据库页的大小

to be continued.

## References

1. Limits on Table Column Count and Row Size, [http://dev.mysql.com/doc/refman/5.5/en/column-count-limit.html](http://dev.mysql.com/doc/refman/5.5/en/column-count-limit.html "Limits on Table Column Count and Row Size")
2. Limits on InnoDB Tables, [http://dev.mysql.com/doc/refman/5.5/en/innodb-restrictions.html](http://dev.mysql.com/doc/refman/5.5/en/innodb-restrictions.html)  