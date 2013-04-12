#!/bin/bash
#description    cut nginx log files, run at 00:00 everyday
#crontab        00 00 * * * /bin/bash /data/cron/nginx_logs_cut.sh
#author         LiCunchang(printf@live.com)

### PART 1: Move web logs to the backup directory which named by year & month.

LOGS_PATH=/usr/local/nginx/logs/
LOGS_NAME=(www.licunchang.com mysql.licunchang.com)
LOGS_BACKUP=/data/logs/nginx/$(date -d "yesterday" +"%Y%m")/

if [ ! -d $LOGS_BACKUP ]; then
    mkdir -p $LOGS_BACKUP
fi

LOGS_NUM=${#LOGS_NAME[@]}

for ((i=0; i<$LOGS_NUM; i++)); do
    if [ -f ${LOGS_PATH}${LOGS_NAME[i]}.access.log ]; then
        mv ${LOGS_PATH}${LOGS_NAME[i]}.access.log ${LOGS_BACKUP}${LOGS_NAME[i]}.access_$(date -d "yesterday" +"%Y%m%d%k%M%S").log
    fi
    if [ -f ${LOGS_PATH}${LOGS_NAME[i]}.error.log ]; then
        mv ${LOGS_PATH}${LOGS_NAME[i]}.error.log ${LOGS_BACKUP}${LOGS_NAME[i]}.error_$(date -d "yesterday" +"%Y%m%d%k%M%S").log
    fi
done

if [ -f ${LOGS_PATH}error.log ]; then
    mv ${LOGS_PATH}error.log ${LOGS_BACKUP}error_$(date -d "yesterday" +"%Y%m%d%k%M%S").log
fi

if [ -f ${LOGS_PATH}access.log ]; then
    mv ${LOGS_PATH}access.log ${LOGS_BACKUP}access_$(date -d "yesterday" +"%Y%m%d%k%M%S").log
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