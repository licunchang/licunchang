#!/bin/bash
# description    Install nginx1.2.7 & mysql5.5.30 & php5.4.12 on CentOS6.4
# author         LiCunchang

# 1 nginx-1.2.7.tar.gz
# 2 openssl-1.0.1e.tar.gz
# 3 pcre-8.32.tar.gz
# 4 mysql-5.5.30.tar.gz
# 5 php-5.4.12.tar.gz
# 6 libiconv-1.14.tar.gz
# 7 mcrypt-2.6.8.tar.gz
# 8 mhash-0.9.9.9.tar.gz
# 9 libmcrypt-2.5.8.tar.gz

# source directory: /usr/local/src

#   /data
#       |-/web
#           |-/www.licunchang.com
#           |-/mysql.licunchang.com
#           |-......
#       |-/mysql
#       |-/logs
#           |-/nginx
#       |-/backup
#           |-/mysql
#           |-/app
#       |-/cron

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
if [ "$NETWORKING" = "no" ]; then
    echo "network is not available."
    exit 1
else
    echo "network is working."
fi

# Create yum repository from cdrom media
echo "create yum repository from cdrom media."
cdrom_mount_dir="/mnt/cdrom"
if [ ! -d "$cdrom_mount_dir" ]; then
    mkdir $cdrom_mount_dir
    exit_value=$?
    if [ $exit_value -gt 0 ]; then
        echo "can't create a directory as a mount point"
    fi
fi

if [ -z "`ls -A "$cdrom_mount_dir"`" ]; then
    echo "mount cdrom"
    mount /dev/cdrom $cdrom_mount_dir
fi

cd /etc/yum.repos.d

ls | grep -i '.repo$' > repo.list
if [ `cat repo.list | wc -l` -ne 0 ]; then
    for repo in `cat repo.list`
    do
        echo "backup the repo files:$repo"
        mv $repo ${repo}_licunchang.bak
    done
fi

rm -f repo.list

touch CentOS-Dvd.repo

cat > CentOS-Dvd.repo <<'EOF'
[c6-dvd]
name=CentOS-$releasever - Dvd
baseurl=file:///mnt/cdrom/
gpgcheck=0
enabled=1
EOF

yum makecache

yum -y install make cmake gcc gcc-c++ chkconfig automake autoconf

cd /usr/local/src

# unzip the packages
ls | grep -i '.tar.gz$' > tar.list
if [ `cat tar.list | wc -l` -ne 0 ]; then
    for tar in `cat tar.list`
    do
        echo "unzip the package: $tar"
        tar zxf $tar
    done
fi

rm -f tar.list

# install mysql5.5.30
mysql() {

    # yum install zlib zlib-devel ncurses ncurses-devel bison
    yum -y install zlib zlib-devel ncurses ncurses-devel bison

    # Create a mysql User and Group
    echo "create a mysql user and group."
    /usr/sbin/groupadd mysql
    /usr/sbin/useradd -g mysql mysql -s /bin/false

    # Create the mysql data directory: /data/mysql
    echo "create the mysql data directory."
    mkdir -p /data/mysql
    chown -R mysql:mysql /data/mysql
    # Create the mysql conf directory: /etc/mysql
    echo "create the mysql conf directory."
    mkdir -p /etc/mysql
    chown -R mysql:mysql /etc/mysql

    cd /usr/local/src/mysql-5.5.30
    cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/data/mysql -DSYSCONFDIR=/etc/mysql -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DWITH_EXTRA_CHARSETS=all -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 -DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 -DWITHOUT_FEDERATED_STORAGE_ENGINE=1 -DWITHOUT_PARTITION_STORAGE_ENGINE=1 -DWITH_READLINE=1 -DWITH_LIBWRAP=1 -DENABLED_LOCAL_INFILE=1 -DENABLED_PROFILING=1 -DMYSQL_TCP_PORT=3306 -DWITH_ZLIB=system
    make
    make install

    # Create the config file
    echo "create the config file."
    rm -f /etc/my.cnf
    
    # Free Memory
    memory_free=`free -m | grep Mem | awk '{print $4}'`
    
    if [ $memory_free -le 128 ]; then
        echo "copy my-medium.cnf as the configuration file"
        cp -f /usr/local/src/mysql-5.5.30/support-files/my-medium.cnf /etc/mysql/my.cnf
    fi
    
    if [ $memory_free -le 512 -a $memory_free -gt 128 ]; then
        echo "copy my-large.cnf as the configuration file"
        cp -f /usr/local/src/mysql-5.5.30/support-files/my-large.cnf /etc/mysql/my.cnf
    fi
    
    if [ $memory_free -le 4096 -a $memory_free -gt 512 ]; then
        echo "copy my-huge.cnf as the configuration file"
        cp -f /usr/local/src/mysql-5.5.30/support-files/my-huge.cnf /etc/mysql/my.cnf
    fi
    
    if [ $memory_free -gt 4096 ]; then
        echo "copy my-innodb-heavy-4G.cnf as the configuration file"
        cp -f /usr/local/src/mysql-5.5.30/support-files/my-innodb-heavy-4G.cnf /etc/mysql/my.cnf
    fi
    
    #vi /etc/mysql/my.cnf
    #[client]
    #default-character-set=utf8
    sed -i '/^\[client\]/a\default-character-set=utf8' /etc/mysql/my.cnf
    
    #[mysqld]
    #datadir = /data/mysql
    #character_set_server=utf8
    #collation-server=utf8_general_ci
    #skip-character-set-client-handshake
    #general-log
    #log-warnings
    #long_query_time=2
    #slow-query-log
    #log-queries-not-using-indexes
    
    sed -i '/^\[mysqld\]/a\
datadir = /data/mysql\
character_set_server=utf8\
collation-server=utf8_general_ci\
skip-character-set-client-handshake\
general-log\
log-warnings\
long_query_time=2\
slow-query-log\
log-queries-not-using-indexes\
innodb_file_per_table' /etc/mysql/my.cnf

    ## Uncomment the following if you are using InnoDB tables
    #innodb_data_home_dir = /data/mysql
    #innodb_data_file_path = ibdata1:10M:autoextend
    #innodb_log_group_home_dir = /data/mysql
    ## You can set .._buffer_pool_size up to 50 - 80 %
    ## of RAM but beware of setting memory usage too high
    #innodb_buffer_pool_size = 16M
    #innodb_additional_mem_pool_size = 2M
    ## Set .._log_file_size to 25 % of buffer pool size
    #innodb_log_file_size = 5M
    #innodb_log_buffer_size = 8M
    #innodb_flush_log_at_trx_commit = 1
    #innodb_lock_wait_timeout = 50
    
    sed -i 's/^#innodb_data_home_dir/innodb_data_home_dir/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_data_file_path/innodb_data_file_path/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_log_group_home_dir/innodb_log_group_home_dir/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_buffer_pool_size/innodb_buffer_pool_size/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_additional_mem_pool_size/innodb_additional_mem_pool_size/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_log_file_size/innodb_log_file_size/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_log_buffer_size/innodb_log_buffer_size/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_flush_log_at_trx_commit/innodb_flush_log_at_trx_commit/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_lock_wait_timeout/innodb_lock_wait_timeout/' /etc/mysql/my.cnf
    
    /usr/local/mysql/scripts/mysql_install_db --user=mysql --basedir=/usr/local/mysql --datadir=/data/mysql
    
    #cp -f /usr/local/mysql/support-files/mysql.server /etc/rc.d/init.d/mysql
    ##vi /etc/rc.d/init.d/mysql
    ##basedir=/usr/local/mysql
    ##datadir=/data/mysql
    #sed -i 's#^basedir=$#basedir=/usr/local/mysql#' /etc/rc.d/init.d/mysql
    #sed -i 's#^datadir=$#datadir=/data/mysql#' /etc/rc.d/init.d/mysql
    #chmod 754 /etc/rc.d/init.d/mysql
    #chkconfig --add mysql
    #chkconfig --level 35 mysql on
    #service mysql start
    
    mkdir -p /data/scripts/
    cp -f /usr/local/mysql/support-files/mysql.server /data/scripts/mysql
    sed -i 's#^basedir=$#basedir=/usr/local/mysql#' /data/scripts/mysql
    sed -i 's#^datadir=$#datadir=/data/mysql#' /data/scripts/mysql
    chmod 755 /data/scripts/mysql

    /data/scripts/mysql start
    
    cd /usr/local/mysql/
    /usr/local/mysql/bin/mysql_secure_installation <<EOF

y
root
root
y
y
y
y
EOF
    
    #vi /etc/sysconfig/iptables
    sed -i '/^-A INPUT -i lo -j ACCEPT$/a\
-A INPUT -m state --state NEW -m tcp -p tcp --dport 3306 -j ACCEPT' /etc/sysconfig/iptables
    
    service iptables restart
    
    return $?
}

#instal php 5.4.12
php() {

    yum -y install libxml2 libjpeg freetype libpng gd curl fontconfig libxml2-devel curl-devel libjpeg-devel libpng-devel freetype-devel

    cd /usr/local/src/libiconv-1.14
    ./configure --prefix=/usr/local/libiconv
    make
    make install
    
    cd /usr/local/src/libmcrypt-2.5.8
    ./configure --prefix=/usr/local/libmcrypt
    make
    make install
    
    cd /usr/local/src/libmcrypt-2.5.8/libltdl
    ./configure --enable-ltdl-install
    make
    make install
    
    cd /usr/local/src/mhash-0.9.9.9
    ./configure --prefix=/usr/local/mhash
    make
    make install
    
    cd /usr/local/src/mcrypt-2.6.8
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/libmcrypt/lib:/usr/local/mhash/lib
    export LDFLAGS="-L/usr/local/mhash/lib/ -I/usr/local/mhash/include/"
    export CFLAGS="-I/usr/local/mhash/include/"
    ./configure --prefix=/usr/local/mcrypt --with-libmcrypt-prefix=/usr/local/libmcrypt
    make
    make install
    
    /usr/sbin/groupadd www
    /usr/sbin/useradd -g www www -s /bin/false

    cd /usr/local/src/php-5.4.12
    ./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --enable-bcmath --enable-shmop --enable-sysvsem --enable-ftp --with-curl --with-curlwrappers --with-png-dir --with-jpeg-dir --with-freetype-dir --with-gd --enable-gd-native-ttf --enable-mbstring --enable-soap --enable-sockets --enable-zip --with-xmlrpc --with-mysql=/usr/local/mysql --with-mysqli=/usr/local/mysql/bin/mysql_config --with-pdo-mysql=/usr/local/mysql/ --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-zlib --with-iconv-dir=/usr/local/libiconv/ --with-pcre-dir=/usr/local/pcre --with-libxml-dir --with-mcrypt=/usr/local/libmcrypt/ --with-mhash=/usr/local/mhash/
    make
    make install
    
    cp -f /usr/local/src/php-5.4.12/php.ini-production /usr/local/php/etc/php.ini
    rm -rf /etc/php.ini

    # vi /usr/local/php/etc/php.ini

    sed -i 's#^;date.timezone =#date.timezone = Asia/Shanghai#' /usr/local/php/etc/php.ini
    sed -i 's#^expose_php = On#expose_php = Off#' /usr/local/php/etc/php.ini
  
    cp -f /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
    
    # vi /etc/php/php-fpm.conf
    # pid = run/php-fpm.pid
    # user = www
    # group = www
    
    sed -i 's/^;pid/pid/' /usr/local/php/etc/php-fpm.conf

    #php-fpm
    
    # Choose how the process manager will control the number of child processes.
    # Possible Values:
    #   static  - a fixed number (pm.max_children) of child processes#
    #   dynamic - the number of child processes are set dynamically based on the
    #             following directives. With this process management, there will be
    #             always at least 1 children.
    #             pm.max_children      - the maximum number of children that can
    #                                    be alive at the same time.
    #             pm.start_servers     - the number of children created on startup.
    #             pm.min_spare_servers - the minimum number of children in 'idle'
    #                                    state (waiting to process). If the number
    #                                    of 'idle' processes is less than this
    #                                    number then some children will be created.
    #             pm.max_spare_servers - the maximum number of children in 'idle'
    #                                    state (waiting to process). If the number
    #                                    of 'idle' processes is greater than this
    #                                    number then some children will be killed.
    #  ondemand - no children are created at startup. Children will be forked when
    #             new requests will connect. The following parameter are used:
    #             pm.max_children           - the maximum number of children that
    #                                         can be alive at the same time.
    #             pm.process_idle_timeout   - The number of seconds after which
    #                                         an idle process will be killed.
    # Note: This value is mandatory.
    # pm = dynamic
    
    # The number of child processes to be created when pm is set to 'static' and the
    # maximum number of child processes when pm is set to 'dynamic' or 'ondemand'.
    # This value sets the limit on the number of simultaneous requests that will be
    # served. Equivalent to the ApacheMaxClients directive with mpm_prefork.
    # Equivalent to the PHP_FCGI_CHILDREN environment variable in the original PHP
    # CGI. The below defaults are based on a server without much resources. Don't
    # forget to tweak pm.* to fit your needs.
    # Note: Used when pm is set to 'static', 'dynamic' or 'ondemand'
    # Note: This value is mandatory.
    # pm.max_children = 5
    
    # The number of child processes created on startup.
    # Note: Used only when pm is set to 'dynamic'
    # Default Value: min_spare_servers + (max_spare_servers - min_spare_servers) / 2
    # pm.start_servers = 2

    # The desired minimum number of idle server processes.
    # Note: Used only when pm is set to 'dynamic'
    # Note: Mandatory when pm is set to 'dynamic'
    # pm.min_spare_servers = 1

    # The desired maximum number of idle server processes.
    # Note: Used only when pm is set to 'dynamic'
    # Note: Mandatory when pm is set to 'dynamic'
    # pm.max_spare_servers = 3

    cp -f /usr/local/src/php-5.4.12/sapi/fpm/init.d.php-fpm /data/scripts/php-fpm
    
    chmod 755 /data/scripts/php-fpm

    /data/scripts/php-fpm start
    
    return #?
}

# install nginx 1.2.7
nginx() {
    
    cd /usr/local/src/pcre-8.32
    ./configure  --prefix=/usr/local/pcre --enable-utf --enable-pcre16 --enable-pcre32 --enable-jit --enable-unicode-properties
    make
    make install
    
    cd /usr/local/src/nginx-1.2.7
    
    sed -i 's/nginx\b/Microsoft-IIS/g' ./src/core/nginx.h
    sed -i 's/1.2.7/7.5/' ./src/core/nginx.h
    sed -i 's/Server: nginx/Server: Microsoft-IIS/' ./src/http/ngx_http_header_filter_module.c
    sed -i 's/>nginx</>Microsoft-IIS</' ./src/http/ngx_http_special_response.c
    
    ./configure --with-http_stub_status_module --with-http_gzip_static_module --with-http_ssl_module --with-openssl=/usr/local/src/openssl-1.0.1e --user=www --group=www --prefix=/usr/local/nginx --with-pcre=/usr/local/src/pcre-8.32 --with-http_realip_module --with-cpu-opt=amd64
    make
    make install

    # CPU core number
    cpu_core_number=`more /proc/cpuinfo | grep "model name" | wc -l`
    
    # Free Memory
    memory_free=`free -m | grep Mem | awk '{print $4}'`
    #worker_processes
    
    #vi /usr/local/nginx/conf/nginx.conf
   
    sed -i 's/^#user.*nobody;$/user  www  www;/' /usr/local/nginx/conf/nginx.conf
    sed -i "s/^worker_processes.*1;\$/worker_processes  $cpu_core_number;/" /usr/local/nginx/conf/nginx.conf
    sed -i 's/^#pid/pid/' /usr/local/nginx/conf/nginx.conf
    sed -i 's*^#error_log  logs/error.log  notice;*error_log  logs/error.log  notice;*' /usr/local/nginx/conf/nginx.conf

    yum -y install bc
    
    worker_cpu_affinity='worker_cpu_affinity'

    for ((loop=0;loop<cpu_core_number;loop++))
    do
        cpumask_unformatted=`echo "obase=2;$[ 2 ** $loop ]" | bc`
        cpumask=`printf " %0${cpu_core_number}d" $cpumask_unformatted`
        worker_cpu_affinity=${worker_cpu_affinity}${cpumask}
    done
    worker_cpu_affinity=${worker_cpu_affinity}';'
    
    sed -i "/^worker_processes/a\\$worker_cpu_affinity" /usr/local/nginx/conf/nginx.conf
    
    sed -i "/^events/a\    use epoll;" /usr/local/nginx/conf/nginx.conf

    sed -i '/http {/,$d' /usr/local/nginx/conf/nginx.conf
    cat >> /usr/local/nginx/conf/nginx.conf <<'EOF'
http {

    #server_tokens off;
    include       mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  logs/access.log  main;

    sendfile        on;

    keepalive_timeout  65;

    gzip on;
    gzip_min_length  1k;
    gzip_buffers     4 16k;
    gzip_http_version 1.0;
    gzip_comp_level 2;
    gzip_types       text/plain application/x-javascript text/css application/xml;
    gzip_vary on;

    server {
        server_name licunchang.com;
        rewrite ^(.*) http://www.licunchang.com$1 permanent;
    }

    include /usr/local/nginx/conf/servers/*.conf;

}
EOF

    mkdir -p /usr/local/nginx/conf/servers/
    
    cat > /usr/local/nginx/conf/servers/www.licunchang.com.conf <<'EOF'
    server {
        listen       80;
        server_name  www.licunchang.com;
        
        root   /data/web/www.licunchang.com;
        
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
EOF

    cat > /usr/local/nginx/conf/servers/mysql.licunchang.com.conf <<'EOF'
    server {
        listen       80;
        server_name  mysql.licunchang.com;
        
        root   /data/web/mysql.licunchang.com;
        
        #charset utf-8;

        access_log  /usr/local/nginx/logs/mysql.licunchang.com.access.log  main;

        location / {
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
EOF
    #ip=`/sbin/ifconfig eth0 | awk '/inet addr/ {print $2}' | awk -F: '{print $2}'`
    #mask=`/sbin/ifconfig eth0 | awk '/inet addr/ {print $4}' | awk -F: '{print $2}'`
    
    mkdir -p /data/web/www.licunchang.com
    mkdir -p /data/web/mysql.licunchang.com

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

    cd /data/web/mysql.licunchang.com
    touch favicon.ico

    echo "404 Not Found" > 404.html

    echo "50x Server Error" > 50x.html
    echo "500 Internal Server Error" > 500.html
    echo "501 Not Implemented" > 501.html
    echo "502 Bad Gateway" > 502.html
    echo "503 Service Unavailable" > 503.html
    echo "504 Gateway Timeout" > 504.html
    echo "505 HTTP Version Not Supported" > 505.html
    
    chown www.www /data/web/mysql.licunchang.com  -R
    chmod 744 /data/web/mysql.licunchang.com  -R

    cat > /data/scripts/nginx <<'EOF'
#!/bin/sh
#
# nginx - this script starts and stops the nginx daemon
#
# chkconfig:   - 85 15 
# description:  Nginx is an HTTP(S) server, HTTP(S) reverse \
#               proxy and IMAP/POP3 proxy server
# processname: nginx
# config:      /usr/local/nginx/conf/nginx.conf
# config:      /etc/sysconfig/nginx
# pidfile:     /usr/local/nginx/logs/nginx.pid

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0

nginx="/usr/local/nginx/sbin/nginx"
prog=$(basename $nginx)

NGINX_CONF_FILE="/usr/local/nginx/conf/nginx.conf"

[ -f /etc/sysconfig/nginx ] && . /etc/sysconfig/nginx

lockfile=/var/lock/subsys/nginx

make_dirs() {
   # make required directories
   user=`$nginx -V 2>&1 | grep "configure arguments:" | sed 's/[^*]*--user=\([^ ]*\).*/\1/g' -`
   if [ -z "`grep $user /etc/passwd`" ]; then
       useradd -M -s /bin/nologin $user
   fi
   options=`$nginx -V 2>&1 | grep 'configure arguments:'`
   for opt in $options; do
       if [ `echo $opt | grep '.*-temp-path'` ]; then
           value=`echo $opt | cut -d "=" -f 2`
           if [ ! -d "$value" ]; then
               # echo "creating" $value
               mkdir -p $value && chown -R $user $value
           fi
       fi
   done
}

start() {
    [ -x $nginx ] || exit 5
    [ -f $NGINX_CONF_FILE ] || exit 6
    make_dirs
    echo -n $"Starting $prog: "
    daemon $nginx -c $NGINX_CONF_FILE
    retval=$?
    echo
    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}

stop() {
    echo -n $"Stopping $prog: "
    killproc $prog -QUIT
    retval=$?
    echo
    [ $retval -eq 0 ] && rm -f $lockfile
    return $retval
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
    killproc $nginx -HUP
    RETVAL=$?
    echo
}

force_reload() {
    restart
}

configtest() {
  $nginx -t -c $NGINX_CONF_FILE
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
    force-reload)
        force_reload
        ;;
    status)
        rh_status
        ;;
    condrestart|try-restart)
        rh_status_q || exit 0
            ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload|configtest}"
        exit 2
esac
EOF

    chmod 755 /data/scripts/nginx
    /data/scripts/nginx start
    
    sed -i '/^-A INPUT -i lo -j ACCEPT$/a\
-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT' /etc/sysconfig/iptables
    
    service iptables restart
    
    # max_clients = worker_processes * worker_connections
    
    # Worker Connections
    # Personally I stick with 1024 worker connections, because I don¡¯t have any reason to raise this value. But if example 4096 connections per second is not enough then it¡¯s possible to try to double this and set 2048 connections per process.
    # worker_processes final setup could be following:
    # worker_connections 1024;
    
    # If you want to allow users upload something or upload personally something over the HTTP then you should maybe increase post size. It can be done with client_max_body_size value which goes under http/server/location section. On default it¡¯s 1 Mb, but it can be set example to 20 Mb and also increase buffer size with following configuration:
    # client_max_body_size 20m;
    # client_body_buffer_size 128k;
    
    # location ~* \.(jpg|jpeg|gif|png|css|js|ico|xml)$ {
        # access_log        off;
        # log_not_found     off;
        # expires           360d;
    # }
    # Pass PHP scripts to PHP-FPM
    # location ~* \.php$ {
        # fastcgi_index   index.php;
        # fastcgi_pass    127.0.0.1:9000;
        # # fastcgi_pass   unix:/var/run/php-fpm/php-fpm.sock;
        # include         fastcgi_params;
        # fastcgi_param   SCRIPT_FILENAME    $document_root$fastcgi_script_name;
        # fastcgi_param   SCRIPT_NAME        $fastcgi_script_name;
    # }
    # It¡¯s very common that server root or other public directories have hidden files, which starts with dot (.) and normally those is not intended to site users. Public directories can contain version control files and directories, like .svn, some IDE properties files and .htaccess files. Following deny access and turn off logging for all hidden files.
    # location ~ /\. {
        # access_log off;
        # log_not_found off; 
        # deny all;
    # }
    
    return #?
}

#MySQL
if [ -d "/usr/local/src/mysql-5.5.30" ]; then
    mysql
fi

#php
if [ -d "/usr/local/src/php-5.4.12" ]; then
    php
fi

#nginx
if [ -d "/usr/local/src/nginx-1.2.7" ]; then
    nginx
fi

# http://www.if-not-true-then-false.com/2011/nginx-and-php-fpm-configuration-and-optimizing-tips-and-tricks/