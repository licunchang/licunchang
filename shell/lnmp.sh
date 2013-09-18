#!/bin/bash
#
# description    Install nginx1.4.2 & mysql5.5.33 & php5.5.3 on CentOS6.4
# author         LiCunchang(printf@live.com)
# version        2.0.20130810

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
    # `date --iso-8601=ns`
    printf "%s\n" "[error:$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
    exit 1
}

################################################################################
# exit when interrupt
# Globals:
#   None
# Arguments:
#   Integer
# Returns:
#   None
################################################################################
trap::interrupt() {
    echo ""
    echo "Aborting at [LINE:$1]!"
    echo ""
    exit 1
}

################################################################################
# Install mysql-5.5.33
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   Integer
################################################################################
mysql::install() {

    echo "install zlib zlib-devel ncurses ncurses-devel bison"
    yum -y install zlib zlib-devel ncurses ncurses-devel bison

    # Create a mysql User and Group
    local mysql_group
    local mysql_user
    mysql_group=$(grep '^mysql' /etc/group | awk -F: '{print $1}')
    mysql_user=$(grep '^mysql' /etc/passwd | awk -F: '{print $1}')

    if [[ "${mysql_group}" != "mysql" ]]; then
        echo "create group:mysql"
        /usr/sbin/groupadd -r mysql
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't create a group for mysql"
            exit 1
        else
            mysql_group="mysql"
        fi
    fi

    if [[ "${mysql_user}" != "mysql" ]]; then
        echo "create user:mysql"
        /usr/sbin/useradd -g mysql -M -r -s /bin/false mysql
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't create a user for mysql"
            exit 1
        else
            mysql_user="mysql"
        fi
    fi

    # Create the mysql data directory: /data/mysql
    echo "create mysql data directory"
    mkdir -p /data/mysql
    chown -R mysql:mysql /data/mysql

    # Create the mysql conf directory: /etc/mysql
    echo "create mysql conf directory"
    mkdir -p /etc/mysql
    chown -R mysql:mysql /etc/mysql

    if [[ -d "/usr/local/src/mysql-5.5.33" ]]; then
        echo "install mysql from source"
        cd /usr/local/src/mysql-5.5.33 || { echo "Can't read /usr/local/src/mysql-5.5.33."; exit 1; }
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
                -DWITH_ZLIB=bundled
        make
        make install
    else
        logger::error "/usr/local/src/mysql-5.5.33 was not fonnd"
        exit 1
    fi

    echo "create the config file"
    # Create the config file
    rm -f /etc/my.cnf
    
    # Free Memory
    local memory_free="$(free -m | grep Mem | awk '{print $4}')"
    
    if [[ "${memory_free}" -le 128 ]]; then
        cp -f /usr/local/src/mysql-5.5.33/support-files/my-medium.cnf \
              /etc/mysql/my.cnf
    fi
    
    if [[ "${memory_free}" -le 512 && "${memory_free}" -gt 128 ]]; then
        cp -f /usr/local/src/mysql-5.5.33/support-files/my-large.cnf \
              /etc/mysql/my.cnf
    fi
    
    if [[ "${memory_free}" -le 4096 && "${memory_free}" -gt 512 ]]; then
        cp -f /usr/local/src/mysql-5.5.33/support-files/my-huge.cnf \
              /etc/mysql/my.cnf
    fi
    
    if [[ "${memory_free}" -gt 4096 ]]; then
        cp -f /usr/local/src/mysql-5.5.33/support-files/my-innodb-heavy-4G.cnf \
              /etc/mysql/my.cnf
    fi
    
    echo "optimize mysql"

    sed -i '/^\[client\]/a\default-character-set=utf8' /etc/mysql/my.cnf
        
    sed -i '/^\[mysqld\]/a\
datadir = /data/mysql\
character_set_server=utf8\
collation-server=utf8_general_ci\
skip-character-set-client-handshake\
performance_schema\
general-log\
log-warnings\
performance_schema\
long_query_time=2\
slow-query-log\
log-queries-not-using-indexes\
innodb_file_per_table\
expire_logs_days=7' /etc/mysql/my.cnf
    
    sed -i 's/^#innodb_data_home_dir/innodb_data_home_dir/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_data_file_path/innodb_data_file_path/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_log_group_home_dir/innodb_log_group_home_dir/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_buffer_pool_size/innodb_buffer_pool_size/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_additional_mem_pool_size/innodb_additional_mem_pool_size/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_log_file_size/innodb_log_file_size/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_log_buffer_size/innodb_log_buffer_size/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_flush_log_at_trx_commit/innodb_flush_log_at_trx_commit/' /etc/mysql/my.cnf
    sed -i 's/^#innodb_lock_wait_timeout/innodb_lock_wait_timeout/' /etc/mysql/my.cnf
    
    echo "install mysql db"
    /usr/local/mysql/scripts/mysql_install_db --user="${mysql_user}" \
                                              --basedir=/usr/local/mysql \
                                              --datadir=/data/mysql
      
    echo "create mysql init script"
    mkdir -p /data/init.d/
    cp -f /usr/local/mysql/support-files/mysql.server /data/init.d/mysql
    sed -i 's#^basedir=$#basedir=/usr/local/mysql#' /data/init.d/mysql
    sed -i 's#^datadir=$#datadir=/data/mysql#' /data/init.d/mysql
    chmod 755 /data/init.d/mysql

    echo "start mysql"
    /data/init.d/mysql start
    
    echo "mysql secure"

    cd /usr/local/mysql/ || { logger::error "Can't read /usr/local/mysql."; exit 1; }
    /usr/local/mysql/bin/mysql_secure_installation <<'EOF'

y
root
root
y
y
y
y
EOF
    
    echo "iptables [port:3306]"
    #vi /etc/sysconfig/iptables
    sed -i '/^-A INPUT -i lo -j ACCEPT$/a\
-A INPUT -m state --state NEW -m tcp -p tcp --dport 3306 -j ACCEPT' /etc/sysconfig/iptables
    
    service iptables restart
    
    echo "[done]mysql::install"
    return "$?"
}

################################################################################
# Install php-5.5.3
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   Integer
################################################################################
php::install() {

    echo "install libxml2 libjpeg freetype libpng gd curl fontconfig \
        libxml2-devel curl-devel libjpeg-devel libpng-devel freetype-devel"
    yum -y install libxml2 libjpeg freetype libpng gd curl fontconfig \
        libxml2-devel curl-devel libjpeg-devel libpng-devel freetype-devel

    echo "re2c install"
    cd /usr/local/src/re2c-0.13.6 || { logger::error "Can't read /usr/local/src/re2c-0.13.6."; exit 1; }
    ./configure
    make
    make install

    echo "libiconv install"
    cd /usr/local/src/libiconv-1.14 || { logger::error "Can't read /usr/local/src/libiconv-1.14."; exit 1; }
    ./configure --prefix=/usr/local/libiconv
    make
    libtool --finish /usr/local/libiconv/lib
    make install
    
    echo "libmcrypt install"
    cd /usr/local/src/libmcrypt-2.5.8 || { logger::error "Can't read /usr/local/src/libmcrypt-2.5.8."; exit 1; }
    ./configure --prefix=/usr/local/libmcrypt
    make
    make install

    echo "libmcrypt libltdl install"
    cd /usr/local/src/libmcrypt-2.5.8/libltdl || { logger::error "Can't read /usr/local/src/libmcrypt-2.5.8/libltdl."; exit 1; }
    ./configure --enable-ltdl-install
    make
    make install
    
    echo "mhash install"
    cd /usr/local/src/mhash-0.9.9.9 || { logger::error "Can't read /usr/local/src/mhash-0.9.9.9."; exit 1; }
    ./configure --prefix=/usr/local/mhash
    make
    make install
    
    echo "mcrypt install"
    cd /usr/local/src/mcrypt-2.6.8 || { logger::error "Can't read /usr/local/src/mcrypt-2.6.8."; exit 1; }
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/libmcrypt/lib:/usr/local/mhash/lib
    export LDFLAGS="-L/usr/local/mhash/lib/ -I/usr/local/mhash/include/"
    export CFLAGS="-I/usr/local/mhash/include/"
    ./configure --prefix=/usr/local/mcrypt --with-libmcrypt-prefix=/usr/local/libmcrypt
    make
    make install

    # Create a PHP User and Group
    local php_group
    local php_user
    php_group=$(grep '^www' /etc/group | awk -F: '{print $1}')
    php_user=$(grep '^www' /etc/passwd | awk -F: '{print $1}')

    if [[ "${php_group}" != "www" ]]; then
        echo "create group:www"
        /usr/sbin/groupadd -r www
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't create a group for php-fpm"
            exit 1
        else
            php_group="www"
        fi
    fi

    if [[ "${php_user}" != "www" ]]; then
        echo "create user:www"
        /usr/sbin/useradd -g www -M -r -s /bin/false www
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't create a user for php-fpm"
            exit 1
        else
            php_user="www"
        fi
    fi

    if [[ -d "/usr/local/src/php-5.5.3" ]]; then
        echo "install php from source"
        cd /usr/local/src/php-5.5.3 || { logger::error "Can't read /usr/local/src/php-5.5.3."; exit 1; }
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
                    --with-mysql=mysqlnd \
                    --with-mysqli=mysqlnd \
                    --with-pdo-mysql=mysqlnd \
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
    else
        logger::error "/usr/local/src/php-5.5.3 was not fonnd"
        exit 1
    fi
    
    echo "create /etc/php.ini"
    cp -f /usr/local/src/php-5.5.3/php.ini-production /usr/local/php/etc/php.ini
    rm -rf /etc/php.ini

    # vi /usr/local/php/etc/php.ini
    echo "optimize php"
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

    echo "create php init script"
    cp -f /usr/local/src/php-5.5.3/sapi/fpm/init.d.php-fpm /data/init.d/php-fpm
    
    chmod 755 /data/init.d/php-fpm
    
    echo "start php-fpm"
    /data/init.d/php-fpm start
    
    echo "[done]php::install"
    return "$?"
}

################################################################################
# Install nginx-1.4.2
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   Integer
################################################################################
nginx::install() {

    # Create a Nginx User and Group
    local nginx_group
    local nginx_user
    nginx_group=$(grep '^www' /etc/group | awk -F: '{print $1}')
    nginx_user=$(grep '^www' /etc/passwd | awk -F: '{print $1}')

    if [[ "${nginx_group}" != "www" ]]; then
        echo "create group:www"
        /usr/sbin/groupadd -r www
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't create a group for nginx"
            exit 1
        else
            nginx_group="www"
        fi
    fi

    if [[ "${nginx_user}" != "www" ]]; then
        echo "create user:www"
        /usr/sbin/useradd -g www -M -r -s /bin/false www
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't create a user for nginx"
            exit 1
        else
            nginx_user="www"
        fi
    fi
    
    if [[ -d "/usr/local/src/pcre-8.33" ]]; then
        echo "install pcre from source"
        cd /usr/local/src/pcre-8.33 || { logger::error "Can't read /usr/local/src/pcre-8.33."; exit 1; }
        ./configure --prefix=/usr/local/pcre \
                    --enable-utf \
                    --enable-pcre16 \
                    --enable-pcre32 \
                    --enable-jit \
                    --enable-unicode-properties
        make
        make install
    else
        logger::error "/usr/local/src/pcre-8.33 was not fonnd"
        exit 1
    fi
    
    if [[ -d "/usr/local/src/nginx-1.4.2" ]]; then
        echo "install nginx from source"
        cd /usr/local/src/nginx-1.4.2 || { logger::error "Can't read /usr/local/src/nginx-1.4.2."; exit 1; }
        
        sed -i 's/nginx\b/Microsoft-IIS/g' ./src/core/nginx.h
        sed -i 's/1.4.2/7.5/' ./src/core/nginx.h
        sed -i 's/Server: nginx/Server: Microsoft-IIS/' ./src/http/ngx_http_header_filter_module.c
        sed -i 's/>nginx</>Microsoft-IIS</' ./src/http/ngx_http_special_response.c
        
        ./configure --with-http_stub_status_module \
                    --with-http_gzip_static_module \
                    --with-http_ssl_module \
                    --with-openssl=/usr/local/src/openssl-1.0.1e \
                    --user="${nginx_user}" \
                    --group="${nginx_group}" \
                    --prefix=/usr/local/nginx \
                    --with-pcre=/usr/local/src/pcre-8.33 \
                    --with-http_realip_module \
                    --with-cpu-opt=amd64
        make
        make install
    else
        logger::error "/usr/local/src/nginx-1.4.2 was not fonnd"
        exit 1
    fi

    echo "optimize nginx config"

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

    echo "add server[www.licunchang.com] nginx config"
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
        
        add_header Cache-Control no-cache;
        add_header Cache-Control private;
    }

    location ~ /\. {
        access_log off;
        log_not_found off; 
        deny all;
    }
}
EOF

    echo "add server[mysql.licunchang.com] nginx config"
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
        
        add_header Cache-Control no-cache;
        add_header Cache-Control private;
    }

    location ~ /\. {
        access_log off;
        log_not_found off; 
        deny all;
    }
}
EOF

    echo "add server[status.licunchang.com] nginx config"
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

    cd /data/web/www.licunchang.com || { logger::error "Can't read /data/web/www.licunchang.com."; exit 1; }
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

    cd /data/web/mysql.licunchang.com || { logger::error "Can't read /data/web/mysql.licunchang.com."; exit 1; }
    touch favicon.ico

    echo "404 Not Found" > 404.html

    echo "50x Server Error" > 50x.html
    echo "500 Internal Server Error" > 500.html
    echo "501 Not Implemented" > 501.html
    echo "502 Bad Gateway" > 502.html
    echo "503 Service Unavailable" > 503.html
    echo "504 Gateway Timeout" > 504.html
    echo "505 HTTP Version Not Supported" > 505.html
    
    chown www:www /data/web/mysql.licunchang.com  -R
    chmod 744 /data/web/mysql.licunchang.com  -R

    echo "add nginx init script"
    cat > /data/init.d/nginx <<'EOF'
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
EOF

    echo "start nginx"
    chmod 755 /data/init.d/nginx
    /data/init.d/nginx start
    
    echo "iptables:80"
    sed -i '/^-A INPUT -i lo -j ACCEPT$/a\
-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT' /etc/sysconfig/iptables
    
    service iptables restart
     
    echo "crontab:nginx_logs_cut"
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

    cd /usr/local/src/ || { logger::error "Can't read /usr/local/src."; exit 1; }
    tar -xzf xdebug-2.2.3.tgz
    cd /usr/local/src/xdebug-2.2.3/ || { logger::error "Can't read /usr/local/src/xdebug-2.2.3/."; exit 1; }
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
# Install xtrabackup-2.1.4
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
################################################################################
xtrabackup::install() {

    cd /usr/local/src/ || { logger::error "Can't read /usr/local/src."; exit 1; }
    tar -xzf percona-xtrabackup-2.1.4.tar.gz
    cd /usr/local/src/percona-xtrabackup-2.1.4/ || { logger::error "Can't read /usr/local/src/percona-xtrabackup-2.1.4/."; exit 1; }

    yum -y install cmake gcc gcc-c++ patch libaio libaio-devel automake \
        autoconf bzr bison libtool ncurses-devel zlib-devel perl-Time-HiRes libgcrypt-devel

    ./utils/build.sh innodb55

    mkdir -p /usr/local/xtrabackup

    cp ./innobackupex /usr/local/xtrabackup/
    cp ./src/xtrabackup_innodb55 /usr/local/xtrabackup/
    ln -s /usr/local/xtrabackup/xtrabackup_innodb55 /usr/local/xtrabackup/xtrabackup_55
    cp ./src/xbstream /usr/local/xtrabackup/

    return $?
}

################################################################################
# The Main Function
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
################################################################################
main() {

    export PS4='+$LINENO:{${FUNCNAME[0]}} '
    trap 'trap::interrupt $LINENO' 1 2 3 6 15

    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│       #####      #####       ##   #####      ###     ########   │"
    echo "│      ##  ##     ## ###      ##   ## ####    ####    ##  ##   #  │"
    echo "│     ###  ##    ##  ####    ##   ##  ####    ###    ##  ###   #  │"
    echo "│     ##         ##  ####    ##   ##  ####   ####   ###  ###   #  │"
    echo "│     ##        ##   #####  ###  ##   ####  #####   ##   ###  ##  │"
    echo "│    ###             ## ### ##        ##### #####        ### ##   │"
    echo "│    ###            ### ### ##       ######## ###       ######    │"
    echo "│    ###            ##   #####       ## ####  ##        ###       │"
    echo "│    ##             ##   #####       ##  ###  ##        ###       │"
    echo "│   ###            ##     ####      ##   ##  ###        ##        │"
    echo "│   ##     ## ###  ##      ##  ###  ##       ###       ##         │"
    echo "│ ##########   #####       ##   #####        #####   ######       │"
    echo "└─────────────────────────────────────────────────────────────────┘"
    echo ""

    # 01 nginx-1.4.2.tar.gz
    # 02 openssl-1.0.1e.tar.gz
    # 03 pcre-8.33.tar.gz
    # 04 mysql-5.5.33.tar.gz
    # 05 php-5.5.3.tar.gz
    # 06 libiconv-1.14.tar.gz
    # 07 mcrypt-2.6.8.tar.gz
    # 08 mhash-0.9.9.9.tar.gz
    # 09 libmcrypt-2.5.8.tar.gz
    # 10 re2c-0.13.6.tar.gz
    # 11 xdebug-2.2.3.tgz
    # 12 percona-xtrabackup-2.1.4.tar.gz
    # 13 * mysql-5.5.17.tar.gz(for xtrabackup)

    PACKAGES[0]="nginx-1.4.2.tar.gz"
    PACKAGES[1]="openssl-1.0.1e.tar.gz"
    PACKAGES[2]="pcre-8.33.tar.gz"
    PACKAGES[3]="mysql-5.5.33.tar.gz"
    PACKAGES[4]="php-5.5.3.tar.gz"
    PACKAGES[5]="libiconv-1.14.tar.gz"
    PACKAGES[6]="mcrypt-2.6.8.tar.gz"
    PACKAGES[7]="mhash-0.9.9.9.tar.gz"
    PACKAGES[8]="libmcrypt-2.5.8.tar.gz"
    PACKAGES[9]="re2c-0.13.6.tar.gz"

    readonly PACKAGES

    cd /usr/local/src || { logger::error "Can't read /usr/local/src."; exit 1; }
    for package in ${PACKAGES[@]}; do
        if [[ -f "${package}" ]]; then
            echo "unzip ${package}"
            tar zxf "${package}" || { logger::error "tar:${package}"; exit 1; }
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
    else
        echo "network is working."
    fi

    readonly CDROM_MOUNT_DIR="/mnt/cdrom"
    if [[ ! -d "${CDROM_MOUNT_DIR}" ]]; then
        mkdir "${CDROM_MOUNT_DIR}"
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't create a directory as a mount point"
        fi
    fi

    if [[ -z "$(ls -A "${CDROM_MOUNT_DIR}")" ]]; then
        echo "mount cdrom."
        mount /dev/cdrom "${CDROM_MOUNT_DIR}"
        if [[ "$?" -ne 0 ]]; then
            logger::error "can't mount the cdrom"
            exit 1
        fi
    fi

    cd /etc/yum.repos.d || { logger::error "/etc/yum.repos.d"; exit 1; }
    echo "backup yum sources"
    for repo in ./*.repo; do
        if [[ -e "${repo}" ]]; then
            mv "${repo}" "${repo}_licunchang.bak"
        fi
    done

    echo "create dvd yum sources"
    touch CentOS-Dvd.repo

    cat > CentOS-Dvd.repo <<'EOF'
[c6-dvd]
name=CentOS-$releasever - Dvd
baseurl=file:///mnt/cdrom/
gpgcheck=0
enabled=1
EOF

    echo "install make cmake gcc gcc-c++ chkconfig automake autoconf libtool"
    yum -y install make cmake gcc gcc-c++ chkconfig automake autoconf libtool

    #MySQL
    if [[ -d "/usr/local/src/mysql-5.5.33" ]]; then
        echo "mysql::install"
        mysql::install
    fi

    #php
    if [[ -d "/usr/local/src/php-5.5.3" ]]; then
        echo "php::install"
        php::install
    fi

    #nginx
    if [[ -d "/usr/local/src/nginx-1.4.2" ]]; then
        echo "nginx::install"
        nginx::install
    fi

    #xdebug
    if [[ -f "/usr/local/src/xdebug-2.2.3.tgz" ]]; then
        echo "xdebug::install"
        xdebug::install
    fi

    #xtrabackup
    if [[ -f "/usr/local/src/percona-xtrabackup-2.1.4.tar.gz" ]]; then
        echo "xtrabackup::install"
        xtrabackup::install
    fi
}

main "$@"