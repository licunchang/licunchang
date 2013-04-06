#!/bin/bash
# description    xtrabackup & memcached & redis & varnish & mongodb
# author         LiCunchang

# 1 percona-xtrabackup-2.0.5.tar.gz (mysql-5.5.17.tar.gz)
# 2 memcached-1.4.15.tar.gz (libevent-2.0.21-stable.tar.gz)
# 3 redis-2.6.11.tar.gz
# 4 varnish-3.0.3.tar.gz
# 5 mongodb-src-r2.4.1.tar.gz
# 6 tcpdump-4.3.0.tar.gz (libpcap-1.3.0.tar.gz)

# source directory: /usr/local/src

prepare() {

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

    yum -y install make cmake gcc gcc-c++ chkconfig automake autoconf
}

# install percona-xtrabackup-2.0.5.tar.gz
xtrabackup() {

    yum -y install cmake gcc gcc-c++ patch libaio libaio-devel automake autoconf bzr bison libtool ncurses-devel zlib-devel perl-Time-HiRes
    
    cd /usr/local/src
    
    source_file=/usr/local/src/percona-xtrabackup-2.0.5.tar.gz
    
    if [ -f $source_file ]; then
        tar zxvf $source_file
    else
        echo "[error] $source_file not found."
        exit 6
    fi
    
    cd /usr/local/src/percona-xtrabackup-2.0.5
    cp /usr/local/src/mysql-5.5.17.tar.gz /usr/local/src/percona-xtrabackup-2.0.5
    ./utils/build.sh innodb55
    
    mkdir /usr/local/xtrabackup

    cp ./innobackupex /usr/local/xtrabackup/
    cp ./src/xtrabackup_innodb55 /usr/local/xtrabackup/
    ln -s /usr/local/xtrabackup/xtrabackup_innodb55 /usr/local/xtrabackup/xtrabackup_55
    cp ./src/xbstream /usr/local/xtrabackup/

    export PATH="$PATH:/usr/local/mysql/bin:/usr/local/xtrabackup"
    
    return $?
}

# install memcached-1.4.15.tar.gz
memcached() {

    cd /usr/local/src

    source_file=/usr/local/src/libevent-2.0.21-stable.tar.gz
    
    if [ -f $source_file ]; then
        tar zxvf $source_file
    else
        echo "[error] $source_file not found."
        exit 6
    fi

    cd /usr/local/src/libevent-2.0.21-stable
    ./configure  --prefix=/usr/local/libevent
    make
    make install
    
    cd /usr/local/src

    source_file=/usr/local/src/memcached-1.4.15.tar.gz
    
    if [ -f $source_file ]; then
        tar zxvf $source_file
    else
        echo "[error] $source_file not found."
        exit 6
    fi

    cd /usr/local/src/memcached-1.4.15
    ./configure  --prefix=/usr/local/memcached --with-libevent=/usr/local/libevent --enable-64bit
    make
    make install
    
    return $?
}

# install redis-2.6.11.tar.gz
redis() {

    yum -y install tcl

    cd /usr/local/src

    source_file=/usr/local/src/redis-2.6.11.tar.gz
    
    if [ -f $source_file ]; then
        tar zxvf $source_file
    else
        echo "[error] $source_file not found."
        exit 6
    fi

    cd /usr/local/src/redis-2.6.11
    make
    make install

    mkdir -p /usr/local/redis/bin /usr/local/redis/conf

    cp /usr/local/bin/redis* /usr/local/redis/bin/
    cp /usr/local/src/redis-2.6.11/redis.conf /usr/local/redis/conf/
    cp /usr/local/redis/conf/redis.conf /usr/local/redis/conf/redis.conf_licunchang.bak

    sed -i 's/^daemonize no/daemonize yes/' /usr/local/redis/conf/redis.conf

    cat > /data/scripts/redis <<'EOF'
#!/bin/bash
#
# Simple Redis init.d script conceived to work on Linux systems
# as it does use of the /proc filesystem.

REDISPORT=6379
EXEC=/usr/local/redis/bin/redis-server
CLIEXEC=/usr/local/redis/bin/redis-cli

PIDFILE=/var/run/redis.pid
CONF="/usr/local/redis/conf/redis.conf"

case "$1" in
    start)
        [ `netstat -tunpl | grep 6379 | wc -l` -eq 0 ] || exit 6
        if [ -f $PIDFILE ]
        then
                echo "$PIDFILE exists, process is already running or crashed"
        else
                echo -n "Starting Redis server..."
                $EXEC $CONF
                if [ `netstat -tunpl | grep 6379 | wc -l` -ne 0 ]; then
                    echo "done"
                else
                    echo "failed"
                    exit 2
                fi
        fi
        ;;
    stop)
        if [ ! -f $PIDFILE ]
        then
                echo "$PIDFILE does not exist, process is not running"
        else
                PID=$(cat $PIDFILE)
                echo "Stopping ..."
                $CLIEXEC -p $REDISPORT shutdown
                while [ -x /proc/${PID} ]
                do
                    echo "Waiting for Redis to shutdown ..."
                    sleep 1
                done
                echo "Redis stopped"
        fi
        ;;
    *)
        echo "Please use start or stop as first argument"
        ;;
esac
EOF
    
    chmod 755 /data/scripts/redis

    return $?
}

# install varnish-3.0.3.tar.gz
varnish() {
    
    yum -y install automake autoconf libtool ncurses-devel libxslt groff pcre-devel pkgconfig

    cd /usr/local/src

    source_file=/usr/local/src/varnish-3.0.3.tar.gz
    
    if [ -f $source_file ]; then
        tar zxvf $source_file
    else
        echo "[error] $source_file not found."
        exit 6
    fi

    cd /usr/local/src/varnish-3.0.3
    ./autogen.sh
    ./configure --prefix=/usr/local/varnish
    make
    make install

    #/usr/local/varnish/sbin/varnishd -f /usr/local/varnish/etc/varnish/default.vcl -s malloc,1G -T 127.0.0.1:2000 -a 0.0.0.0:8080
    #http://www.cnblogs.com/littlehb/archive/2012/02/11/2346319.html
    return $?
}

# install mongodb-src-r2.4.1.tar.gz
mongodb() {

    #todo
    cd /usr/local/src

    source_file=/usr/local/src/mongodb-src-r2.4.1.tar.gz
    
    if [ -f $source_file ]; then
        tar zxvf $source_file
    else
        echo "[error] $source_file not found."
        exit 6
    fi

    cd /usr/local/src/mongodb-src-r2.4.1
    
    return $?
}

# install tcpdump-4.3.0.tar.gz
tcpdump() {

    cd /usr/local/src
    source_file=/usr/local/src/libpcap-1.3.0.tar.gz
    if [ -f $source_file ]; then
        tar zxvf $source_file
    else
        echo "[error] $source_file not found."
        exit 6
    fi
    yum -y install flex
    cd /usr/local/src/libpcap-1.3.0
    ./configure --prefix=/usr/local/libpcap
    make
    make install

    cd /usr/local/src
    source_file=/usr/local/src/tcpdump-4.3.0.tar.gz
    if [ -f $source_file ]; then
        tar zxvf $source_file
    else
        echo "[error] $source_file not found."
        exit 6
    fi
    ./configure --prefix=/usr/local/tcpdump 
    make
    make install
    return $?
}
--prefix

case "$1" in
    xtrabackup)
        prepare
        xtrabackup && exit 0
        $1
        ;;
    memcached)
        prepare
        memcached && exit 0
        $1
        ;;
    redis)
        prepare
        redis && exit 0
        $1
        ;;
    varnish)
        prepare
        varnish && exit 0
        $1
        ;;
#    mongodb)
#        prepare
#        mongodb && exit 0
#        $1
#        ;;
    *)
        echo $"Usage: $0 {xtrabackup|memcached|redis|varnish}"
        exit 2
esac