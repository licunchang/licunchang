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
        /usr/sbin/useradd -r -M -g ${nginx_group} -s /sbin/nologin ${nginx_user}
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