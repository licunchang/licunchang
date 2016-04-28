**File Name** configure-new-lnmp-server.md  
**Description**  DELL R720 Web 配置  
**Author** LiCunchang (printf@live.com)  
**Version** 1.0.20140821  

------

公司新上一台服务器，具体配置如下：

> DELL PowerEdge R720 2U Rack Server  
> Intel(R) Xeon(R) CPU E5-2630 v2 @ 2.60GHz x 2  
> Seagate 3TB 3.5" SATA Hard Drive(ST3000NM0033) x 3  
> 32GB(16GB x 2) LRDIMM Memory  
> DELL PERC H310 Mini RAID Controller  

## CentOS Installation

CentOS 6.5 安装，语言相关都设置 English，时区设置 **Asia/Shanghai**，`system clock uses UTC` 选项要勾选，最小化安装完毕后设置时间：

    [root@localhost ~]# vi /etc/sysconfig/clock
    ZONE="Asia/Shanghai"
    UTC="true"
    [root@localhost ~]# date --set "07/25/2014 18:10:00"
    Fri Jul 25 18:10:00 CST 2014
    [root@localhost ~]# hwclock --systohc
    [root@localhost ~]# hwclock --show
    Fri 25 Jul 2014 06:11:04 PM CST  -0.392072 seconds
    [root@localhost ~]# hwclock --debug
    hwclock from util-linux-ng 2.17.2
    Using /dev interface to clock.
    Last drift adjustment done at 1406283045 seconds after 1969
    Last calibration done at 1406283045 seconds after 1969
    Hardware clock is on local time
    Assuming hardware clock is kept in local time.
    Waiting for clock tick...
    ...got clock tick
    Time read from Hardware Clock: 2014/07/25 18:11:21
    Hw clock time : 2014/07/25 18:11:21 = 1406283081 seconds since 1969
    Fri 25 Jul 2014 06:11:21 PM CST  -0.438558 seconds

## Storage Settings

3TB 的磁盘分区表需要使用 **GPT (GUID Partition Table)**，对新硬盘的分区使用 `parted` 工具：

    [root@localhost dev]# parted -a optimal /dev/sdb
    GNU Parted 2.1
    Using /dev/sdb
    Welcome to GNU Parted! Type 'help' to view a list of commands.
    (parted) mklabel gpt
    (parted) mkpart primary 0% 100%
    (parted) quit
    Information: You may need to update /etc/fstab.

    [root@localhost dev]#

`mkfs.ext4 /dev/sdb1` 格式化，查看磁盘UUID：

    [root@localhost ~]# blkid -s UUID
    /dev/sda1: UUID="af436579-f911-4e49-971f-a4e01044ad3f" TYPE="ext4"
    /dev/sda2: UUID="0d2f035b-d6e4-4975-9ada-47716f77fbd4" TYPE="swap"
    /dev/sda3: UUID="28a44218-f8f6-487b-955e-db890d8806d5" TYPE="ext4"
    /dev/sdb1: UUID="39ba4f2c-1495-483b-943c-ed1b0fd4fef5" TYPE="ext4"
    /dev/sdc1: UUID="e333f07c-22ca-4848-b1b1-9c908f5d1d43" TYPE="ext4"

`mkdir /disk1` 创建挂载点，`vi /etc/fstab` 自动挂载

    UUID=39ba4f2c-1495-483b-943c-ed1b0fd4fef5  /disk1  ext4  defaults  0  0

如果是挂载的硬盘用于存放 MySQL 数据的 ext4 文件系统，使用下面的挂载方式能提高性能

    UUID=39ba4f2c-1495-483b-943c-ed1b0fd4fef5  /disk1  ext4  defaults,noatime  0  0

`mount -a` 挂载所有磁盘。

## Hostname Setting (optinal)

>T: Tower Server  
>R: Rack Server  
>B: Blade Server  

r[server-id].domain.com

## Update Packages and Kernal

将系统软件内核等更新到最新版本，更新完之后根据情况重启服务器(一般情况下是不需要重启的，如果更新了 kernel ，那么重启之前新 kernel 是不会生效的)

    yum check-update
    yum update

## Create a User Account

添加普通用户用于 ssh 远程登录：

    /usr/sbin/useradd -U -m -s /bin/bash common
    /usr/bin/passwd common

下面的语句将已有的用户附加到 common 群组中

    usermod -G common user

## SSH Settings

`vi /etc/ssh/sshd_config` 修改端口地址，禁止root远程登录等

    Port 9022
    Protocol 2
    ListenAddress 192.168.1.1
    PermitRootLogin no
    UseDNS no
    AllowUsers common

`vi /etc/profile.d/autologout.sh` 添加 ssh client 超时退出设置

    TMOUT=600
    readonly TMOUT
    export TMOUT

`vi /etc/profile.d/history.sh` 修改系统 history 的日志条数大小和时间戳

    HISTSIZE=20
    readonly HISTSIZE
    export HISTSIZE

    HISTTIMEFORMAT="%y-%m-%d %T "
    readonly HISTTIMEFORMAT
    export HISTTIMEFORMAT

修改权限

    chmod 644 /etc/profile.d/autologout.sh
    chmod 644 /etc/profile.d/history.sh
    chown root:root /etc/profile.d/autologout.sh
    chown root:root /etc/profile.d/history.sh

`vi /etc/sysconfig/iptables` 修改防火墙 打开 sshd 的 9022 端口和 http 的 80 端口

    -A INPUT -m state --state NEW -m tcp -p tcp --dport 9022 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT

## Add Yum Repositories

`vi /etc/resolv.conf` 修改 DNS 服务器，因为下面的有些域名国内的 DNS 服务商可能解析不到

    nameserver 8.8.8.8
    nameserver 8.8.4.4
    nameserver 114.114.114.114

安装 epel / remi / mysql 的 YUM 源

    rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
    rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
    rpm -Uvh http://dev.mysql.com/get/mysql-community-release-el6-5.noarch.rpm
    rpm -Uvh http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm

`vi /etc/yum.repos.d/nginx.repo` 添加 nginx 官方 YUM 源

    [nginx]
    name=nginx repo
    baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
    gpgcheck=0
    enabled=1

`vi /etc/yum.repos.d/remi.repo` 将 remi 源的 **[remi]** 和 **[remi-php56]** 设置为 `enabled=1`

## Create System Accounts

添加 mysql 和 www 两个系统用户分别作为 MySQL 和 Nginx 的运行用户

    /usr/sbin/useradd -U -m -r -s /sbin/nologin -c "MySQL User" mysql
    /usr/sbin/useradd -U -m -r -s /sbin/nologin -c "HTTP Server User" www

## Install Nginx PHP MySQL

    yum install jemalloc jemalloc-devel mysql-community-server mysql-community-client mysql-community-common wget nginx php-cli php-fpm php-mysqlnd php-gd php-common php php-pdo php-mbstring php-mcrypt php-opcache

## MySQL Settings

`vi /etc/my.cnf` 编辑 MySQL 的基础配置，下面的配置项依情况设定

    [client]

    # CLIENT #
    port                           = 3306
    socket                         = /home/mysql/data/mysql.sock

    [mysqld]

    # GENERAL #
    user                           = mysql
    default-storage-engine         = InnoDB
    socket                         = /home/mysql/data/mysql.sock
    pid-file                       = /var/run/mysqld/mysqld.pid
    auto_increment_increment       = 17

    # MyISAM #
    key-buffer-size                = 32M
    myisam-recover                 = FORCE,BACKUP

    # SAFETY #
    max-allowed-packet             = 16M
    max-connect-errors             = 1000000
    skip-name-resolve
    symbolic-links                 = 0
    sysdate-is-now                 = 1
    innodb                         = FORCE
    innodb-strict-mode             = 1
    explicit_defaults_for_timestamp

    # DATA STORAGE #
    datadir                        = /home/mysql/data/

    # BINARY LOGGING #
    log-bin                        = mysql-bin
    expire-logs-days               = 14
    sync-binlog                    = 1

    # CACHES AND LIMITS #
    tmp-table-size                 = 32M
    max-heap-table-size            = 32M
    query-cache-type               = 0
    query-cache-size               = 0
    max-connections                = 500
    thread-cache-size              = 50
    open-files-limit               = 65535
    table-definition-cache         = 1024
    table-open-cache               = 4096

    # INNODB #
    innodb-flush-method            = O_DIRECT
    innodb-log-files-in-group      = 2
    innodb-log-file-size           = 128M
    innodb-flush-log-at-trx-commit = 1
    innodb-file-per-table          = 1
    innodb-buffer-pool-size        = 1456M

    # LOGGING #
    log-error                      = /var/log/mysql/mysql-error.log
    log_warnings                   = 1
    log-queries-not-using-indexes  = 0
    slow-query-log                 = 1
    slow-query-log-file            = /home/mysql/data/mysql-slow.log
    long_query_time                = 1

    # CHARSET #
    character-set-server           = utf8
    collation-server               = utf8_unicode_ci
    skip-character-set-client-handshake

    # PERFORMANCE SCHEMA #
    performance_schema             = 0

    # REPLICATION #
    server-id                      = 1

    [mysql]
    no-auto-rehash
    safe-updates

    [mysqld_safe]
    malloc-lib=/usr/lib64/libjemalloc.so

创建 MySQL 的日志目录

    mkdir /var/log/mysql/
    chown mysql:mysql /var/log/mysql/

`vi /etc/init.d/mysqld` 编辑 MySQL 的启动文件修改下面一行，添加 `--defaults-file=/etc/my.cnf`

> result=\`/usr/bin/my_print_defaults **--defaults-file=/etc/my.cnf** "$1" | sed -n "s/^--$2=//p" | tail -n 1\`

初始化数据库

    mysql_install_db --user=mysql --datadir=/home/mysql/data

初始化之后启动服务器 `service mysqld start`，设置 MySQL 基本的安全配置修改密码等

    ln -s /home/mysql/data/mysql.sock /var/lib/mysql/mysql.sock

    /usr/bin/mysql_secure_installation

`vi /home/mysql/backup/mysqldump_backup.sh` 设置数据库逻辑备份

    #!/bin/bash

    readonly MYSQL_BACKUP_1=/home/mysql/backup/
    readonly MYSQL_BACKUP_2=/disk1/mysql-backup/

    readonly MYSQL_FILE_NAME=databasename.$(date -d "yesterday" +"%Y-%m-%d").sql

    mysqldump --defaults-extra-file=/home/mysql/backup/pass.conf --add-locks --create-options --flush-logs --lock-tables --port=3306 --extended-insert databasename > ${MYSQL_BACKUP_1}${MYSQL_FILE_NAME}

    if [[ -f ${MYSQL_BACKUP_1}${MYSQL_FILE_NAME} ]];  then
        chmod 600 ${MYSQL_BACKUP_1}${MYSQL_FILE_NAME}
        cp ${MYSQL_BACKUP_1}${MYSQL_FILE_NAME} ${MYSQL_BACKUP_2}${MYSQL_FILE_NAME} && chmod 600 ${MYSQL_BACKUP_2}${MYSQL_FILE_NAME}
    fi

`vi /home/mysql/backup/pass.conf` 创建密码文件，并更改权限 `chmod 600 /home/mysql/backup/pass.conf`

    [client]
    user = username
    password = password

`crontab -e -uroot` 创建备份定时任务

    00 00 * * * /bin/bash /home/mysql/backup/mysqldump_cron.sh

## PHP Settings

`vi /etc/php.ini` 修改 PHP 的基本配置

    date.timezone = Asia/Shanghai
    expose_php = Off
    session.name = JSESSIONID
    display_errors = Off
    max_execution_time = 30
    memory_limit = 8M
    post_max_size = 8M
    file_uploads = On
    upload_max_filesize = 2M
    log_errors = On
    allow_url_fopen = Off

`vi /etc/php-fpm.d/www.conf` 修改 php-fpm 的基本配置

    user = www
    group = www

## Nginx Settings

`vi /etc/nginx/nginx.conf` 编辑 Nginx 配置文件

    user www www;
    worker_processes  8;
    worker_cpu_affinity 00000001 00000010 00000100 00001000 00010000 00100000 01000000 10000000;

    timer_resolution            1000ms;
    worker_rlimit_nofile        100000;

    error_log  /var/log/nginx/error.log notice;
    pid        /var/run/nginx.pid;

    events {
        use epoll;
        worker_connections  1024;
    }

    http {

        #don't send the nginx version number in error pages and Server header
        server_tokens off;

        # config to don't allow the browser to render the page inside an frame or iframe
        # and avoid clickjacking http://en.wikipedia.org/wiki/Clickjacking
        # if you need to allow [i]frames, you can use SAMEORIGIN or even set an uri with ALLOW-FROM uri
        # https://developer.mozilla.org/en-US/docs/HTTP/X-Frame-Options
        add_header X-Frame-Options SAMEORIGIN;

        # when serving user-supplied content, include a X-Content-Type-Options: nosniff header along with the Content-Type: header,
        # to disable content-type sniffing on some browsers.
        # https://www.owasp.org/index.php/List_of_useful_HTTP_headers
        # currently suppoorted in IE > 8 http://blogs.msdn.com/b/ie/archive/2008/09/02/ie8-security-part-vi-beta-2-update.aspx
        # http://msdn.microsoft.com/en-us/library/ie/gg622941(v=vs.85).aspx
        # 'soon' on Firefox https://bugzilla.mozilla.org/show_bug.cgi?id=471020
        add_header X-Content-Type-Options nosniff;

        # This header enables the Cross-site scripting (XSS) filter built into most recent web browsers.
        # It's usually enabled by default anyway, so the role of this header is to re-enable the filter for
        # this particular website if it was disabled by the user.
        # https://www.owasp.org/index.php/List_of_useful_HTTP_headers
        add_header X-XSS-Protection "1; mode=block";

        # with Content Security Policy (CSP) enabled(and a browser that supports it(http://caniuse.com/#feat=contentsecuritypolicy),
        # you can tell the browser that it can only download content from the domains you explicitly allow
        # http://www.html5rocks.com/en/tutorials/security/content-security-policy/
        # https://www.owasp.org/index.php/Content_Security_Policy
        # I need to change our application code so we can increase security by disabling 'unsafe-inline' 'unsafe-eval'
        # directives for css and js(if you have inline css or js, you will need to keep it too).
        # more: http://www.html5rocks.com/en/tutorials/security/content-security-policy/#inline-code-considered-harmful
        add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src 'self'; style-src 'self' 'unsafe-inline'; font-src 'self'";

        include       /etc/nginx/mime.types;
        default_type  application/octet-stream;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        sendfile  on;
        tcp_nopush  on;

        keepalive_timeout  10;
        send_timeout  1000;

        client_body_buffer_size  8k;
        client_max_body_size 4096m;
        client_body_timeout 10;

        client_header_buffer_size 8k;
        large_client_header_buffers 4 8k;
        client_header_timeout 10;

        gzip on;
        gzip_min_length  1024;
        gzip_buffers     4 16k;
        gzip_http_version 1.0;
        gzip_comp_level 2;
        gzip_types       text/plain application/x-javascript text/css application/xml;
        gzip_vary on;

        include /etc/nginx/conf.d/*.conf;
    }

`vi /etc/nginx/conf.d/[server-name].conf` 编辑 server 配置文件

    server {
        listen       192.168.1.1:80;
        server_name  192.168.1.1;

        access_log  /var/log/nginx/access.log  main;

        root /home/www/webroot;

        location / {
            index  index.php index.html;
        }

        location ~ ^/data/ {
            internal;
        }

        location ~ ^/(application|system)/(.*)$ {
            return 404;
        }

        if ($http_user_agent ~ ^$) {
            return 412;
        }

        error_page  404              /404.html;

        error_page  500 502 503 504  /50x.html;

        location ~ \.php$ {
            fastcgi_split_path_info ^(.+?\.php)(/.*)$;
            if (!-f $document_root$fastcgi_script_name) {
                return 404;
            }
            
            # limit_except  GET POST {
            #     deny   all;
            # }

            charset utf-8;
            
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
            include fastcgi_params;
        }

        location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|js|ico|css)$ {
            expires    360d;
            add_header Pragma public;
            add_header Cache-Control "public, must-revalidate, proxy-revalidate";
        }

        location ~ /\. {
            access_log off;
            log_not_found off;
            deny all;
        }
    }

`vi /etc/logrotate.d/nginx` 配置日志每天轮换切割

    /var/log/nginx/*.log {
            daily
            missingok
            rotate 52
            compress
            delaycompress
            notifempty
            create 640 www www
            sharedscripts
            postrotate
                    [ -f /var/run/nginx.pid ] && kill -USR1 `cat /var/run/nginx.pid`
            endscript
    }
