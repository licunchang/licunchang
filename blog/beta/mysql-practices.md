**File Name** mysql-practices.md  
**Description**  MySQL 性能优化实践  
**Author** LiCunchang (printf@live.com)  
**Version** 1.0.20140321  

------

## 1 操作系统层面

### 1.1 优化 IO 调度算法

    [root@localhost ~]# cat /sys/block/sda/queue/scheduler
    noop anticipatory deadline [cfq]
    [root@localhost ~]# echo deadline >/sys/block/sda/queue/scheduler
    [root@localhost ~]# cat /sys/block/sda/queue/scheduler
    noop anticipatory [deadline] cfq
    [root@localhost ~]#



SELECT 
  CONCAT(`table_schema`, '.', `table_name`) AS `Table Name`,
  CONCAT(
    ROUND(`data_length` / (1024 * 1024), 2),
    'M'
  ) AS `Data Length`,
  CONCAT(
    ROUND(`index_length` / (1024 * 1024), 2),
    'M'
  ) AS `Index Length`,
  CONCAT(
    ROUND(
      ROUND(`data_length` + `index_length`) / (1024 * 1024),
      2
    ),
    'M'
  ) AS `Total Size` 
FROM
  `information_schema`.`TABLES` 
ORDER BY `data_length` DESC ;











SELECT @@profiling;

SHOW PROFILES

SHOW PROFILE FOR QUERY 19;

SHOW PROFILE ALL FOR QUERY 19;


















