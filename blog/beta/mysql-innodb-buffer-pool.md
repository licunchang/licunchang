**File Name** mysql-innodb-buffer-pool.md  

**Description** MySQL 的 Buffer Pool 简介   
**Author** LiCunchang(printf@live.com)  
**Version** 2.0.20130819  

------

## 1 概述

InnoDB 在内存中维护一个 buffer pool 用来缓存数据和索引，这是 InnoDB 非常重要的一个功能。划分给 buffer pool 的内存越大，InnoDB 的表现就越像是一个内存服务器，只要第一次将数据从磁盘中加载到内存中，后面的数据读取操作都可以在内存中进行了，buffer pool 甚至还可以缓存由 insert 和 update 引起的数据变更，这使得磁盘的写操作可以合并，从而使得数据库表现出更好的性能。

InnoDB 把 buffer pool 当作一个 block 列表来管理，使用 LRU(Least Recently Used) 算法来置换 block。当需要添加一个新的 block 到 buffer pool 的时候，InnoDB 将最近最少使用的 block 踢出，然后将这个新的 block 添加到列表的中间，这种中间插入的策略相当于把这个列表划分成了两个子列表：

* 在头部，是最近刚刚访问过的 new blocks 组成的 new sublist
* 在尾部，是最近很少访问过的 old blocks 组成的 old sublist

这个算法使得访问最频繁的 block 保持在 new sublist 中，同时 old sublist 中包含了很少访问的 block。

LRU 算法默认的按照下面的执行

* 3/8 的 buffer pool 分配给了 old sublist
* 中间点是 new sublist 的尾部和 old sublist 的头部的分界线
* 当用户查询到一个新的 block，或者 InnoDB 预读到了一个新的 block 时，这个 block 被读入到 buffer pool 中，并插入到列表的中间(old sublist 的头部)
* 当访问到 old sublist 中的一个 block 时，将其移动到 buffer pool list 的头部(也就是 new sublist 的头部)
* 

默认的，查询过程中读到的 block 会立刻移动到 new sublist ，这意味着这些 blocks 可能将在 buffer pool 中呆上足够长的时间才可能被踢出。同样的，被后台现成预读到的 block 不会










InnoDB在内存中维护一个缓存池用于缓存数据和索引。缓存池管理一个数据块列表，该列表又分为2个字列表，一个子列表存放new blocks，另一个子列表存放old blocks。old blocks默认占整个列表大小的3/8（可通过innodb_old_blocks_pct改变默认值，该值范围在5-95之间，这是一个百分比），其余大小为new blocks占用。
 
当有新数据添加到缓存池中时，如果缓存池的空间不足，则根据LRU算法清除数据。
 
新插入缓存池的数据插入到存放old blocks的子列表的头部，如果数据被用户访问，则将这个数据移至new blocks的头部。如果设置了innodb_old_blocks_time大于0，比如innodb_old_blocks_time=1000，当新数据插入缓存池后过1s之后被访问，才会把数据移至new blocks的头部，在刚插入的一秒之内被访问改数据不会被移动，仍然在old blocks的头部。
 
当访问old blocks中的数据时，该数据会被移至new blocks的头部，但是当访问new blocks中的数据时，只有在该数据离new blocks的头部有一定距离时才移动。
为了更好的并发性能，通过指定innodb_buffer_pool_instances（该值取值范围为1-64）创建多个缓存池，每个缓存池的大小为
innodb_buffer_pool_size/innodb_buffer_pool_instances，通常需要保持当个缓存池的大小大于1GB。




## 2 Configuration Options

* innodb\_buffer\_pool\_size

指定 buffer pool 的总大小

* innodb\_buffer\_pool\_instances

将 buffer pool 划分成用户指定数目的独立的区域，每一个区块都有自己的 LRU 算法

* innodb\_old\_blocks\_pct

设置 buffer pool 中 old sublist 占的比例，取值范围从 5 到 95 ，默认值是37(也就是 3/8)

* innodb\_old\_blocks\_time

设置 插入到 old sublist 中的 block 在多长时间(单位ms)之后才能移动到 new sublist
innodb_old_blocks_time 可以在运行时进行设置，所以你可以在 table scan 或者 table dump 时暂时修改。

## 3 Monitoring the Buffer Pool


Old database pages






## 4 SHOW ENGINE INNODB STATUS and the InnoDB Monitors



CREATE TABLE innodb_monitor (a INT) ENGINE=INNODB;
CREATE TABLE innodb_lock_monitor (a INT) ENGINE=INNODB;
CREATE TABLE innodb_table_monitor (a INT) ENGINE=INNODB;
CREATE TABLE innodb_tablespace_monitor (a INT) ENGINE=INNODB;




