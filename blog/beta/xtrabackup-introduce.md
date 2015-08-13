**File Name** xtrabackup-introduce.md

**Description** Xtrabackup for MySQL InnoDB 简介  
**Author** LiCunchang(printf@live.com)  
**Version** 2.0.20131128  

------

## 1 下载 & 安装

CentOS 下安装依赖

    yum -y install cmake gcc gcc-c++ patch libaio libaio-devel automake autoconf bzr bison libtool ncurses-devel zlib-devel perl-Time-HiRes perl-DBD-MySQL

Debian 下安装依赖

    apt-get install debhelper autotools-dev libaio-dev wget automake libtool bison libncurses-dev libz-dev cmake bzr libgcrypt11-dev perl perl-module

官方网站 ([http://www.percona.com/software/percona-xtrabackup](http://www.percona.com/software/percona-xtrabackup)) 有针对各大发行版的二进制安装文件，不建议编译安装，这玩意编译安装坑爹的一货。

## 2 概述

XtraBackup 是一套四个命令的工具集

* innobackupex 一个封装了的脚本，提供了对 MyISAM、InnoDB 的备份功能
* xtrabackup 一个 C 编译的二进制文件，只对 InnoDB 的数据进行备份
* xbcrypt 加密、解密备份文件
* xbstream 以流的格式来备份、还原数据

你可以单独使用 `xtrabackup` 命令，不过由于这个命令不对数据库的结构进行备份等原因，一般来使用 `innobackupex` 来备份。

## 3 innobackupex

`innobackupex` 是一个 Perl 脚本，封装了 `xtrabackup` 命令。这是对 Oracle 分发的 InnoDB 热备工具 `innobackup` 的一个 patch，提供了很多的功能，能够对 InnoDB 引擎执行基于时间点的备份。

XtraBackup 必须能够连接到数据库服务器上并执行操作，同时在备份和重建数据时还必须对 **datadir** 目录有管理权限，这些都是必须满足的条件。所以执行 xtrabackup 或者 innobackupex 需要两个用户角色：一个是系统用户，一个是数据库用户。

连接到数据库需要提供用户名(--user)和密码(--password)，下面是一个执行全部备份任务所需的数据库用户最小权限的示例：

    mysql> GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'xtrabackup'@'localhost' IDENTIFIED BY 'xtrabackup';
    mysql> FLUSH PRIVILEGES;

同时，执行 `innobackupex` 命令的系统用户必须对 MySQL 的 **datadir** 有 READ, WRITE, EXECUTE 权限。下面是一个典型的全备份的样例：

    innobackupex --defaults-file=/etc/mysql/my.cnf --user=xtrabackup --password=xtrabackup --port=3306 --host=localhost --socket=/tmp/mysql.sock --databases=utrans --defaults-group=mysql --no-timestamp /data/backup/mysql/$(date +'%Y-%m-%d')/

上面的命令就在 `/data/backup/mysql/$(date +'%Y-%m-%d')/` 目录下创建了一份全备份，因为可能有未提交的事务和有些事务没有重做，所以在还原到这次全备份之前需要将数据预处理一下，使用额外的操作使数据保持一致：

    innobackupex --apply-log --use-memory=4G --ibbackup=xtrabackup_56 /data/backup/mysql/$(date +'%Y-%m-%d')/

完事之后，就可以将数据还原到此时间点了，在还原之前需要将 MySQL 停机，并且将 datadir 目录下相应的数据库的目录及其目录下文件删除，因为还原过程不能覆盖存在的文件，

    /data/init.d/mysql stop

清空目录，即使只备份一个数据库，也需要把 datadir 下面的其他文件和文件夹清空：

    mkdir -p /data/backup/mysql/$(date +'%Y-%m-%d')-data/
    mv /data/mysql/* /data/backup/mysql/$(date +'%Y-%m-%d')-data/
    innobackupex --copy-back /data/backup/mysql/$(date +'%Y-%m-%d')/

将系统数据库拷贝回来(中间有部分数据提示要不要覆盖，不要。)

    cp -r /data/backup/mysql/$(date +'%Y-%m-%d')-data/mysql /data/mysql/
    cp -r /data/backup/mysql/$(date +'%Y-%m-%d')-data/performance_schema /data/mysql/

千万注意修改文件的权限

    chown mysql:mysql /data/mysql -R

    /data/init.d/mysql start

上面的是完全备份，下面介绍增量备份。

增量备份首先必须创建一个完全备份，前面有述，不表。

    innobackupex --incremental --user=xtrabackup --password=xtrabackup --port=3306 --host=localhost --socket=/tmp/mysql.sock --incremental-basedir=/data/backup/mysql/$(date +'%Y-%m-%d')/ --no-timestamp /data/backup/mysql/$(date +'%Y-%m-%d_%H')/


    innobackupex --incremental /data/backups --incremental-lsn=1358967

    innobackupex --apply-log --redo-only --use-memory=4G --ibbackup=xtrabackup_56 /data/backup/mysql/$(date +'%Y-%m-%d')/
    innobackupex --apply-log --redo-only --use-memory=4G --ibbackup=xtrabackup_56 /data/backup/mysql/$(date +'%Y-%m-%d')/ --incremental-basedir=/data/backup/mysql/$(date +'%Y-%m-%d_%H')/ 
    innobackupex --apply-log --use-memory=4G --ibbackup=xtrabackup_56 /data/backup/mysql/$(date +'%Y-%m-%d')/ --incremental-basedir=/data/backup/mysql/$(date +'%Y-%m-%d_%H')/ 










    /usr/local/mysql/bin/mysql -uroot -p -e "DROP DATABASE utrans;"
    /usr/local/mysql/bin/mysql -uroot -p -e "SOURCE /data/web/www.utrans.com/application/utrans.sql;"
    /usr/local/mysql/bin/mysql -uroot -p -e "GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'xtrabackup'@'localhost' IDENTIFIED BY 'xtrabackup';"
    /usr/local/mysql/bin/mysql -uroot -p -e "GRANT INSERT, DELETE, UPDATE, SELECT ON utrans.* TO 'utrans'@'%' IDENTIFIED BY '**HaiShiNaGe**';"
    /usr/local/mysql/bin/mysql -uroot -p -e "FLUSH PRIVILEGES"