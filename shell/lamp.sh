#!/bin/bash
# description    Install httpd2.2.24 & mysql5.5.30 & php5.4.12 on CentOS6.4
# author         LiCunchang

# 1 httpd-2.2.24.tar.gz
# 2 libmcrypt-2.5.8.tar.gz
# 3 pcre-8.32.tar.gz
# 4 mysql-5.5.30.tar.gz
# 5 php-5.4.12.tar.gz
# 6 libiconv-1.14.tar.gz
# 7 mcrypt-2.6.8.tar.gz
# 8 mhash-0.9.9.9.tar.gz

# source directory: /usr/local/src

#   /data
#       |-/web
#           |-/www.licunchang.com
#           |-/mysql.licunchang.com
#           |-......
#       |-/mysql
#       |-/logs
#           |-/httpd
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
    
    cd /usr/local/src/php-5.4.12
    ./configure --prefix=/usr/local/php  --with-apxs2=/usr/local/httpd/bin/apxs --with-config-file-path=/usr/local/php/etc --enable-bcmath --enable-shmop --enable-sysvsem --enable-ftp --with-curl --with-curlwrappers --with-png-dir --with-jpeg-dir --with-freetype-dir --with-gd --enable-gd-native-ttf --enable-mbstring --enable-soap --enable-sockets --enable-zip --with-xmlrpc --with-mysql=/usr/local/mysql --with-mysqli=/usr/local/mysql/bin/mysql_config --with-pdo-mysql=/usr/local/mysql/ --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-zlib --with-iconv-dir=/usr/local/libiconv/ --with-pcre-dir=/usr/local/pcre --with-libxml-dir --with-mcrypt=/usr/local/libmcrypt/ --with-mhash=/usr/local/mhash/
    make
    make install
    
    cp -f /usr/local/src/php-5.4.12/php.ini-production /usr/local/php/etc/php.ini
    rm -rf /etc/php.ini

    sed -i 's#^;date.timezone =#date.timezone = Asia/Shanghai#' /usr/local/php/etc/php.ini
    sed -i 's#^expose_php = On#expose_php = Off#' /usr/local/php/etc/php.ini

    /data/scripts/httpd start

    return #?
}

# install httpd-2.2.24
httpd() {

    yum -y install zlib zlib-devel

    /usr/sbin/groupadd www
    /usr/sbin/useradd -g www www -s /bin/false
    
    cd /usr/local/src/httpd-2.2.24/

    sed -i 's/#define AP_SERVER_BASEPRODUCT "Apache"/#define AP_SERVER_BASEPRODUCT "Microsoft-IIS"/' /usr/local/src/httpd-2.2.24/include/ap_release.h

    ./configure --prefix=/usr/local/httpd --enable-http --enable-mods-shared=most --enable-vhost-alias --with-mpm=prefork --enable-so --enable-rewrite --enable-spelling --enable-deflate
    make
    make install

    cp /usr/local/httpd/conf/httpd.conf /usr/local/httpd/conf/httpd.conf_licunchang.bak

    sed -i 's#^User daemon#User www#' /usr/local/httpd/conf/httpd.conf
    sed -i 's#^Group daemon#Group www#' /usr/local/httpd/conf/httpd.conf
    sed -i 's#^ServerAdmin you@example.com#ServerAdmin printf@live.com#' /usr/local/httpd/conf/httpd.conf
    #sed -i 's/^DocumentRoot/#DocumentRoot/' /usr/local/httpd/conf/httpd.conf
    sed -i 's/^#ServerName.*$/ServerName www.licunchang.com/' /usr/local/httpd/conf/httpd.conf
    sed -i 's#^DocumentRoot.*#DocumentRoot "/data/web/www.licunchang.com"#' /usr/local/httpd/conf/httpd.conf
    sed -i 's#^<Directory ".*htdocs.*">#<Directory "/data/web/www.licunchang.com">#' /usr/local/httpd/conf/httpd.conf
    sed -i '0,/^LoadModule/s//LoadModule php5_module modules\/libphp5.so\n&/' /usr/local/httpd/conf/httpd.conf
    sed -i '/^# Virtual hosts$/a\Include /usr/local/httpd/conf/vhosts/*.conf' /usr/local/httpd/conf/httpd.conf
    sed -i '/^# Virtual hosts$/a\NameVirtualHost *:80' /usr/local/httpd/conf/httpd.conf
    sed -i '/^<\/FilesMatch>/a\
\
<FilesMatch \\.php$>\
    SetHandler application/x-httpd-php\
</FilesMatch>' /usr/local/httpd/conf/httpd.conf
    sed -i '/^DocumentRoot/a\
\
ServerSignature Off\
ServerTokens Prod\
\
<IfModule mod_headers.c>\
  Header unset Server\
  Header unset X-Powered-By\
</IfModule>' /usr/local/httpd/conf/httpd.conf


    mkdir -p /usr/local/httpd/conf/vhosts/

    cat > /usr/local/httpd/conf/vhosts/www.licunchang.com.conf <<'EOF'
<VirtualHost *:80>
    ServerAdmin printf@live.com
    DocumentRoot "/data/web/www.licunchang.com"
    ServerName licunchang.com
    ServerAlias www.licunchang.com
    ErrorLog "logs/www.licunchang.com.error.log"
    CustomLog "logs/www.licunchang.com.access.log" common
</VirtualHost>
EOF

    cat > /usr/local/httpd/conf/vhosts/mysql.licunchang.com.conf <<'EOF'
<VirtualHost *:80>
    ServerAdmin printf@live.com
    DocumentRoot "/data/web/mysql.licunchang.com"
    ServerName mysql.licunchang.com
    ErrorLog "logs/mysql.licunchang.com.error.log"
    CustomLog "logs/mysql.licunchang.com.access.log" common
</VirtualHost>
EOF

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

    chown www.www /data/web/mysql.licunchang.com  -R
    chmod 744 /data/web/mysql.licunchang.com  -R

    ln -s /usr/local/httpd/bin/apachectl /data/scripts/httpd

    chmod 755 /data/scripts/httpd
    
    sed -i '/^-A INPUT -i lo -j ACCEPT$/a\
-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT' /etc/sysconfig/iptables
    
    service iptables restart
    
    return #?
}
EOF

#MySQL
if [ -d "/usr/local/src/mysql-5.5.30" ]; then
    mysql
fi

#httpd
if [ -d "/usr/local/src/httpd-2.2.24" ]; then
    httpd
fi

#php
if [ -d "/usr/local/src/php-5.4.12" ]; then
    php
fi

