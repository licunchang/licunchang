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