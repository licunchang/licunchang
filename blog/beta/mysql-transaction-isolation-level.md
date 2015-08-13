**File Name** mysql-transaction-isolation-level.md    

**Description** MySQL 事务隔离级别  
**Author** LiCunchang(printf@live.com)  
**Version** 1.0.20130429  

------

## 1 事务

数据库的事务是数据库并发控制的基本单位，一组操作的集合、序列。要么都执行，要么都不执行，是一个不可分割的整体。比如银行的转账，钱从一个账户转移到另一个账户，账户A扣钱账户B加钱，要么都执行，要么都不执行。不可能A扣了钱B没有加钱，也不可能A没扣钱B却加了钱。







## 2 隔离级别

标准 SQL 中定义了四个隔离级别，每一种级别都规定了一个事务中所做的修改，哪些是在事务内和事务间是可见的，哪些是不可见的。较低级别的隔离通常可以执行更高的并发， 系统的开销也更低。

1. READ UNCOMMITTED
2. READ COMMITTED
3. REPEATABLE READ
4. SERIALIZABLE

### 1.1 READ UNCOMMITTED



### 1.2 READ COMMITTED



### 1.3 REPEATABLE READ

这是 InnoDB 的默认隔离级别


### 1.4 SERIALIZABLE



## References

1. 关于数据库事务、隔离级别、锁的理解与整理, [http://www.e800.com.cn/articles/2011/0803/492650.shtml](http://www.e800.com.cn/articles/2011/0803/492650.shtml "关于数据库事务、隔离级别、锁的理解与整理")
1. MySQL 5.5 Manual, [http://dev.mysql.com/doc/refman/5.5/en/set-transaction.html](http://dev.mysql.com/doc/refman/5.5/en/set-transaction.html "MySQL 5.5 Manual")
