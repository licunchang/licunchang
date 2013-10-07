**File Name** centos-nginx-mysql-php-memcached.md  

**Description** LNMP (Linux:CentOS6.4 + Nginx + MySQL + PHP) 安装文档    
**Author** LiCunchang(printf@live.com)   
**Version** 3.0.20130728  

------

## 1 准备

### 1.1 yum 源配置  

如果没有可用的网络进行 yum(Yellow dog Updater, Modified)安装则需要配置本地的 yum 安装源，使用本地光盘作为 yum 源，如果有网络连接可用，则推荐使用163的 yum 源，跳过本步骤，具体详见[CentOS镜像使用帮助](http://mirrors.163.com/.help/centos.html)。

    mkdir /mnt/cdrom
    mount /dev/cdrom /mnt/cdrom
    cd /etc/yum.repos.d/

禁用掉系统中其他的 yum 源有两种方式：  

1.将以 .repo 结尾的文件重命名  
2.将每个配置文件中的 enabled=1 改为 enabled=0  

    mv CentOS-Base.repo CentOS-Base.repo_licunchang.bak
    mv CentOS-Debuginfo.repo CentOS-Debuginfo.repo_licunchang.bak
    mv CentOS-Media.repo CentOS-Media.repo_licunchang.bak
    mv CentOS-Vault.repo CentOS-Vault.repo_licunchang.bak

    vi CentOS-Dvd.repo

文件中添加：

    [c6-dvd]
    name=CentOS-$releasever - Dvd
    baseurl=file:///mnt/cdrom/
    gpgcheck=0
    enabled=1

重建 yum 缓存

    yum makecache

### 1.2 编译工具等安装

    yum -y install make cmake gcc gcc-c++ chkconfig automake autoconf

### 1.3 所需源码包

*  nginx-1.4.2.tar.gz
*  openssl-1.0.1e.tar.gz
*  pcre-8.33.tar.gz
*  mysql-5.6.13.tar.gz
*  php-5.5.4.tar.gz
*  libiconv-1.14.tar.gz
*  mcrypt-2.6.8.tar.gz
*  mhash-0.9.9.9.tar.gz
*  libmcrypt-2.5.8.tar.gz
*  libevent-2.0.21-stable.tar.gz
*  memcached-1.4.15.tar.gz
*  re2c-0.13.6.tar.gz

所有的源码包放置在 /usr/local/src 目录下。

## 2 MySQL

### 2.1 安装依赖包

    yum -y install zlib zlib-devel ncurses ncurses-devel bison
  
### 2.2 创建运行账户及数据目录

添加一个 MySQL 使用的用户和用户组(`-r`:添加一个系统用户或用户组)：

    /usr/sbin/groupadd -r mysql
    /usr/sbin/useradd -g mysql -M -r -s /bin/false mysql
    
将 MySQL 的数据文件放置在 /data/mysql 目录下，配置文件 my.cnf 放置在 /etc/mysql 目录下：

    mkdir -p /data/mysql
    chown -R mysql:mysql /data/mysql
    mkdir -p /etc/mysql
    chown -R mysql:mysql /etc/mysql

MySQL 的 bin-log 是顺序写日志，需要提供较高的顺序写能力，MySQL 的数据日志需要提供较高的随机读写能力。与此同时，有条件的情况下将 bin-log 和数据文件分开存储是有益处的，而事务日志则可以和数据文件存放在一起。

### 2.3 源码安装

    cd /usr/local/src
    tar zxvf /usr/local/src/mysql-5.6.13.tar.gz
    cd /usr/local/src/mysql-5.6.13
    cmake /usr/local/src/mysql-5.6.13/ -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
                                       -DMYSQL_DATADIR=/data/mysql \
                                       -DSYSCONFDIR=/etc/mysql \
                                       -DDEFAULT_CHARSET=utf8 \
                                       -DDEFAULT_COLLATION=utf8_general_ci \
                                       -DWITH_EXTRA_CHARSETS=all \
                                       -DWITH_INNOBASE_STORAGE_ENGINE=1 \
                                       -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
                                       -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
                                       -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 \
                                       -DWITH_PARTITION_STORAGE_ENGINE=1 \
                                       -DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 \
                                       -DWITHOUT_FEDERATED_STORAGE_ENGINE=1 \
                                       -DWITH_READLINE=1 \
                                       -DENABLED_LOCAL_INFILE=1 \
                                       -DENABLED_PROFILING=1 \
                                       -DMYSQL_TCP_PORT=3306

    make
    make install
    
### 2.4 初始化数据目录和数据

    cd /usr/local/mysql/
    /usr/local/mysql/scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql

脚本会在程序根目录下生成一个配置文件 my.cnf ，没什么用，删掉。

### 2.5 配置 my.cnf 文件

    rm -f /etc/my.cnf
    rm -f /usr/local/mysql/my.cnf
    vi /etc/mysql/my.cnf

5.6 的系统中默认不再分发my-huge.cnf、my-large.cnf、my-medium.cnf等几个默认配置文件，我们需要根据自己的情况来配置一个 my.cnf，下面的配置适合 2GB 内存服务器使用

    [client]

    # CLIENT #
    port                           = 3306
    socket                         = /tmp/mysql.sock

    [mysqld]

    # GENERAL #
    user                           = mysql
    default-storage-engine         = InnoDB
    socket                         = /tmp/mysql.sock
    pid-file                       = /data/mysql/mysql.pid

    # MyISAM #
    key-buffer-size                = 32M
    myisam-recover                 = FORCE,BACKUP

    # SAFETY #
    max-allowed-packet             = 16M
    max-connect-errors             = 1000000
    skip-name-resolve
    sql-mode                       = STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_AUTO_VALUE_ON_ZERO,NO_ENGINE_SUBSTITUTION,NO_ZERO_DATE,NO_ZERO_IN_DATE,ONLY_FULL_GROUP_BY
    sysdate-is-now                 = 1
    innodb                         = FORCE
    innodb-strict-mode             = 1

    # DATA STORAGE #
    datadir                        = /data/mysql/

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
    default-storage-engine         = INNODB
    innodb-flush-method            = O_DIRECT
    innodb-log-files-in-group      = 2
    innodb-log-file-size           = 128M
    innodb-flush-log-at-trx-commit = 1
    innodb-file-per-table          = 1
    innodb-buffer-pool-size        = 1456M

    # LOGGING #
    log-error                      = /data/mysql/mysql-error.log
    log_warnings                   = 1
    log-queries-not-using-indexes  = 1
    slow-query-log                 = 1
    slow-query-log-file            = /data/mysql/mysql-slow.log
    long_query_time                = 2

    # CHARSET #
    character-set-server           = utf8
    collation-server               = utf8_general_ci
    skip-character-set-client-handshake

    # PERFORMANCE SCHEMA #
    performance_schema             = 1

    # REPLICATION #
    server-id                      = 1

    [mysql]
    no-auto-rehash
    safe-updates
    
添加字符集配置和慢查询日志，记录没有使用索引的查询，`general-log` 将开启一般日志，所有查询语句将记录到日志中，不推荐在生产环境中使用，仅限测试环境调试。log-bin 记录 master 服务器的 bin_log 的名称，如果不设置此选项，那么 MySQL 使用 `hostname-bin` 的形式，如果主机更改 hostname 那么 slaver 服务器将无法找到主服务器的 bin-log 从而产生错误，从这个角度上讲，设置一个 bin-log 名称是有必要的。
    
使用 InnoDB 以下选项

* **innodb\_data\_file\_path** 调整数据库表空间增量
* **innodb\_buffer\_pool\_size** 调整为内存总量的50% - 80%
* **innodb\_log\_file\_size** 调整为`innodb_buffer_pool_size`的25%

### 2.6 创建 MySQL 启动停止脚本

你可以把 MySQL 加入系统启动，系统启动时自动启动 MySQL 服务，不过生产环境不推荐这么做。

    cp /usr/local/mysql/support-files/mysql.server  /etc/rc.d/init.d/mysql

    vi /etc/rc.d/init.d/mysql

编辑 MySQL 启动脚本，设置 basedir 和 datadir

    basedir=/usr/local/mysql
    datadir=/data/mysql

增加执行权限

    chmod 755 /etc/rc.d/init.d/mysql
    chkconfig --add mysql
    chkconfig --level 35 mysql on
    
启动 MySQL 服务

    service mysql start

### 2.7 MySQL安全设置

MySQL 提供了一个脚本在安装初期修改密码的脚本，执行脚本，按照提醒即可对默认密码用户等进行修改

    cd /usr/local/mysql/
    /usr/local/mysql/bin/mysql_secure_installation

登录 MySQL 服务器

    /usr/local/mysql/bin/mysql -uroot -p

创建数据库

    DROP DATABASE IF EXISTS `licunchang`;
    CREATE DATABASE IF NOT EXISTS `licunchang` DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE 'utf8_general_ci';

授权用户

    GRANT INSERT, DELETE, UPDATE, SELECT ON licunchang.* TO 'username'@'%' IDENTIFIED BY 'password' WITH GRANT OPTION;

### 2.8 MySQL 防火墙设置

配置防火墙，开启 3306 端口

    vi /etc/sysconfig/iptables

把这条规则添加到默认的 22 端口这条规则的下面

    -A INPUT -m state --state NEW -m tcp -p tcp --dport 3306 -j ACCEPT

重新启动 iptables 服务

    service iptables restart

## 3 PHP
    
### 3.1 安装依赖包

    yum -y install libxml2 libjpeg freetype libpng gd curl fontconfig libxml2-devel curl-devel libjpeg-devel libpng-devel freetype-devel
    
### 3.2 安装 libiconv

    cd /usr/local/src
    tar zxvf libiconv-1.14.tar.gz
    cd /usr/local/src/libiconv-1.14
    ./configure --prefix=/usr/local/libiconv
    make
    make install
    
### 3.2 安装 libmcrypt & mhash & mcrypt

    cd /usr/local/src
    tar zxvf libmcrypt-2.5.8.tar.gz
    cd /usr/local/src/libmcrypt-2.5.8
    ./configure --prefix=/usr/local/libmcrypt
    make
    make install
    
    cd /usr/local/src/libmcrypt-2.5.8/libltdl
    ./configure --enable-ltdl-install
    make
    make install
    
    cd /usr/local/src
    tar zxvf mhash-0.9.9.9.tar.gz
    cd /usr/local/src/mhash-0.9.9.9
    ./configure --prefix=/usr/local/mhash
    make
    make install
    
    cd /usr/local/src
    tar zxvf mcrypt-2.6.8.tar.gz
    cd /usr/local/src/mcrypt-2.6.8
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/libmcrypt/lib:/usr/local/mhash/lib
    export LDFLAGS="-L/usr/local/mhash/lib/ -I/usr/local/mhash/include/"
    export CFLAGS="-I/usr/local/mhash/include/"
    ./configure --prefix=/usr/local/mcrypt --with-libmcrypt-prefix=/usr/local/libmcrypt
    make
    make install

### 3.3 创建 nginx 及 php-fpm 运行用户及用户组
    
    /usr/sbin/groupadd -r www
    /usr/sbin/useradd -g www -M -r -s /bin/false www
    
### 3.4 安装 php

    cd /usr/local/src
    tar zxvf re2c-0.13.6.tar.gz
    cd /usr/local/src/re2c-0.13.6
    ./configure
    make
    make install

    cd /usr/local/src
    tar zxvf php-5.5.4.tar.gz
    cd /usr/local/src/php-5.5.4

使用 mysqlnd 驱动，则使用下面的编译方法（推荐）

    ./configure --prefix=/usr/local/php \
                --with-config-file-path=/usr/local/php/etc \
                --enable-bcmath \
                --enable-shmop \
                --enable-sysvsem \
                --enable-ftp \
                --enable-opcache \
                --with-curl \
                --with-png-dir \
                --with-jpeg-dir \
                --with-freetype-dir \
                --with-gd \
                --enable-gd-native-ttf \
                --enable-mbstring \
                --enable-soap \
                --enable-sockets \
                --enable-zip \
                --with-xmlrpc \
                --with-mysql=mysqlnd \
                --with-mysqli=mysqlnd \
                --with-pdo-mysql=mysqlnd \
                --enable-fpm \
                --with-fpm-user=www \
                --with-fpm-group=www \
                --with-zlib \
                --with-iconv-dir=/usr/local/libiconv/ \
                --with-pcre-dir=/usr/local/pcre \
                --with-libxml-dir \
                --with-mcrypt=/usr/local/libmcrypt/ \
                --with-mhash=/usr/local/mhash/ \
                --disable-ipv6

使用 libmysql 驱动，则使用下面的编译方法

    ./configure --prefix=/usr/local/php \
                --with-config-file-path=/usr/local/php/etc \
                --enable-bcmath \
                --enable-shmop \
                --enable-sysvsem \
                --enable-ftp \
                --with-curl \
                --with-png-dir \
                --with-jpeg-dir \
                --with-freetype-dir \
                --with-gd \
                --enable-gd-native-ttf \
                --enable-mbstring \
                --enable-soap \
                --enable-sockets \
                --enable-zip \
                --with-xmlrpc \
                --with-mysql=/usr/local/mysql \
                --with-mysqli=/usr/local/mysql/bin/mysql_config \
                --with-pdo-mysql=/usr/local/mysql/ \
                --enable-fpm \
                --with-fpm-user=www \
                --with-fpm-group=www \
                --with-zlib \
                --with-iconv-dir=/usr/local/libiconv/ \
                --with-pcre-dir=/usr/local/pcre \
                --with-libxml-dir \
                --with-mcrypt=/usr/local/libmcrypt/ \
                --with-mhash=/usr/local/mhash/ \
                --disable-ipv6

    make
    # make test # 安装前可以使用 make test 做一下测试，发现安装过程中的错误
    make install

### 3.5 配置 php.ini 及 php-fpm.conf

创建 php.ini 及 php-fpm.conf文件

    cp php.ini-production /usr/local/php/etc/php.ini
    rm -rf /etc/php.ini
    # ln -s /usr/local/php/etc/php.ini  /etc/php.ini
    cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf

编辑 php-fpm.conf 文件

    vi /usr/local/php/etc/php-fpm.conf

    pid = run/php-fpm.pid
    user = www
    group = www

pm 这几个选项在 php-fpm.conf 中有详细的功能描述，不清楚的可以查看文档注释

    pm = dynamic

    pm.max_children = 8
    pm.start_servers = 4
    pm.min_spare_servers = 1
    pm.max_spare_servers = 3

编辑 php.ini 文件

    vi /usr/local/php/etc/php.ini

    date.timezone = Asia/Shanghai
    expose_php = Off

### 3.6 把 php-fpm 加入系统启动

同样的，生产环境中不推荐这么做

    cp /usr/local/src/php-5.5.4/sapi/fpm/init.d.php-fpm /etc/rc.d/init.d/php-fpm
    chmod 755 /etc/rc.d/init.d/php-fpm
    chkconfig --add php-fpm
    chkconfig --level 35 php-fpm on

启动 php-fpm

    service php-fpm start

## 4 Nginx

### 4.1 安装 pcre

    cd /usr/local/src
    tar zxvf pcre-8.33.tar.gz
    cd /usr/local/src/pcre-8.33
    ./configure  --prefix=/usr/local/pcre --enable-utf --enable-pcre16 --enable-pcre32 --enable-jit --enable-unicode-properties
    make
    make install
    
### 4.2 安装nginx

    cd /usr/local/src
    tar zxvf openssl-1.0.1e.tar.gz
    
    tar zxvf nginx-1.4.2.tar.gz
    cd /usr/local/src/nginx-1.4.2

安全原因，你可以修改 Nginx 的服务器标识信息

    sed -i 's/nginx\b/Microsoft-IIS/g' ./src/core/nginx.h
    sed -i 's/1.4.2/7.5/' ./src/core/nginx.h
    sed -i 's/Server: nginx/Server: Microsoft-IIS/' ./src/http/ngx_http_header_filter_module.c
    sed -i 's/>nginx</>Microsoft-IIS</' ./src/http/ngx_http_special_response.c
    
安装

    ./configure --with-http_stub_status_module --with-http_gzip_static_module --with-http_ssl_module --with-openssl=/usr/local/src/openssl-1.0.1e --user=www --group=www --prefix=/usr/local/nginx --with-pcre=/usr/local/src/pcre-8.33 --with-http_realip_module --with-cpu-opt=amd64
    make
    make install

### 4.3 配置 nginx.conf 文件修改

    vi /usr/local/nginx/conf/nginx.conf

    # user [user] [group]
    user  www www;

    # the numbers of CPU cores
    worker_processes  4;

    # Binds worker processes to the sets of CPUs
    worker_cpu_affinity 1000 0100 0010 0001;

    #error_log  logs/error.log;
    error_log  logs/error.log  notice;
    #error_log  logs/error.log  info;

    pid        logs/nginx.pid;

    events {
        use epoll;
        worker_connections  1024;
    }

    http {

        # disabled nginx version in error messages and in the “Server” response header field.
        #server_tokens off;
        include       mime.types;
        default_type  application/octet-stream;

        log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

        access_log  logs/access.log  main;

        # Enable the use of sendfile()
        sendfile        on;
        #tcp_nopush     on;
        keepalive_timeout  65;

        gzip on;
        # Sets the minimum length of a response that will be gzipped. The length is determined only from the “Content-Length” response header field.
        gzip_min_length  1k;
        # Sets the [number] and [size] of buffers used to compress a response. By default, the buffer size is equal to one memory page. This is either 4K or 8K, depending on a platform.
        gzip_buffers     4 16k;
        gzip_http_version 1.0;
        # Acceptable values are in the 1..9 range.
        gzip_comp_level 2;
        gzip_types       text/plain application/x-javascript text/css application/xml;
        gzip_vary on;

        server {
            server_name licunchang.com;
            rewrite ^(.*) http://www.licunchang.com$1 permanent;
        }

        # if the client didn't give a user_agent, return 412
        if ($http_user_agent ~ ^$) {
            return 412;
        }

        #Only allow these request methods, Do not accept DELETE, SEARCH and other methods
        if ($request_method !~ ^(GET|HEAD|POST)$ ) {
            return 405;
        }

        # Only requests to our Host are allowed
        if ($host !~ ^(licunchang.com|www.licunchang.com|mysql.licunchang.com)$ ) {
            return 444;
        }
        
        include /usr/local/nginx/conf/servers/*.conf;

    }

### 4.4 添加 Server

    mkdir /usr/local/nginx/conf/servers/

    vi /usr/local/nginx/conf/servers/www.licunchang.com.conf

    # BEGIN ------------------------------------------- www.licunchang.com.conf
    server {
        listen       80;
        server_name  www.licunchang.com;
        
        root  /data/web/www.licunchang.com;
        
        #charset utf-8;

        access_log  /usr/local/nginx/logs/www.licunchang.com.access.log  main;

        location / {
            index  index.php index.html;
        }

        rewrite ^(.*)/attatchment/(.*)\.php$ /404.html  last;

        error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        # location ~ \.php$ {
        location ~ .*\.(php|do|inc|tpl)?$ {
            if (!-f $document_root$fastcgi_script_name) {
                    return 404;
            }
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }
        
        location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|js|ico|css)$ {
            expires      360d;
            add_header Cache-Control no-cache;
            add_header Cache-Control private;
        }

        location ~ /\. {
            access_log off;
            log_not_found off; 
            deny all;
        }
    }
    # END --------------------------------------------- www.licunchang.com.conf

配置 phpmyadmin 

    vi /usr/local/nginx/conf/servers/mysql.licunchang.com.conf

    # BEGIN ----------------------------------------- mysql.licunchang.com.conf
    server {
        listen       80;
        server_name  mysql.licunchang.com;
        
        root  /data/web/mysql.licunchang.com;
        
        #charset utf-8;

        access_log  /usr/local/nginx/logs/mysql.licunchang.com.access.log  main;

        location / {
            # Notice: the subnet is 10.10.10.0
            allow  10.10.10.0/24;
            index  index.php index.html;
        }

        error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        # location ~ \.php$ {
        location ~ .*\.(php|do|inc|tpl)?$ {
            if (!-f $document_root$fastcgi_script_name) {
                    return 404;
            }
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }
        
        location ~ .*\.(gif|jpg|jpeg|png|bmp|swf|js|ico|css)$ {
            expires      360d;
        }

        location ~ /\. {
            access_log off;
            log_not_found off; 
            deny all;
        }
    }
    # END ------------------------------------------- mysql.licunchang.com.conf

`mkdir -p /data/web/mysql.licunchang.com` 并上传 phpmyadmin 文件到 **/data/web/mysql.licunchang.com**
    
    mkdir -p /data/web/mysql.licunchang.com

    cd /data/web/mysql.licunchang.com

配置 nginx 状态监控应用

    vi /usr/local/nginx/conf/servers/status.licunchang.com.conf

    # BEGIN ------------------------------------------- status.licunchang.com.conf
    server {
        listen  80;
        server_name  status.licunchang.com;

        location / {
            # allow 10.10.10.0/24;
            stub_status  on;
            access_log  off;
        }
    }
    # END --------------------------------------------- status.licunchang.com.conf

    chown www:www /data/web/mysql.licunchang.com  -R
    chmod 744 /data/web/mysql.licunchang.com  -R
    
### 4.5 把 nginx 加入系统启动

同样不推荐在生产环境中作为服务自动启动

    vi /etc/rc.d/init.d/nginx

开机[启动脚本](http://wiki.nginx.org/RedHatNginxInitScript)内容(有所修改)

    #!/bin/bash
    #
    # nginx    Start/Stop the cron clock daemon.
    #
    # chkconfig: 35 85 15
    # description: Nginx is an HTTP and reverse proxy server, as well as a mail proxy server.
    #
    # processname: nginx
    # bin:      /usr/local/nginx/sbin/nginx
    # config:   /usr/local/nginx/conf/nginx.conf
    # pidfile:  /usr/local/nginx/logs/nginx.pid

    ################################################################################
    # Make required directories | user | group .
    # Globals:
    #   NGINX_SBIN_FILE
    # Arguments:
    #   None
    # Returns:
    #   None
    ################################################################################
    prepare() {

        local options="$(${NGINX_SBIN_FILE} -V 2>&1 | grep 'configure arguments:')"

        local nginx_user="$(echo ${options} | sed 's/[^*]*--user=\([^ ]*\).*/\1/g')"
        local nginx_group="$(echo ${options} | sed 's/[^*]*--group=\([^ ]*\).*/\1/g')"

        local group=$(grep "^${nginx_group}" /etc/group | awk -F: '{print $1}')
        local user=$(grep "^${nginx_user}" /etc/passwd | awk -F: '{print $1}')

        if [[ "${nginx_group}" != "${group}" ]]; then
            /usr/sbin/groupadd -r "${nginx_group}"
            if [[ "$?" -ne 0 ]]; then
                echo "can't create a group for nginx"
                exit 1
            fi
        fi

        if [[ "${nginx_user}" != "${user}" ]]; then
            /usr/sbin/useradd -r -M -g ${nginx_group} -s /bin/false ${nginx_user}
            if [[ "$?" -ne 0 ]]; then
                echo "can't create a user for nginx"
                exit 1
            fi
        fi

        for option in ${options}; do
            if [[ -n "$(echo ${option} | grep '.*-temp-path')" ]]; then
                directory="$(echo $option | cut -d "=" -f 2)"
                if [[ ! -d "${directory}" ]]; then
                    mkdir -p "${directory}" && chown -R "${nginx_user}" "${directory}"
                fi
            fi
        done
    }

    ################################################################################
    # Start up nginx.
    # Globals:
    #   NGINX_SBIN_FILE
    #   NGINX_CONF_FILE
    #   NGINX_LOCK_FILE
    #   NGINX_PROG_NAME
    # Arguments:
    #   None
    # Returns:
    #   Integer
    ################################################################################
    start() {
        if [[ ! -x ${NGINX_SBIN_FILE} ]]; then
            exit 1
        fi
        if [[ ! -f ${NGINX_CONF_FILE} ]]; then
            exit 6
        fi

        prepare
        echo -n "Starting ${NGINX_PROG_NAME}: "
        daemon ${NGINX_SBIN_FILE} -c ${NGINX_CONF_FILE}
        exit_code=$?
        echo
        if [[ ${exit_code} -eq 0 ]]; then
            touch ${NGINX_LOCK_FILE}
        fi
        return ${exit_code}
    }

    ################################################################################
    # Stop nginx.
    # Globals:
    #   NGINX_PROG_NAME
    #   NGINX_LOCK_FILE
    # Arguments:
    #   None
    # Returns:
    #   Integer
    ################################################################################
    stop() {
        echo -n "Stopping ${NGINX_PROG_NAME}: "
        # QUIT:graceful shutdown
        killproc ${NGINX_PROG_NAME} -QUIT
        exit_code=$?
        echo
        if [[ ${exit_code} -eq 0 ]]; then
            rm -f ${NGINX_LOCK_FILE}
        fi
        return ${exit_code}
    }

    ################################################################################
    # Retart nginx.
    # Globals:
    #   None
    # Arguments:
    #   None
    # Returns:
    #   None
    ################################################################################
    restart() {
        configtest || return $?
        stop
        sleep 1
        start
    }

    ################################################################################
    # Reload nginx configuration file.
    # Globals:
    #   NGINX_PROG_NAME
    #   NGINX_SBIN_FILE
    # Arguments:
    #   None
    # Returns:
    #   Integer
    ################################################################################
    reload() {
        configtest || return $?
        echo -n "Reloading ${NGINX_PROG_NAME}: "
        # changing configuration, keeping up with a changed time zone (only for FreeBSD and Linux), 
        # starting new worker processes with a new configuration, graceful shutdown of old worker processes
        killproc ${NGINX_SBIN_FILE} -HUP
        exit_code=$?
        echo
        return ${exit_code}
    }

    ################################################################################
    # Re-opening nginx log files.
    # Globals:
    #   NGINX_SBIN_FILE
    # Arguments:
    #   None
    # Returns:
    #   Integer
    ################################################################################
    reopen-logs() {
        configtest || return $?
        echo -n "Re-opening ${NGINX_PROG_NAME} log files: "
        # re-opening log files
        killproc ${NGINX_SBIN_FILE} -USR1
        exit_code=$?
        echo
        return ${exit_code}
    }

    ################################################################################
    # Check the nginx configuration file.
    # Globals:
    #   NGINX_SBIN_FILE
    #   NGINX_CONF_FILE
    # Arguments:
    #   None
    # Returns:
    #   None
    ################################################################################
    configtest() {
        ${NGINX_SBIN_FILE} -t -c ${NGINX_CONF_FILE}
    }

    ################################################################################
    # Check the nginx status.
    # Globals:
    #   NGINX_PROG_NAME
    # Arguments:
    #   None
    # Returns:
    #   None
    ################################################################################
    rh_status() {
        status ${NGINX_PROG_NAME}
    }

    ################################################################################
    # Check the nginx status without any output.
    # Globals:
    #   None
    # Arguments:
    #   None
    # Returns:
    #   None
    ################################################################################
    rh_status_q() {
        rh_status >/dev/null 2>&1
    }

    # Source function library.
    . /etc/rc.d/init.d/functions

    # Source networking configuration.
    . /etc/sysconfig/network

    # Check that networking is up.
    if [[ "${NETWORKING}" = "no" ]]; then
        echo "Networking is not available."
        exit 6
    fi

    readonly NGINX_SBIN_FILE="/usr/local/nginx/sbin/nginx"
    readonly NGINX_CONF_FILE="/usr/local/nginx/conf/nginx.conf"
    readonly NGINX_LOCK_FILE="/var/lock/subsys/nginx"
    readonly NGINX_PROG_NAME=$(basename ${NGINX_SBIN_FILE})

    case "$1" in
        start)
            rh_status_q && exit 0
            $1
            ;;
        stop)
            rh_status_q || exit 0
            $1
            ;;
        restart|configtest)
            $1
            ;;
        reload)
            rh_status_q || exit 7
            $1
            ;;
        reopen-logs)
            rh_status_q || exit 7
            $1
            ;;
        status)
            rh_status
            ;;
        *)
            echo "Usage: {start|stop|status|restart|reload|reopen-logs|configtest}"
            exit 2
    esac
    exit $?

启动脚本权限

    chmod 755 /etc/rc.d/init.d/nginx
    chkconfig --add nginx 
    chkconfig --level 35 nginx on

    service nginx start

### 4.6 创建 webroot 目录

    mkdir -p /data/web/www.licunchang.com

    cd /data/web/www.licunchang.com

    touch favicon.ico

    echo "404 Not Found" > 404.html

    echo "50x Server Error" > 50x.html
    echo "500 Internal Server Error" > 500.html
    echo "501 Not Implemented" > 501.html
    echo "502 Bad Gateway" > 502.html
    echo "503 Service Unavailable" > 503.html
    echo "504 Gateway Timeout" > 504.html
    echo "505 HTTP Version Not Supported" > 505.html
    
    echo "<?php echo phpinfo();" > index.php

    chown www:www /data/web/www.licunchang.com  -R
    chmod 744 /data/web/www.licunchang.com  -R

    mkdir -p /data/web/mysql.licunchang.com

    cd /data/web/mysql.licunchang.com

    chown www:www /data/web/mysql.licunchang.com  -R
    chmod 744 /data/web/mysql.licunchang.com  -R

### 4.7 nginx 日志切割

    mkdir -p /data/logs/nginx/
    mkdir -p /data/cron/

部署 nginx 日志切割任务 `crontab -u root -e`，每天零时切割日志

    00 00 * * * /bin/bash /data/cron/nginx_logs_cut.sh

创建脚本 `vi /data/cron/nginx_logs_cut.sh`

    #!/bin/bash
    #
    #description    cut nginx log files, run at 00:00 everyday
    #crontab        00 00 * * * /bin/bash /data/cron/nginx_logs_cut.sh
    #author         LiCunchang(printf@live.com)

    ### PART 1: Move web logs to the backup directory which named by year & month.

    readonly LOGS_PATH="/usr/local/nginx/logs/"
    readonly APP_NAME=(www.licunchang.com mysql.licunchang.com)
    readonly LOGS_BACKUP="/data/logs/nginx/$(date -d "yesterday" +"%Y%m")/"

    if [[ ! -d "${LOGS_BACKUP}" ]]; then
        mkdir -p "${LOGS_BACKUP}"
    fi

    readonly APP_NUM=${#APP_NAME[@]}

    for ((i=0; i<"${APP_NUM}"; i++)); do
        if [[ -f ${LOGS_PATH}${APP_NAME[i]}.access.log ]]; then
            mv ${LOGS_PATH}${APP_NAME[i]}.access.log ${LOGS_BACKUP}${APP_NAME[i]}.access_$(date -d "yesterday" +"%Y%m%d%H%M%S").log
        fi
        if [[ -f ${LOGS_PATH}${APP_NAME[i]}.error.log ]]; then
            mv ${LOGS_PATH}${APP_NAME[i]}.error.log ${LOGS_BACKUP}${APP_NAME[i]}.error_$(date -d "yesterday" +"%Y%m%d%H%M%S").log
        fi
    done

    if [[ -f ${LOGS_PATH}error.log ]]; then
        mv ${LOGS_PATH}error.log ${LOGS_BACKUP}error_$(date -d "yesterday" +"%Y%m%d%H%M%S").log
    fi

    if [[ -f ${LOGS_PATH}access.log ]]; then
        mv ${LOGS_PATH}access.log ${LOGS_BACKUP}access_$(date -d "yesterday" +"%Y%m%d%H%M%S").log
    fi

    chmod 444 "${LOGS_BACKUP}"  -R

    ### PART 2: make the nginx server reopen a new log files if the nginx is running.

    # Source function library.
    . /etc/rc.d/init.d/functions

    readonly NGINX="/usr/local/nginx/sbin/nginx"
    readonly NGINX_CONF_FILE="/usr/local/nginx/conf/nginx.conf"
    readonly PROG=$(basename "$NGINX")

    reopen-logs() {
        ${NGINX} -t -c ${NGINX_CONF_FILE} || return $?
        echo -n $"Re-opening log files: "
        # changing configuration, keeping up with a changed time zone (only for FreeBSD and Linux), 
        # starting new worker processes with a new configuration, graceful shutdown of old worker processes
        killproc ${NGINX} -USR1
        retval=$?
        echo
        return ${retval}
    }

    rh_status() {
        status ${PROG}
    }

    rh_status_q() {
        rh_status >/dev/null 2>&1
    }

    # Check that networking is up.
    rh_status_q && reopen-logs

    ### PART 3: remove the old logs to free some disk space.

    cd ${LOGS_BACKUP}
    cd ..

    readonly LOGS_LIFETIME_MONTHS=12
    find . -mtime +$((${LOGS_LIFETIME_MONTHS}*30)) -exec rm -rf {} \;

### 4.8 配置防火墙

配置防火墙，开启 80 端口

    vi /etc/sysconfig/iptables

把这条规则添加到默认的 22 端口这条规则的下面

    -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT

重新启动 iptables 服务

    service iptables restart

## 5 Memcached

### 5.1 安装libevent
    
    cd /usr/local/src
    tar zxvf libevent-2.0.21-stable.tar.gz
    cd /usr/local/src/libevent-2.0.21-stable
    ./configure  --prefix=/usr/local/libevent
    make
    make install
    
### 5.2 安装memcached

    cd /usr/local/src
    tar zxvf memcached-1.4.15.tar.gz
    cd /usr/local/src/memcached-1.4.15
    ./configure  --prefix=/usr/local/memcached --with-libevent=/usr/local/libevent --enable-64bit
    make
    make install

