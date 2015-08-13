**File Name** mysql-query-cache.md  

**Description**  MySQL 查询缓存简介  
**Author** licunchang  
**Version** 1.0.20130815  

------

    mysql> SHOW VARIABLES LIKE 'have_query_cache';
    +------------------+-------+
    | Variable_name    | Value |
    +------------------+-------+
    | have_query_cache | YES   |
    +------------------+-------+
    1 row in set (0.00 sec)

在 MySQL 的发行版中，这个值(一般都是 `YES` )只是标识当前系统是否支持 query cache，与 query cache 是否启用没有关系。

你可以使用下面的命令，查看 query cache 相应的系统变量

    mysql> SHOW GLOBAL VARIABLES LIKE 'query_cache_%';
    +------------------------------+---------+
    | Variable_name                | Value   |
    +------------------------------+---------+
    | query_cache_limit            | 1048576 |
    | query_cache_min_res_unit     | 4096    |
    | query_cache_size             | 0       |
    | query_cache_type             | OFF     |
    | query_cache_wlock_invalidate | OFF     |
    +------------------------------+---------+
    5 rows in set (0.00 sec)

query cache 的系统变量总是以 `query_cache` 开头的。


分区表不支持 query cache。


SHOW GLOBAL STATUS LIKE 'Qcache_free_memory';
SHOW GLOBAL VARIABLES LIKE 'query_cache_size';


SHOW GLOBAL STATUS LIKE 'Qcache_total_blocks';
SHOW GLOBAL STATUS LIKE 'Qcache_free_blocks';
SHOW GLOBAL STATUS LIKE 'Qcache_queries_in_cache';


    SHOW GLOBAL STATUS LIKE 'Qcache_lowmem_prunes';

The number of queries that were deleted from the query cache because of low memory.

vi /etc/mysql/my.cnf

    query_cache_size=0
    query_cache_type=0


Qcache_hits

如果一个查询是从 query cache 中取得的结果，那么就在 Qcache_hits 上加 1 ，而不是 Com_select 








































http://dev.mysql.com/doc/refman/5.6/en/server-system-variables.html#sysvar_query_cache_type
http://dev.mysql.com/doc/refman/5.5/en/server-system-variables.html#sysvar_query_cache_type
http://dev.mysql.com/doc/refman/5.5/en/query-cache-configuration.html
http://dev.mysql.com/doc/refman/5.6/en/query-cache.html
http://dev.mysql.com/doc/refman/5.5/en/query-cache.html