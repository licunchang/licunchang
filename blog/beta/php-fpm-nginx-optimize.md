**File Name** php-fpm-nginx-optimize.md  

**Description** LNMP 环境单机优化    
**Author** LiCunchang(printf@live.com)   
**Version** 3.0.20130728  

------

## NGINX

* worker_process

设定 worker process 的数量。

这个选项的优化取决于很多因素，包括但不局限于 CPU 的核心数、存储数据的磁盘驱动器的数目、负载模型等。设置为 CPU 的核心数是一个好选择。

    [www@www ~]$ more /proc/cpuinfo | grep "model name" | wc -l
    16
    [www@www ~]$ ps aux | grep nginx | grep "worker process" | wc -l
    16

** how about Intel Hyper-Threading Technology? **

* worker_cpu_affinity

将 worker process 绑定到指定的 CPU 上。

    worker_processes    4;
    worker_cpu_affinity 0001 0010 0100 1000;

如果你有一个 16 核心的服务器，那么……

    worker_processes 16;
    worker_cpu_affinity 0000000000000001 0000000000000010 0000000000000100 0000000000001000 0000000000010000 0000000000100000 0000000001000000 0000000010000000 0000000100000000 0000001000000000 0000010000000000 0000100000000000 0001000000000000 0010000000000000 0100000000000000 1000000000000000;

* worker_connections 

设定一个 worker process 能同时打开的最大并发连接数。

* worker_rlimit_nofile



* server_tokens


* client_max_body_size


* client_body_buffer_size




## PHP

### php-fpm

* pm

* pm.max_children


* pm.start_servers


* pm.min_spare_servers


* pm.max_spare_servers


* emergency_restart_threshold


* emergency_restart_interval


* process_control_timeout

* request_slowlog_timeout = 1s

* slowlog = /usr/local/php/log/php-fpm.log.slow

* request_terminate_timeout = 10s

### php.ini

### PHP-FPM Pools Configuration



## MySQL

### character set & collation


sql_safe_updates


## Linux

### ulimit










http://blog.csdn.net/wangbin579/article/details/6327651
