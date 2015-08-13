#!/bin/bash
#
# 00 00,04,08,12,16,20 * * * (/bin/bash /data/cron/mysql_backup.sh -c utrans >> /data/logs/mysql/mysql_backup_`date +"\%Y\%m\%d"`.log 2>&1)
#
# description    MySQL Backup Script via innobackupex
# author         LiCunchang(printf@live.com)
# version        1.0.20131128

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
    echo "Please Wait......"
    echo ""
}

################################################################################
# prepare
# Globals:
#   MYSQL_RUN_GROUP
#   MYSQL_CNF_PATH
#   INNOBACKUPEX_PATH
# Arguments:
#   None
# Returns:
#   None
################################################################################
prepare() {
    if [[ ! -x "${INNOBACKUPEX_PATH}" ]]; then
        logger::error "INNOBACKUPEX_PATH:""${INNOBACKUPEX_PATH}"
    fi

    if [[ ! -f "${MYSQL_CNF_PATH}" ]]; then
        logger::error "MYSQL_CNF_PATH:""${MYSQL_CNF_PATH}"
    fi

    group=$(grep "^${MYSQL_RUN_GROUP}" /etc/group | awk -F: '{print $1}')

    if [[ "${MYSQL_RUN_GROUP}" != "${group}" ]]; then
        logger::error "MYSQL_RUN_GROUP:""${MYSQL_RUN_GROUP}"
    fi
}

################################################################################
# MySQL Full Backup.
# Globals:
#   MYSQL_BACKUP_DIR
#   FROM
#   MYSQL_DATABASE
#   INNOBACKUPEX_PATH
#   MYSQL_HOST
#   MYSQL_PORT
#   MYSQL_USER
#   MYSQL_SOCKET
#   MYSQL_PASSWORD
#   MYSQL_CNF_PATH
#   MYSQL_RUN_GROUP
# Arguments:
#   None
# Returns:
#   None
################################################################################
backup:full() {

    local BACK_UP_DIR="${MYSQL_BACKUP_DIR}f-$(date +'%Y%m%d')/"

    if [[ "${FROM}" == 'f' ]]; then
        BACK_UP_DIR="${MYSQL_BACKUP_DIR}f-$(date +'%Y%m%d%H%M%S')/"
    fi

    if [[ -d "${BACK_UP_DIR}" ]]; then
        logger::error "[backup:full] BACK_UP_DIR:${BACK_UP_DIR}"
    fi

    if [[ ! -z "${MYSQL_DATABASE}" ]]; then
        "${INNOBACKUPEX_PATH}"  --defaults-file="${MYSQL_CNF_PATH}" \
                                --user="${MYSQL_USER}" \
                                --password="${MYSQL_PASSWORD}" \
                                --port="${MYSQL_PORT}" \
                                --host="${MYSQL_HOST}" \
                                --socket="${MYSQL_SOCKET}" \
                                --databases="${MYSQL_DATABASE}" \
                                --defaults-group="${MYSQL_RUN_GROUP}" \
                                --no-timestamp \
                                "${BACK_UP_DIR}"
    else
        "${INNOBACKUPEX_PATH}"  --defaults-file="${MYSQL_CNF_PATH}" \
                                --user="${MYSQL_USER}" \
                                --password="${MYSQL_PASSWORD}" \
                                --port="${MYSQL_PORT}" \
                                --host="${MYSQL_HOST}" \
                                --socket="${MYSQL_SOCKET}" \
                                --defaults-group="${MYSQL_RUN_GROUP}" \
                                --no-timestamp \
                                "${BACK_UP_DIR}"
    fi

    if [[ ! -f "${BACK_UP_DIR}xtrabackup_checkpoints" ]]; then
        logger::error "[backup:full] xtrabackup_checkpoints not exists."
    fi

    local TO_LSN=$(grep "^to_lsn" "${BACK_UP_DIR}xtrabackup_checkpoints" | awk '{print $3}')
    local FROM_LSN=$(grep "^from_lsn" "${BACK_UP_DIR}xtrabackup_checkpoints" | awk '{print $3}')
    local BACKUP_TYPE=$(grep "^backup_type" "${BACK_UP_DIR}xtrabackup_checkpoints" | awk '{print $3}')

    if [[ "${BACKUP_TYPE}" != "incremental" ]]; then
        if [[ "${BACKUP_TYPE}" != "full-backuped" ]]; then
            rm -f -R "${BACK_UP_DIR}"
            logger::error "[backup:full] backup_type is unavailable."
        fi
    fi

    if [[ "${TO_LSN}" -le 0 ]]; then
        rm -f -R "${BACK_UP_DIR}"
        logger::error "[backup:full] to_lsn is unavailable."
    fi

    if [[ "${FROM_LSN}" -gt "${TO_LSN}" ]]; then
        rm -f -R "${BACK_UP_DIR}"
        logger::error "[backup:full] from_lsn is unavailable."
    fi

    echo "${TO_LSN}" > "${BACK_UP_DIR}lcc_incremental_lsn"
    echo -e "${BACK_UP_DIR}\t${BACKUP_TYPE}\t${FROM_LSN}\t${TO_LSN}" > "${BACK_UP_DIR}lcc_incremental_list"
    echo "${BACK_UP_DIR}" > "${BACK_UP_DIR}lcc_apply_not_lock"
    echo "${BACK_UP_DIR}" > "${BACK_UP_DIR}lcc_apply_not_list"

    return "$?"
}

################################################################################
# MySQL Full Backup.
# Globals:
#   MYSQL_BACKUP_DIR
#   INNOBACKUPEX_PATH
#   MYSQL_HOST
#   MYSQL_PORT
#   MYSQL_USER
#   MYSQL_SOCKET
#   MYSQL_PASSWORD
# Arguments:
#   None
# Returns:
#   None
################################################################################
backup:incremental() {

    local BASE_DIR="${MYSQL_BACKUP_DIR}f-$(date +'%Y%m%d')/"

    if [[ ! -f "${BASE_DIR}lcc_incremental_lsn" ]]; then
        logger::error "[backup:incremental] ${BASE_DIR}lcc_incremental_lsn"
    fi
    
    local INCREMENTAL_LSN="$(cat ${BASE_DIR}lcc_incremental_lsn)"

    if [[ "${INCREMENTAL_LSN}" -le 0 ]]; then
        logger::error "[backup:incremental] incremental_lsn is unavailable."
    fi

    BACK_UP_DIR="${MYSQL_BACKUP_DIR}i-$(date +'%Y%m%d%H%M%S')/"

    if [[ -d "${BACK_UP_DIR}" ]]; then
        logger::error "[backup:incremental] BACK_UP_DIR:${BACK_UP_DIR}"
    fi

    "${INNOBACKUPEX_PATH}"  --incremental \
                            --user="${MYSQL_USER}" \
                            --password="${MYSQL_PASSWORD}" \
                            --port="${MYSQL_PORT}" \
                            --host="${MYSQL_HOST}" \
                            --socket="${MYSQL_SOCKET}" \
                            --incremental-lsn="${INCREMENTAL_LSN}" \
                            --no-timestamp \
                            "${BACK_UP_DIR}"
    
    local TO_LSN=$(grep "^to_lsn" "${BACK_UP_DIR}xtrabackup_checkpoints" | awk '{print $3}')
    local FROM_LSN=$(grep "^from_lsn" "${BACK_UP_DIR}xtrabackup_checkpoints" | awk '{print $3}')
    local BACKUP_TYPE=$(grep "^backup_type" "${BACK_UP_DIR}xtrabackup_checkpoints" | awk '{print $3}')

    if [[ "${BACKUP_TYPE}" != "incremental" ]]; then
        if [[ "${BACKUP_TYPE}" != "full-backuped" ]]; then
            logger::error "[backup:full] backup_type is unavailable."
        fi
    fi

    if [[ "${TO_LSN}" -le 0 ]]; then
        logger::error "[backup:full] to_lsn is unavailable."
    fi

    if [[ "${FROM_LSN}" -gt "${TO_LSN}" ]]; then
        logger::error "[backup:full] from_lsn is unavailable."
    fi
    
    echo -e "${BACK_UP_DIR}\t${BACKUP_TYPE}\t${FROM_LSN}\t${TO_LSN}" >> "${BASE_DIR}lcc_incremental_list"
    echo "${BACK_UP_DIR}" > "${BACK_UP_DIR}lcc_apply_not_lock"
    echo -e "\n${BACK_UP_DIR}" >> "${BASE_DIR}lcc_apply_not_list"
    echo "${TO_LSN}" > "${BASE_DIR}lcc_incremental_lsn"
    return "$?"
}

################################################################################
# MySQL Cron Backup.
# Globals:
#   MYSQL_BACKUP_DIR
# Arguments:
#   None
# Returns:
#   None
################################################################################
backup:cron() {
    local BASE_DIR="${MYSQL_BACKUP_DIR}f-$(date +'%Y%m%d')/"

    if [[ -d "${BASE_DIR}" ]]; then
        backup:incremental
    else
        backup:full
    fi
}

################################################################################
# Restore MySQL Data from Full Backup
# Globals:
#   MYSQL_BACKUP_DIR
#   INNOBACKUPEX_PATH
#   MYSQL_VERSION
#   MYSQL_DATA_DIR
#   MYSQL_CMD_START
#   MYSQL_CMD_STOP
# Arguments:
#   None
# Returns:
#   None
################################################################################
restore:from_f() {
    local BASE_DIR="${MYSQL_BACKUP_DIR}f-$(date +'%Y%m%d')/"
    local OLD_DATA_DIR="${MYSQL_BACKUP_DIR}o-$(date +'%Y%m%d')/"

    if [[ -f "${BASE_DIR}lcc_apply_not_lock" ]]; then
        echo "${INNOBACKUPEX_PATH} --apply-log --use-memory=4G --ibbackup=xtrabackup_${MYSQL_VERSION} ${BASE_DIR}"
        echo "rm -f ${BASE_DIR}lcc_apply_not_lock"
    else
        logger::error "[restore:from_f] ${BASE_DIR} already apply log"
    fi
    echo "mkdir -p ${OLD_DATA_DIR}"
    echo "${MYSQL_CMD_STOP}"
    echo "mv ${MYSQL_DATA_DIR}* ${OLD_DATA_DIR}"
    echo "${INNOBACKUPEX_PATH} --copy-back ${BASE_DIR}"
    echo "awk 'BEGIN { cmd=\"cp -r -i ${OLD_DATA_DIR}mysql ${MYSQL_DATA_DIR}\"; print \"n\" |cmd; }'"
    echo "chown mysql:mysql ${MYSQL_DATA_DIR} -R"
    echo "${MYSQL_CMD_START}"
}

################################################################################
# Restore MySQL Data from incremental Backup
# Globals:
#   MYSQL_BACKUP_DIR
#   INNOBACKUPEX_PATH
#   MYSQL_VERSION
#   MYSQL_DATA_DIR
#   MYSQL_CMD_START
#   MYSQL_CMD_STOP
# Arguments:
#   None
# Returns:
#   None
################################################################################
restore:from_i() {
    local BASE_DIR="${MYSQL_BACKUP_DIR}f-$(date +'%Y%m%d')/"
    local OLD_DATA_DIR="${MYSQL_BACKUP_DIR}o-$(date +'%Y%m%d')/"

    local I_COUNT=$(cat "${BASE_DIR}lcc_incremental_list" | wc -l)

    if [[ "${I_COUNT}" == 1 ]]; then
        restore:from_f
        exit
    fi

    if [[ -f "${BASE_DIR}lcc_apply_not_lock" ]]; then
        echo "${INNOBACKUPEX_PATH} --apply-log --redo-only --use-memory=4G --ibbackup=xtrabackup_${MYSQL_VERSION} ${BASE_DIR}"
        echo "rm -f ${BASE_DIR}lcc_apply_not_lock"
    else
        logger::error "[restore:from_i] ${BASE_DIR} already apply log"
    fi

    local INCREMENTAL_LSN="$(cat ${BASE_DIR}lcc_incremental_lsn)"

    if [[ "${INCREMENTAL_LSN}" -le 0 ]]; then
        logger::error "[restore:from_i] incremental_lsn is unavailable."
    fi

    local OLD_IFS=$IFS
    IFS=$'\n'
    for line in $(cat "${BASE_DIR}lcc_incremental_list"); do
        local INCREMENTAL_DIR=$(echo ${line} | awk -F"\t" '{print $1}')
        local BACKUP_TYPE=$(echo ${line} | awk -F"\t" '{print $2}')
        local FROM_LSN=$(echo ${line} | awk -F"\t" '{print $3}')
        local TO_LSN=$(echo ${line} | awk -F"\t" '{print $4}')

        if [[ "${BACKUP_TYPE}" == "full-backuped" ]]; then
            I_COUNT="$(expr ${I_COUNT} - 1)"
            continue
        fi

        if [[ ! -f "${INCREMENTAL_DIR}lcc_apply_not_lock" ]]; then
            logger::error "[restore:from_i] ${INCREMENTAL_DIR} already apply log"
        fi

        echo "${INNOBACKUPEX_PATH} --apply-log --redo-only --use-memory=4G --ibbackup=xtrabackup_${MYSQL_VERSION} ${BASE_DIR} --incremental-basedir=${INCREMENTAL_DIR}"
        echo "rm -f ${INCREMENTAL_DIR}lcc_apply_not_lock"

    done
    IFS=$OLD_IFS

    echo "${INNOBACKUPEX_PATH} --apply-log --use-memory=4G --ibbackup=xtrabackup_${MYSQL_VERSION} ${BASE_DIR}"

    echo "mkdir -p ${OLD_DATA_DIR}"
    echo "${MYSQL_CMD_STOP}"
    echo "mv ${MYSQL_DATA_DIR}* ${OLD_DATA_DIR}"
    echo "${INNOBACKUPEX_PATH} --copy-back ${BASE_DIR}"
    echo "awk 'BEGIN { cmd=\"cp -r -i ${OLD_DATA_DIR}mysql ${MYSQL_DATA_DIR}\"; print \"n\" |cmd; }'"
    echo "chown mysql:mysql ${MYSQL_DATA_DIR} -R"
    echo "${MYSQL_CMD_START}"
}

################################################################################
# Restore MySQL Data
# Globals:
#   None
# Arguments:
#   String
# Returns:
#   None
################################################################################
restore:main() {
    case "$1" in
        i)
            restore:from_i
            ;;
        f)
            restore:from_f
            ;;
        *)
            logger:error "the second argument is not correct( i | f )."
            ;;
    esac
}

################################################################################
# Show END
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
################################################################################
show:end() {
    echo "-------------------------------- END --------------------------------"
    echo
    echo
}

################################################################################
# Show Usage.
# Globals:
#   MYSQL_HOST
#   MYSQL_PORT
#   MYSQL_USER
#   MYSQL_SOCKET
#   MYSQL_PASSWORD
#   MYSQL_VERSION
#   MYSQL_DATA_DIR
#   MYSQL_BACKUP_DIR
#   MYSQL_CNF_PATH
#   INNOBACKUPEX_PATH
#   MYSQL_CMD_STOP
#   MYSQL_CMD_START
# Arguments:
#   None
# Returns:
#   None
################################################################################
show:usage() {

    echo "#####################################################################"
    echo "#                                                                   #"
    echo "#             NOTE: PLEASE READ EACH PART CAREFULLY!                #"
    echo "#                                                                   #"
    echo "#####################################################################"
    echo
    echo "NAME"
    echo "    mysql_backup.sh - make a MySQL backup"
    echo 
    echo "AUTHOR"
    echo "    LiCunchang"
    echo     
    echo "SYNOPSIS"
    echo "    mysql_backup.sh [options]"
    echo 
    echo "OPTIONS"
    echo "    The options which apply to this script are:"
    echo 
    echo "    -c, -c [database]"
    echo "       Create a cron MySQL backup."
    echo 
    echo "    -f, -f [database]"
    echo "       Create a Full MySQL backup."
    echo 
    echo "    -i"
    echo "       Create a Incremental MySQL backup."
    echo 
    echo "    -r, -r [ i | f ]"
    echo "       restore MySQL, from Incremental backup (i) or Full backup(f)"
    echo
    echo "    [database]"
    echo "        This option speciﬁes the database that script should back up."
    echo "        If this option is not speciﬁed, all databases containing"
    echo "        MyISAM and InnoDB tables will be backed up."
    echo
    echo "REMARKS"
    echo "    You must make sure the following configurations are correct,"
    echo "    or you should modify them in function named 'main'."
    echo
    echo "        MYSQL_HOST        = ${MYSQL_HOST}"
    echo "        MYSQL_PORT        = ${MYSQL_PORT}"
    echo "        MYSQL_USER        = ${MYSQL_USER}"
    echo "        MYSQL_PASSWORD    = ${MYSQL_PASSWORD}"
    echo "        MYSQL_VERSION     = ${MYSQL_VERSION}"
    echo "        MYSQL_SOCKET      = ${MYSQL_SOCKET}"
    echo "        MYSQL_DATA_DIR    = ${MYSQL_DATA_DIR}"
    echo "        MYSQL_BACKUP_DIR  = ${MYSQL_BACKUP_DIR}"
    echo "        MYSQL_RUN_GROUP   = ${MYSQL_RUN_GROUP}"
    echo "        MYSQL_CNF_PATH    = ${MYSQL_CNF_PATH}"
    echo "        INNOBACKUPEX_PATH = ${INNOBACKUPEX_PATH}"
    echo "        MYSQL_CMD_STOP    = ${MYSQL_CMD_STOP}"
    echo "        MYSQL_CMD_START   = ${MYSQL_CMD_START}"
    echo
}

################################################################################
# The Main Function
# Globals:
#   MYSQL_HOST
#   MYSQL_PORT
#   MYSQL_USER
#   MYSQL_SOCKET
#   MYSQL_PASSWORD
#   MYSQL_VERSION
#   MYSQL_DATA_DIR
#   MYSQL_BACKUP_DIR
#   MYSQL_RUN_GROUP
#   MYSQL_CNF_PATH
#   INNOBACKUPEX_PATH
#   MYSQL_CMD_STOP
#   MYSQL_CMD_START
# Arguments:
#   None
# Returns:
#   None
################################################################################
main() {

    export PS4='+$LINENO:{${FUNCNAME[0]}} '
    trap 'trap::interrupt $LINENO' 1 2 3 6 15

    if [[ $# -gt 2 ]]; then
        logger:error "Argument list too long."
    fi

    readonly MYSQL_HOST="localhost"
    readonly MYSQL_PORT="3306"
    readonly MYSQL_USER="xtrabackup"
    readonly MYSQL_SOCKET="/tmp/mysql.sock"
    readonly MYSQL_PASSWORD="xtrabackup"
    readonly MYSQL_VERSION="56"
    
    readonly MYSQL_DATA_DIR="/data/mysql/"
    readonly MYSQL_BACKUP_DIR="/data/backup/mysql/"
    readonly MYSQL_CNF_PATH="/etc/mysql/my.cnf"

    readonly MYSQL_RUN_GROUP="mysql"

    readonly MYSQL_CMD_STOP="/data/init.d/mysql stop"
    readonly MYSQL_CMD_START="/data/init.d/mysql start"

    readonly INNOBACKUPEX_PATH="/usr/bin/innobackupex"

    MYSQL_DATABASE=""
    if [[ $# -eq 2 ]]; then
        MYSQL_DATABASE="$2"
    else
        if [[ "$1" == "-r" ]]; then
            logger:error "the second argument is required( i | f )."
        fi
    fi
    
    case "$1" in
        -c)
            readonly FROM="c"
            prepare
            backup:cron
            ;;
        -f)
            readonly FROM="f"
            prepare
            backup:full
            ;;
        -i)
            readonly FROM="i"
            prepare
            backup:incremental
            ;;
        -r)
            prepare
            restore:main "$2"
            ;;
        *)
            show:usage
            ;;
    esac
    show:end
}

main "$@"