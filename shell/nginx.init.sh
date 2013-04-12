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
    killproc $nginx -HUP
    RETVAL=$?
    echo
    return $RETVAL
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
    status)
        rh_status
        ;;
    condrestart|try-restart)
        rh_status_q || exit 0
        ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|configtest}"
        exit 2
esac