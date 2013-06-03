#!/bin/bash
#
# description    Install nginx1.4.1 & mysql5.5.31 & php5.4.15 on CentOS6.4
# author         LiCunchang(printf@live.com)
# version        2.0.20130602

################################################################################
# Put error messages to STDERR.
# Globals:
#   None
# Arguments:
#   String
# Returns:
#   None
################################################################################
logger::error() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
}

################################################################################
# Install mysql-5.5.31
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   Integer
################################################################################
mysql::install() {

    # yum install zlib zlib-devel ncurses ncurses-devel bison
    yum -y install zlib zlib-devel ncurses ncurses-devel bison

    # Create a mysql User and Group
    local mysql_group=$(cat /etc/group | grep '^mysql' | awk -F: '{print $1}')
    local mysql_user=$(cat /etc/passwd | grep '^mysql' | awk -F: '{print $1}')

    if [[ "${mysql_group}" != "mysql" ]]; then
        /usr/sbin/groupadd -r mysql
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't create a group for mysql"
            exit 1
        else
            mysql_group="mysql"
        fi
    fi

    if [[ "${mysql_user}" != "mysql" ]]; then
        /usr/sbin/useradd -g mysql -M -r -s /sbin/nologin mysql
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't create a user for mysql"
            exit 1
        else
            mysql_user="mysql"
        fi
    fi

    # Create the mysql data directory: /data/mysql
    mkdir -p /data/mysql
    chown -R mysql:mysql /data/mysql

    # Create the mysql conf directory: /etc/mysql
    mkdir -p /etc/mysql
    chown -R mysql:mysql /etc/mysql

    if [[ -d "/usr/local/src/mysql-5.5.31" ]]; then
        cd /usr/local/src/mysql-5.5.31
        cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
                -DMYSQL_DATADIR=/data/mysql \
                -DSYSCONFDIR=/etc/mysql \
                -DDEFAULT_CHARSET=utf8 \
                -DDEFAULT_COLLATION=utf8_general_ci \
                -DWITH_EXTRA_CHARSETS=all \
                -DWITH_INNOBASE_STORAGE_ENGINE=1 \
                -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
                -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
                -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 \
                -DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 \
                -DWITHOUT_FEDERATED_STORAGE_ENGINE=1 \
                -DWITHOUT_PARTITION_STORAGE_ENGINE=1 \
                -DWITH_READLINE=1 -DWITH_LIBWRAP=1 \
                -DENABLED_LOCAL_INFILE=1 \
                -DENABLED_PROFILING=1 \
                -DMYSQL_TCP_PORT=3306 \
                -DWITH_ZLIB=system
        make
        make install
    else
        logger::error "/usr/local/src/mysql-5.5.31 was not fonnd"
        exit 1
    fi

    # Create the config file
    rm -f /etc/my.cnf
    
    # Free Memory
    local memory_free="$(free -m | grep Mem | awk '{print $4}')"
    
    if [[ "${memory_free}" -le 128 ]]; then
        cp -f /usr/local/src/mysql-5.5.31/support-files/my-medium.cnf \
              /etc/mysql/my.cnf
    fi
    
    if [[ "${memory_free}" -le 512 && "${memory_free}" -gt 128 ]]; then
        cp -f /usr/local/src/mysql-5.5.31/support-files/my-large.cnf \
              /etc/mysql/my.cnf
    fi
    
    if [[ "${memory_free}" -le 4096 && "${memory_free}" -gt 512 ]]; then
        cp -f /usr/local/src/mysql-5.5.17/support-files/my-huge.cnf \
              /etc/mysql/my.cnf
    fi
    
    if [[ "${memory_free}" -gt 4096 ]]; then
        cp -f /usr/local/src/mysql-5.5.31/support-files/my-innodb-heavy-4G.cnf \
              /etc/mysql/my.cnf
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
performance_schema\
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
    
    /usr/local/mysql/scripts/mysql_install_db --user="${mysql_user}" \
                                              --basedir=/usr/local/mysql \
                                              --datadir=/data/mysql
    
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
    
    mkdir -p /data/init.d/
    cp -f /usr/local/mysql/support-files/mysql.server /data/init.d/mysql
    sed -i 's#^basedir=$#basedir=/usr/local/mysql#' /data/init.d/mysql
    sed -i 's#^datadir=$#datadir=/data/mysql#' /data/init.d/mysql
    chmod 755 /data/init.d/mysql

    /data/init.d/mysql start
    
    # TODO
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
    
    return "$?"
}

################################################################################
# Install php-5.4.15
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   Integer
################################################################################
php::install() {

    yum -y install libxml2 libjpeg freetype libpng gd curl fontconfig \
        libxml2-devel curl-devel libjpeg-devel libpng-devel freetype-devel

    cd /usr/local/src/re2c-0.13.5
    ./configure
    make
    make install

    cd /usr/local/src/libiconv-1.14
    ./configure --prefix=/usr/local/libiconv
    make
    libtool --finish /usr/local/libiconv/lib
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

    # Create a PHP User and Group
    local php_group=$(cat /etc/group | grep '^www' | awk -F: '{print $1}')
    local php_user=$(cat /etc/passwd | grep '^www' | awk -F: '{print $1}')

    if [[ "${php_group}" != "www" ]]; then
        /usr/sbin/groupadd -r www
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't create a group for php-fpm"
            exit 1
        else
            php_group="www"
        fi
    fi

    if [[ "${php_user}" != "www" ]]; then
        /usr/sbin/useradd -g www -M -r -s /sbin/nologin www
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't create a user for php-fpm"
            exit 1
        else
            php_user="www"
        fi
    fi

    cd /usr/local/src/php-5.4.15
    ./configure --prefix=/usr/local/php \
                --with-config-file-path=/usr/local/php/etc \
                --enable-bcmath \
                --enable-shmop \
                --enable-sysvsem \
                --enable-ftp \
                --with-curl \
                --with-curlwrappers \
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
                --with-fpm-user="${php_user}" \
                --with-fpm-group="${php_group}" \
                --with-zlib \
                --with-iconv-dir=/usr/local/libiconv/ \
                --with-pcre-dir=/usr/local/pcre \
                --with-libxml-dir \
                --with-mcrypt=/usr/local/libmcrypt/ \
                --with-mhash=/usr/local/mhash/ \
                --disable-ipv6
    make
    make install
    
    cp -f /usr/local/src/php-5.4.15/php.ini-production /usr/local/php/etc/php.ini
    rm -rf /etc/php.ini

    # vi /usr/local/php/etc/php.ini

    sed -i 's#^;date.timezone =#date.timezone = Asia/Shanghai#' /usr/local/php/etc/php.ini
    sed -i 's#^expose_php = On#expose_php = Off#' /usr/local/php/etc/php.ini
    sed -i 's#^session.name = PHPSESSID#session.name = JSESSIONID#' /usr/local/php/etc/php.ini
    sed -i 's#^;session.save_path#session.save_path#' /usr/local/php/etc/php.ini
  
    cp -f /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
    
    # vi /etc/php/php-fpm.conf
    # pid = run/php-fpm.pid
    # user = www
    # group = www
    
    sed -i 's/^;pid/pid/' /usr/local/php/etc/php-fpm.conf
    # sed -i 's/^listen = 127.0.0.1:9000/;listen = 127.0.0.1:9000/' /usr/local/php/etc/php-fpm.conf
    # sed -i '/^;listen = 127.0.0.1:9000/a\listen = /tmp/php-fpm.sock' /usr/local/php/etc/php-fpm.conf

    sed -i 's/^;listen.backlog/listen.backlog/' /usr/local/php/etc/php-fpm.conf
    sed -i 's/^;pm.max_requests = 500$/pm.max_requests = 5000/' /usr/local/php/etc/php-fpm.conf

    # CPU core number
    local cpu_core_number="$(more /proc/cpuinfo | grep "model name" | wc -l)"
    
    # Free Memory
    local memory_free="$(free -m | grep Mem | awk '{print $4}')"

    # max php-fpm processors
    local php_fpm_max_processor="$(expr ${memory_free} / 30)"

    # max php-fpm pm children
    local pm_max_children="$(expr ${cpu_core_number} \* 2)"

    if [[ "${php_fpm_max_processor}" -ge "${pm_max_children}" ]]; then
        sed -i 's/^pm = dynamic$/pm = static/' /usr/local/php/etc/php-fpm.conf
        sed -i "s/^pm.max_children = 5\$/pm.max_children = ${pm_max_children}/" /usr/local/php/etc/php-fpm.conf
        sed -i "s/^pm.start_servers = 2\$/pm.start_servers = ${pm_max_children}/" /usr/local/php/etc/php-fpm.conf
        sed -i 's/^pm.min_spare_servers = 1$/pm.min_spare_servers = 0/' /usr/local/php/etc/php-fpm.conf
        sed -i "s/^pm.max_spare_servers = 3\$/pm.max_spare_servers = ${pm_max_children}/" /usr/local/php/etc/php-fpm.conf
        sed -i 's/^;pm.max_requests = 500$/pm.max_requests = 5000/' /usr/local/php/etc/php-fpm.conf
    else
        #sed -i 's/^pm = dynamic$/pm = static/' /usr/local/php/etc/php-fpm.conf
        sed -i "s/^pm.max_children = 5\$/pm.max_children = ${pm_max_children}/" /usr/local/php/etc/php-fpm.conf
        sed -i "s/^pm.start_servers = 2\$/pm.start_servers = ${cpu_core_number}/" /usr/local/php/etc/php-fpm.conf
        sed -i 's/^pm.min_spare_servers = 1$/pm.min_spare_servers = 2/' /usr/local/php/etc/php-fpm.conf
        sed -i "s/^pm.max_spare_servers = 3\$/pm.max_spare_servers = ${cpu_core_number}/" /usr/local/php/etc/php-fpm.conf
        sed -i 's/^;pm.max_requests = 500$/pm.max_requests = 5000/' /usr/local/php/etc/php-fpm.conf
    fi

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

    cp -f /usr/local/src/php-5.4.15/sapi/fpm/init.d.php-fpm /data/init.d/php-fpm
    
    chmod 755 /data/init.d/php-fpm

    /data/init.d/php-fpm start
    
    return "$?"
}

################################################################################
# Install nginx-1.4.1
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   Integer
################################################################################
nginx::install() {

    # Create a Nginx User and Group
    local nginx_group=$(cat /etc/group | grep '^www' | awk -F: '{print $1}')
    local nginx_user=$(cat /etc/passwd | grep '^www' | awk -F: '{print $1}')

    if [[ "${nginx_group}" != "www" ]]; then
        /usr/sbin/groupadd -r www
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't create a group for nginx"
            exit 1
        else
            nginx_group="www"
        fi
    fi

    if [[ "${nginx_user}" != "www" ]]; then
        /usr/sbin/useradd -g www -M -r -s /sbin/nologin www
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't create a user for nginx"
            exit 1
        else
            nginx_user="www"
        fi
    fi
    
    cd /usr/local/src/pcre-8.32
    ./configure --prefix=/usr/local/pcre \
                --enable-utf \
                --enable-pcre16 \
                --enable-pcre32 \
                --enable-jit \
                --enable-unicode-properties
    make
    make install
    
    cd /usr/local/src/nginx-1.4.1
    
    sed -i 's/nginx\b/Microsoft-IIS/g' ./src/core/nginx.h
    sed -i 's/1.4.1/7.5/' ./src/core/nginx.h
    sed -i 's/Server: nginx/Server: Microsoft-IIS/' ./src/http/ngx_http_header_filter_module.c
    sed -i 's/>nginx</>Microsoft-IIS</' ./src/http/ngx_http_special_response.c
    
    ./configure --with-http_stub_status_module \
                --with-http_gzip_static_module \
                --with-http_ssl_module \
                --with-openssl=/usr/local/src/openssl-1.0.1e \
                --user="${nginx_user}" \
                --group="${nginx_group}" \
                --prefix=/usr/local/nginx \
                --with-pcre=/usr/local/src/pcre-8.32 \
                --with-http_realip_module \
                --with-cpu-opt=amd64
    make
    make install

    # CPU core number
    local cpu_core_number="$(more /proc/cpuinfo | grep "model name" | wc -l)"
    
    # Free Memory
    local memory_free="$(free -m | grep Mem | awk '{print $4}')"

    #vi /usr/local/nginx/conf/nginx.conf
    sed -i "s/^#user.*nobody;\$/user  ${nginx_user}  ${nginx_group};/" /usr/local/nginx/conf/nginx.conf
    sed -i "s/^worker_processes.*1;\$/worker_processes  ${cpu_core_number};/" /usr/local/nginx/conf/nginx.conf
    sed -i 's/^#pid/pid/' /usr/local/nginx/conf/nginx.conf
    sed -i 's*^#error_log  logs/error.log  notice;*error_log  logs/error.log  notice;*' /usr/local/nginx/conf/nginx.conf

    yum -y install bc
    
    local worker_cpu_affinity='worker_cpu_affinity'
    for ((loop=0;loop<cpu_core_number;loop++)); do
        cpumask_unformatted=$(echo "obase=2;$[ 2 ** ${loop} ]" | bc)
        cpumask=$(printf " %0${cpu_core_number}d" ${cpumask_unformatted})
        worker_cpu_affinity=${worker_cpu_affinity}${cpumask}
    done
    worker_cpu_affinity=${worker_cpu_affinity}';'

    sed -i "/^worker_processes/a\\${worker_cpu_affinity}" /usr/local/nginx/conf/nginx.conf
    sed -i "s/^.*worker_connections  1024;$/    worker_connections 8192;/" /usr/local/nginx/conf/nginx.conf

    local worker_rlimit_nofile=$((8192*${cpu_core_number}));
    sed -i "/^worker_cpu_affinity/a\worker_rlimit_nofile ${worker_rlimit_nofile};" /usr/local/nginx/conf/nginx.conf
    sed -i "/^events/a\    use epoll;" /usr/local/nginx/conf/nginx.conf

    ulimit -SHn ${worker_rlimit_nofile}

    sed -i "s/^;rlimit_files.*1024$/rlimit_files = ${worker_rlimit_nofile}/" /usr/local/php/etc/php-fpm.conf
    
    sed -i '/http {/,$d' /usr/local/nginx/conf/nginx.conf
    cat >> /usr/local/nginx/conf/nginx.conf <<'EOF'
http {

    server_tokens on;
    include       mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  logs/access.log  main;

    sendfile  on;
    tcp_nopush  on;

    keepalive_timeout  10;
    send_timeout  10;

    client_body_buffer_size  8k;
    client_max_body_size 8m;
    client_body_timeout 10;

    client_header_buffer_size 8k;
    large_client_header_buffers 4 8k;
    client_header_timeout 10;

    # gzip configuration
    gzip on;
    gzip_min_length  1k;
    gzip_buffers     4 16k;
    gzip_http_version 1.0;
    gzip_comp_level 2;
    gzip_types       text/plain application/x-javascript text/css application/xml;
    gzip_vary on;

    server {
        server_name licunchang.com;
        
        # if the client didn't give a user_agent, return 412
        if ($http_user_agent ~ ^$) {
            return 412;
        }

        rewrite ^(.*) http://www.licunchang.com$1 permanent;
    }

    include /usr/local/nginx/conf/servers/*.conf;

}
EOF

    mkdir -p /usr/local/nginx/conf/servers/
    
    cat > /usr/local/nginx/conf/servers/www.licunchang.com.conf <<'EOF'
server {
    listen  80  default_server; 
    server_name  www.licunchang.com;
    
    root   /data/web/www.licunchang.com;
    
    #charset utf-8;

    access_log  /usr/local/nginx/logs/www.licunchang.com.access.log  main;

    location / {
        index  index.php index.html;
    }

    error_page  404  /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    location ~ \.php {
        fastcgi_split_path_info ^(.+\.php)(.*)$;
        # NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini (why:http://www.laruence.com/2009/11/13/1138.html)

        if (!-f $document_root$fastcgi_script_name) {
                return 404;
        }
        fastcgi_pass   127.0.0.1:9000;
        # fastcgi_pass   unix:/tmp/php-fpm.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param  PATH_INFO       $fastcgi_path_info;
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

    error_page  404  /404.html;

    # redirect server error pages to the static page /50x.html
    #
    error_page   500 502 503 504  /50x.html;

    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
    location ~ \.php {
        fastcgi_split_path_info ^(.+\.php)(.*)$;
        # NOTE: You should have "cgi.fix_pathinfo = 0;" in php.ini (why:http://www.laruence.com/2009/11/13/1138.html)

        if (!-f $document_root$fastcgi_script_name) {
            return 404;
        }
        fastcgi_pass   127.0.0.1:9000;
        # fastcgi_pass   unix:/tmp/php-fpm.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param  PATH_INFO       $fastcgi_path_info;
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

cat > /usr/local/nginx/conf/servers/status.licunchang.com.conf <<'EOF'
server {
    listen  80;
    server_name  status.licunchang.com;

    location / {
        # allow 10.10.10.0/24;
        # deny all;
        stub_status on;
        access_log  off;
        error_log off;
    }
}
EOF

    sed -i 's#nginx/#Microsoft-IIS/#' /usr/local/nginx/conf/fastcgi_params

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

    cat > /data/init.d/nginx <<'EOF'
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
EOF

    chmod 755 /data/init.d/nginx
    /data/init.d/nginx start
    
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
    
    mkdir -p /data/logs/nginx/
    mkdir -p /data/cron/
    cat > /data/cron/nginx_logs_cut.sh <<'EOF'
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
    return ${readonly}
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
EOF
    
    echo "00 00 * * * /bin/bash /data/cron/nginx_logs_cut.sh" >> /var/spool/cron/root

    return $?
}

################################################################################
# Install xdebug-2.2.3
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
################################################################################
xdebug::install() {

    cd /usr/local/src/
    tar -xzf xdebug-2.2.2.tgz
    cd /usr/local/src/xdebug-2.2.2/
    /usr/local/php/bin/phpize
    ./configure --enable-xdebug --with-php-config=/usr/local/php/bin/php-config
    make
    make install
    
    mkdir -p /usr/local/php/ext/
    mv /usr/local/php/lib/php/extensions/no-debug-non-zts-20100525/xdebug.so /usr/local/php/ext/

    sed -i '/^; extension_dir = "\.\/"$/a\
extension_dir = /usr/local/php/ext/' /usr/local/php/etc/php.ini

    sed -i '/^; Local Variables:$/i\
[xdebug]\
zend_extension="/usr/local/php/ext/xdebug.so"\
xdebug.default_enable=1\
xdebug.auto_profile=1\
' /usr/local/php/etc/php.ini

    /data/init.d/php-fpm restart

    return $?
}

################################################################################
# Install xtrabackup-2.1.3
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
################################################################################
xtrabackup::install() {

    yum -y install cmake gcc gcc-c++ patch libaio libaio-devel automake \
        autoconf bzr bison libtool ncurses-devel zlib-devel perl-Time-HiRes

    cd /usr/local/src/

    if [[ ! -f "/usr/local/src/mysql-5.5.17.tar.gz" ]]; then
        echo "error:miss mysql-5.5.17.tar.gz"
        exit 1
    fi

    cp /usr/local/src/mysql-5.5.17.tar.gz /usr/local/src/percona-xtrabackup-2.0.6
    cd /usr/local/src/percona-xtrabackup-2.0.6
    ./utils/build.sh innodb55

    mkdir -p /usr/local/xtrabackup

    cp ./innobackupex /usr/local/xtrabackup/
    cp ./src/xtrabackup_innodb55 /usr/local/xtrabackup/
    ln -s /usr/local/xtrabackup/xtrabackup_innodb55 /usr/local/xtrabackup/xtrabackup_55
    cp ./src/xbstream /usr/local/xtrabackup/

    /usr/local/mysql/bin/mysql -uroot -proot -P3306 <<'EOF'
CREATE USER 'xtrabackup'@'localhost' IDENTIFIED BY 'xtrabackup';
GRANT RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'xtrabackup'@'localhost';
FLUSH PRIVILEGES;
EOF

    mkdir -p /data/cron/
    cat > /data/cron/mysql_xtrabackup.sh <<'EOF'
#!/bin/bash
#description    backup mysql data files, run at 0:00 everyday
#crontab        00 00 * * * /bin/bash /data/cron/nginx_logs_cut.sh
#author         LiCunchang(printf@live.com)

EOF
    return $?
}



################################################################################
# Put error messages to STDERR.
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
################################################################################
main(){

    clear

    echo "┌───────────────────────────────────────────────────────────────────┐"
    echo "│        #####      #####       ##   #####      ###     ########    │"
    echo "│       ##  ##     ## ###      ##   ## ####    ####    ##  ##   #   │"
    echo "│      ###  ##    ##  ####    ##   ##  ####    ###    ##  ###   #   │"
    echo "│      ##         ##  ####    ##   ##  ####   ####   ###  ###   #   │"
    echo "│      ##        ##   #####  ###  ##   ####  #####   ##   ###  ##   │"
    echo "│     ###             ## ### ##        ##### #####        ### ##    │"
    echo "│     ###            ### ### ##       ######## ###       ######     │"
    echo "│     ###            ##   #####       ## ####  ##        ###        │"
    echo "│     ##             ##   #####       ##  ###  ##        ###        │"
    echo "│    ###            ##     ####      ##   ##  ###        ##         │"
    echo "│    ##     ## ###  ##      ##  ###  ##       ###       ##          │"
    echo "│  ##########   #####       ##   #####        #####   ######        │"
    echo "└───────────────────────────────────────────────────────────────────┘"
    echo ""

    # 01 nginx-1.4.1.tar.gz
    # 02 openssl-1.0.1e.tar.gz
    # 03 pcre-8.32.tar.gz
    # 04 mysql-5.5.31.tar.gz
    # 05 php-5.4.15.tar.gz
    # 06 libiconv-1.14.tar.gz
    # 07 mcrypt-2.6.8.tar.gz
    # 08 mhash-0.9.9.9.tar.gz
    # 09 libmcrypt-2.5.8.tar.gz
    # 10 re2c-0.13.5.tar.gz
    # 11 xdebug-2.2.3.tgz
    # 12 percona-xtrabackup-2.1.3.tar.gz
    # 13 * mysql-5.5.17.tar.gz(for xtrabackup)

    PACKAGES[0]="nginx-1.4.1.tar.gz"
    PACKAGES[1]="openssl-1.0.1e.tar.gz"
    PACKAGES[2]="pcre-8.32.tar.gz"
    PACKAGES[3]="mysql-5.5.31.tar.gz"
    PACKAGES[4]="php-5.4.15.tar.gz"
    PACKAGES[5]="libiconv-1.14.tar.gz"
    PACKAGES[6]="mcrypt-2.6.8.tar.gz"
    PACKAGES[7]="mhash-0.9.9.9.tar.gz"
    PACKAGES[8]="libmcrypt-2.5.8.tar.gz"
    PACKAGES[9]="re2c-0.13.5.tar.gz"

    readonly PACKAGES

    # cd /usr/local/src
    # # unzip the packages
    # ls | grep -i '.tar.gz$' > tar.list
    # if [[ `cat tar.list | wc -l` -ne 0 ]]; then
    #     for TAR in `cat tar.list`
    #     do
    #         echo "unzip the package: $TAR"
    #         tar zxf $TAR
    #     done
    # fi
    # rm -f tar.list

    cd /usr/local/src
    for package in ${PACKAGES[@]}; do
        if [[ -f "${package}" ]]; then
            tar zxf "${package}"
        else
            logger::error "/usr/local/src/${package} was not found."
            exit 1
        fi
    done

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
    #       |-/init.d

    # Source networking configuration.
    . /etc/sysconfig/network

    # Check that networking is up.
    if [[ "${NETWORKING}" == "no" ]]; then
        logger::error "network is not available."
        exit 1
    fi

    readonly CDROM_MOUNT_DIR="/mnt/cdrom"
    if [[ ! -d "${CDROM_MOUNT_DIR}" ]]; then
        mkdir "${CDROM_MOUNT_DIR}"
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't create a directory as a mount point"
        fi
    fi

    if [[ -z "$(ls -A "${CDROM_MOUNT_DIR}")" ]]; then
        mount /dev/cdrom "${CDROM_MOUNT_DIR}"
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't create a directory as a mount point"
            exit 1
        fi
    fi

    cd /etc/yum.repos.d

    for repo in $(ls | grep -i '.repo$'); do
        if [[ -n "${repo}" ]]; then
            mv "${repo}" "${repo}_licunchang.bak"
        fi
    done

    touch CentOS-Dvd.repo

    cat > CentOS-Dvd.repo <<'EOF'
[c6-dvd]
name=CentOS-$releasever - Dvd
baseurl=file:///mnt/cdrom/
gpgcheck=0
enabled=1
EOF

    yum makecache

    yum -y install make cmake gcc gcc-c++ chkconfig automake autoconf libtool

    #MySQL
    if [ -d "/usr/local/src/mysql-5.5.31" ]; then
        mysql::install
    fi

    #php
    if [ -d "/usr/local/src/php-5.4.15" ]; then
        php::install
    fi

    #nginx
    if [ -d "/usr/local/src/nginx-1.4.1" ]; then
        nginx::install
    fi

    #xdebug
    if [ -f "/usr/local/src/xdebug-2.2.3.tgz" ]; then
        xdebug::install
    fi

    #xtrabackup
    if [ -d "/usr/local/src/percona-xtrabackup-2.1.3" ]; then
        xtrabackup::install
    fi

}

main "$@"