**File Name** centos-nginx-mysql-php-memcached.md  

**Description** LNMP (Linux:CentOS6.4 + Nginx + MySQL + PHP) 安装文档    
**Author** LiCunchang(printf@live.com)  
**Version** 3.0.20130326  

------

## 1 准备

### 1.1 yum源配置  

如果没有可用的网络进行yum(Yellow dog Updater, Modified)安装则需要配置本地的yum安装源，使用本地光盘作为yum源，如果有网络连接可用，则推荐使用163的yum源，跳过本步骤，具体详见[CentOS镜像使用帮助](http://mirrors.163.com/.help/centos.html)。

    mkdir /mnt/cdrom
    mount /dev/cdrom /mnt/cdrom
    cd /etc/yum.repos.d/

禁用掉系统中其他的yum源有两种方式：  

1.将以.repo结尾的文件重命名  
2.将每个配置文件中的enabled=1改为enabled=0  

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

重建yum缓存

    yum makecache

### 1.2 编译工具等安装

    yum -y install make cmake gcc gcc-c++ chkconfig automake autoconf

### 1.3 所需源码包

*  nginx-1.4.2.tar.gz
*  openssl-1.0.1e.tar.gz
*  pcre-8.32.tar.gz
*  mysql-5.5.32.tar.gz
*  php-5.4.14.tar.gz
*  libiconv-1.14.tar.gz
*  mcrypt-2.6.8.tar.gz
*  mhash-0.9.9.9.tar.gz
*  libmcrypt-2.5.8.tar.gz
*  libevent-2.0.21-stable.tar.gz
*  memcached-1.4.15.tar.gz
*  re2c-0.13.5.tar.gz

所有的源码包放置在/usr/local/src目录下。

## 2 MySQL

### 2.1 安装依赖包

    yum -y install zlib zlib-devel ncurses ncurses-devel bison
  
### 2.2 创建运行账户及数据目录

添加一个MySQL使用的用户和用户组：

    /usr/sbin/groupadd -r mysql
    /usr/sbin/useradd -g mysql -M -r -s /bin/false mysql
    
将MySQL的数据文件放置在/data/mysql目录下，配置文件my.cnf放置在/etc/mysql目录下：

    mkdir -p /data/mysql
    chown -R mysql:mysql /data/mysql
    mkdir -p /etc/mysql
    chown -R mysql:mysql /etc/mysql
    
### 2.3 源码安装

    cd /usr/local/src
    tar zxvf /usr/local/src/mysql-5.5.32.tar.gz
    cd /usr/local/src/mysql-5.5.32
    cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/data/mysql -DSYSCONFDIR=/etc/mysql -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=all -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 -DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 -DWITHOUT_FEDERATED_STORAGE_ENGINE=1 -DWITHOUT_PARTITION_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DWITH_LIBWRAP=1 -DENABLED_LOCAL_INFILE=1 -DENABLED_PROFILING=1 -DMYSQL_TCP_PORT=3306 -DWITH_ZLIB=system
    make
    make install
    
### 2.4 配置my.cnf文件

    rm -f /etc/my.cnf
    
系统提供了几个配置文件样例，可根据系统资源情况进行设置，各配置文件的说明如下：    

* my-huge.cnf 

>This is for a large system with memory of 1G-2G where the system runs mainly MySQL.  

* my-large.cnf 

>This is for a large system with memory = 512M where the system runs mainly MySQL.  

* my-medium.cnf

>This is for a system with little memory (32M - 64M) where MySQL plays an important part, or systems up to 128M where MySQL is used together with other programs (such as a web server).  

* my-small.cnf 

>This is for a system with little memory (<= 64M) where MySQL is only used from time to time and it's important that the mysqld daemon doesn't use much resources.  

* my-innodb-heavy-4G.cnf

>This is a MySQL example config file for systems with 4GB of memory running mostly MySQL using InnoDB only tables and performing complex queries with few connections.    

    cd /usr/local/src/mysql-5.5.32
    cp ./support-files/my-medium.cnf /etc/mysql/my.cnf

编辑my.cnf文件

    vi /etc/mysql/my.cnf

添加字符集配置和慢查询日志，记录没有使用索引的查询，仅限测试环境调试。

    [client]
    default-character-set=utf8

    [mysqld]
    datadir=/data/mysql
    character_set_server=utf8
    collation-server=utf8_general_ci
    skip-character-set-client-handshake
    general-log
    log-warnings
    long_query_time=2
    slow-query-log
    log-queries-not-using-indexes
    innodb_file_per_table
    
使用InnoDB打开以下选项

    # Uncomment the following if you are using InnoDB tables
    innodb_data_home_dir = /data/mysql
    innodb_data_file_path = ibdata1:10M:autoextend
    innodb_log_group_home_dir = /data/mysql
    # You can set .._buffer_pool_size up to 50 - 80 %
    # of RAM but beware of setting memory usage too high
    innodb_buffer_pool_size = 16M
    innodb_additional_mem_pool_size = 2M
    # Set .._log_file_size to 25 % of buffer pool size
    innodb_log_file_size = 5M
    innodb_log_buffer_size = 8M
    innodb_flush_log_at_trx_commit = 1
    innodb_lock_wait_timeout = 50

其中

* **innodb\_data\_file\_path** 调整数据库表空间增量
* **innodb\_buffer\_pool\_size** 调整为内存总量的50% - 80%
* **innodb\_log\_file\_size** 调整为`innodb_buffer_pool_size`的25%

### 2.6 生成授权表

    /usr/local/mysql/scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql

### 2.7 创建 MySQL 启动停止脚本

你可以把MySQL加入系统启动，系统启动时自动启动MySQL服务：

    cp /usr/local/mysql/support-files/mysql.server  /etc/rc.d/init.d/mysql

    vi /etc/rc.d/init.d/mysql

编辑MySQL启动脚本，设置basedir和datadir：

    basedir=/usr/local/mysql
    datadir=/data/mysql

增加执行权限

    chmod 755 /etc/rc.d/init.d/mysql
    chkconfig --add mysql
    chkconfig --level 35 mysql on
    
启动mysql服务

    service mysql start

### 2.8 MySQL安全设置

修改密码

    cd /usr/local/mysql/
    /usr/local/mysql/bin/mysql_secure_installation

登录MySQL服务器

    /usr/local/mysql/bin/mysql -uroot -p

创建数据库

    DROP DATABASE IF EXISTS `licunchang`;
    CREATE DATABASE IF NOT EXISTS `licunchang` DEFAULT CHARACTER SET 'utf8' DEFAULT COLLATE 'utf8_general_ci';

授权用户

    GRANT INSERT, DELETE, UPDATE, SELECT ON licunchang.* TO 'username'@'%' IDENTIFIED BY 'password' WITH GRANT OPTION;

### 2.9 MySQL防火墙设置

配置防火墙，开启3306端口

    vi /etc/sysconfig/iptables

把这条规则添加到默认的22端口这条规则的下面

    -A INPUT -m state --state NEW -m tcp -p tcp --dport 3306 -j ACCEPT

重新启动iptables服务

    service iptables restart

## 3 PHP
    
### 3.1 安装依赖包

    yum -y install libxml2 libjpeg freetype libpng gd curl fontconfig libxml2-devel curl-devel libjpeg-devel libpng-devel freetype-devel
    
### 3.2 安装libiconv

    cd /usr/local/src
    tar zxvf libiconv-1.14.tar.gz
    cd /usr/local/src/libiconv-1.14
    ./configure --prefix=/usr/local/libiconv
    make
    make install
    
### 3.2 安装libmcrypt & mhash & mcrypt

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
    
### 3.4 安装php

    cd /usr/local/src
    tar zxvf re2c-0.13.5.tar.gz
    ./configure
    make
    make install

    cd /usr/local/src
    tar zxvf php-5.4.17.tar.gz
    cd /usr/local/src/php-5.4.17
    ./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --enable-bcmath --enable-shmop --enable-sysvsem --enable-ftp --with-curl --with-curlwrappers --with-png-dir --with-jpeg-dir --with-freetype-dir --with-gd --enable-gd-native-ttf --enable-mbstring --enable-soap --enable-sockets --enable-zip --with-xmlrpc --with-mysql=/usr/local/mysql --with-mysqli=/usr/local/mysql/bin/mysql_config --with-pdo-mysql=/usr/local/mysql/ --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-zlib --with-iconv-dir=/usr/local/libiconv/ --with-pcre-dir=/usr/local/pcre --with-libxml-dir --with-mcrypt=/usr/local/libmcrypt/ --with-mhash=/usr/local/mhash/ --disable-ipv6
    make
    # make test #注意:make test可能有错
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

    cp /usr/local/src/php-5.4.14/sapi/fpm/init.d.php-fpm /etc/rc.d/init.d/php-fpm
    chmod 755 /etc/rc.d/init.d/php-fpm
    chkconfig --add php-fpm
    chkconfig --level 35 php-fpm on

启动 php-fpm

    service php-fpm start

## 4 Nginx

### 4.1 安装 pcre

    cd /usr/local/src
    tar zxvf pcre-8.32.tar.gz
    cd /usr/local/src/pcre-8.32
    ./configure  --prefix=/usr/local/pcre --enable-utf --enable-pcre16 --enable-pcre32 --enable-jit --enable-unicode-properties
    make
    make install
    
### 4.2 安装nginx

    cd /usr/local/src
    tar zxvf openssl-1.0.1e.tar.gz
    
    tar zxvf nginx-1.2.8.tar.gz
    cd /usr/local/src/nginx-1.2.8

安全原因，你可以修改 Nginx 的服务器标识信息

    sed -i 's/nginx\b/Microsoft-IIS/g' ./src/core/nginx.h
    sed -i 's/1.2.8/7.5/' ./src/core/nginx.h
    sed -i 's/Server: nginx/Server: Microsoft-IIS/' ./src/http/ngx_http_header_filter_module.c
    sed -i 's/>nginx</>Microsoft-IIS</' ./src/http/ngx_http_special_response.c
    
安装

    ./configure --with-http_stub_status_module --with-http_gzip_static_module --with-http_ssl_module --with-openssl=/usr/local/src/openssl-1.0.1e --user=www --group=www --prefix=/usr/local/nginx --with-pcre=/usr/local/src/pcre-8.32 --with-http_realip_module --with-cpu-opt=amd64
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

    chown www.www /data/web/mysql.licunchang.com  -R
    chmod 744 /data/web/mysql.licunchang.com  -R
    
### 4.5 把 nginx 加入系统启动

    vi /etc/rc.d/init.d/nginx

开机[启动脚本](http://wiki.nginx.org/RedHatNginxInitScript)内容

    #!/bin/bash
    #
    # nginx - this script starts and stops the nginx daemon
    #
    # chkconfig: 35 85 15
    # description: Nginx is an HTTP and reverse proxy server, as well as a mail proxy server.
    #
    # processname: nginx
    # bin:      /usr/local/nginx/sbin/nginx
    # config:   /usr/local/nginx/conf/nginx.conf
    # pidfile:  /usr/local/nginx/logs/nginx.pid

    # Source function library.
    . /etc/rc.d/init.d/functions

    # Source networking configuration.
    . /etc/sysconfig/network

    # Check that networking is up.
    [ "${NETWORKING}" = "no" ] && exit 6

    NGINX="/usr/local/nginx/sbin/nginx"
    NGINX_CONF_FILE="/usr/local/nginx/conf/nginx.conf"

    prog=$(basename $NGINX)
    lockfile=/var/lock/subsys/nginx

    # make required directories
    make_dirs() {
        NGINX_USER=`$NGINX -V 2>&1 | grep "configure arguments:" | sed 's/[^*]*--user=\([^ ]*\).*/\1/g' -`
        if [ -z "`grep $NGINX_USER /etc/passwd`" ]; then
            if [ -z "`grep $NGINX_USER /etc/group`" ]; then
                /usr/sbin/groupadd $NGINX_USER
            fi
            /usr/sbin/useradd -M -g $NGINX_USER -s /bin/false $NGINX_USER
        fi
        OPTIONS=`$NGINX -V 2>&1 | grep 'configure arguments:'`
        for OPT in $OPTIONS; do
            if [ `echo $OPT | grep '.*-temp-path'` ]; then
                VALUE=`echo $OPT | cut -d "=" -f 2`
                if [ ! -d "$VALUE" ]; then
                    # echo "creating" $value
                    mkdir -p $VALUE && chown -R $NGINX_USER $VALUE
                fi
            fi
        done
    }

    start() {
        if [ ! -x $NGINX ]; then
            exit 1
        fi
        if [ ! -f $NGINX_CONF_FILE ]; then
            exit 6
        fi

        make_dirs
        echo -n $"Starting $prog: "
        daemon $NGINX -c $NGINX_CONF_FILE
        RETVAL=$?
        echo
        [ $RETVAL -eq 0 ] && touch $lockfile
        return $RETVAL
    }

    stop() {
        echo -n $"Stopping $prog: "
        # QUIT:graceful shutdown
        killproc $prog -QUIT
        RETVAL=$?
        echo
        [ $RETVAL -eq 0 ] && rm -f $lockfile
        return $RETVAL
    }

    restart() {
        configtest || return $?
        stop
        sleep 1
        start
    }

    reload() {
        configtest || return $?
        echo -n $"Reloading $prog: "
        # changing configuration, keeping up with a changed time zone (only for FreeBSD and Linux), 
        # starting new worker processes with a new configuration, graceful shutdown of old worker processes
        killproc $NGINX -HUP
        RETVAL=$?
        echo
        return $RETVAL
    }

    reopen-logs() {
        configtest || return $?
        echo -n $"Re-opening log files: "
        # re-opening log files
        killproc $NGINX -USR1
        RETVAL=$?
        echo
        return $RETVAL
    }

    configtest() {
        $NGINX -t -c $NGINX_CONF_FILE
    }

    rh_status() {
        status $prog
    }

    rh_status_q() {
        rh_status >/dev/null 2>&1
    }

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
        condrestart|try-restart)
            rh_status_q || exit 0
            ;;
        *)
            echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|reopen-logs|configtest}"
            exit 2
    esac
    exit $?

启动脚本权限

    chmod 755 /etc/rc.d/init.d/nginx
    chkconfig --add nginx 
    chkconfig --level 35 nginx on

    service nginx restart

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

    chown www.www /data/web/www.licunchang.com  -R
    chmod 744 /data/web/www.licunchang.com  -R

    mkdir -p /data/web/mysql.licunchang.com

    cd /data/web/mysql.licunchang.com

    chown www.www /data/web/mysql.licunchang.com  -R
    chmod 744 /data/web/mysql.licunchang.com  -R

### 4.7 nginx 日志切割

    mkdir -p /data/logs/nginx/
    mkdir -p /data/cron/

部署 nginx 日志切割任务 `crontab -u root -e`

    00 00 * * * /bin/bash /data/cron/nginx_logs_cut.sh

创建脚本 `vi /data/cron/nginx_logs_cut.sh`

    #!/bin/bash
    #description    cut nginx log files, run at 00:00 everyday
    #crontab        00 00 * * * /bin/bash /data/cron/nginx_logs_cut.sh
    #author         LiCunchang(printf@live.com)

    ### PART 1: Move web logs to the backup directory which named by year & month.

    LOGS_PATH=/usr/local/nginx/logs/
    APP_NAME=(www.licunchang.com mysql.licunchang.com)
    LOGS_BACKUP=/data/logs/nginx/$(date -d "yesterday" +"%Y%m")/

    if [ ! -d $LOGS_BACKUP ]; then
        mkdir -p $LOGS_BACKUP
    fi

    APP_NUM=${#APP_NAME[@]}

    for ((i=0; i<$APP_NUM; i++)); do
        if [ -f ${LOGS_PATH}${APP_NAME[i]}.access.log ]; then
            mv ${LOGS_PATH}${APP_NAME[i]}.access.log ${LOGS_BACKUP}${APP_NAME[i]}.access_$(date -d "yesterday" +"%Y%m%d%H%M%S").log
        fi
        if [ -f ${LOGS_PATH}${APP_NAME[i]}.error.log ]; then
            mv ${LOGS_PATH}${APP_NAME[i]}.error.log ${LOGS_BACKUP}${APP_NAME[i]}.error_$(date -d "yesterday" +"%Y%m%d%H%M%S").log
        fi
    done

    if [ -f ${LOGS_PATH}error.log ]; then
        mv ${LOGS_PATH}error.log ${LOGS_BACKUP}error_$(date -d "yesterday" +"%Y%m%d%H%M%S").log
    fi

    if [ -f ${LOGS_PATH}access.log ]; then
        mv ${LOGS_PATH}access.log ${LOGS_BACKUP}access_$(date -d "yesterday" +"%Y%m%d%H%M%S").log
    fi

    chmod 444 $LOGS_BACKUP  -R

    ### PART 2: make the nginx server reopen a new log files if the nginx is running.

    # Source function library.
    . /etc/rc.d/init.d/functions

    NGINX="/usr/local/nginx/sbin/nginx"
    NGINX_CONF_FILE="/usr/local/nginx/conf/nginx.conf"

    prog=$(basename $NGINX)
    lockfile=/var/lock/subsys/nginx

    reopen-logs() {
        $NGINX -t -c $NGINX_CONF_FILE || return $?
        echo -n $"Re-opening log files: "
        # changing configuration, keeping up with a changed time zone (only for FreeBSD and Linux), 
        # starting new worker processes with a new configuration, graceful shutdown of old worker processes
        killproc $NGINX -USR1
        RETVAL=$?
        echo
        return $RETVAL
    }

    rh_status() {
        status $prog
    }

    rh_status_q() {
        rh_status >/dev/null 2>&1
    }

    # Check that networking is up.
    rh_status_q && reopen-logs

    ### PART 3: remove the old logs to free some disk space.

    cd $LOGS_BACKUP
    cd ..

    LOGS_LIFETIME_MONTHS=12
    find . -mtime +$(($LOGS_LIFETIME_MONTHS*30)) -exec rm -rf {} \;

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

