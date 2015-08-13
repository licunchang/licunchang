## Redis configuration

redis.conf

配置文件中使用key-value的格式，value中如果有空格，使用双引号：

    requirepass "hello world"

不停机的情况下可以使用`CONFIG SET`、`CONFIG GET`来设置或者得到当前设置，并不是所有的配置项都能够通过这种方式来修改配置，可以使用`CONFIG REWRITE`来将当前服务器配置写入到redis.conf文件中。

可以把redis当作单纯的缓存服务器，这种情况下需要设置

    maxmemory 2mb
    maxmemory-policy allkeys-lru

这样就不需要为每一个key指定一个`EXPIRE`过期时间了，当缓存的数据超过maxmemory限制的时候redis会使用LRU算法来淘汰过期数据，这时候redis的表现更像是mememcached服务器。

## Replication

1. redis使用异步复制
2. 一个主服务器能有多个从服务器
3. 从服务器能从多个从服务器
4. redis的复制在主服务器上是非阻塞式的，这意味着从服务器在执行同步操作的时候，主服务器依然能够处理查询
5. 在从服务器一侧，复制也是非阻塞式的，

主服务器关掉持久化的时候怎样保证安全

如果主服务器的持久化被关闭，则实例一定要避免程序自动重启
