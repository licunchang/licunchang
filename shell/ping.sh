#!/bin/bash
#
# description    ping ip list
# author         ZhangXiao
# version        1.0.20140805

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
# ping
# Globals:
#   PINT_COUNT
# Arguments:
#   IP
# Returns:
#   Integer
################################################################################
func:ping() {
    printf "\n" >&1
    printf "%s\n" "----- $(date +'%Y-%m-%dT%H:%M:%S%z')" >&1

    ping "$1" -c "${PINT_COUNT}"

    printf "\n" >&1
}

################################################################################
# The Main Function
# Globals:
#   PINT_COUNT
#   IP_LIST_FILE_PATH
# Arguments:
#   None
# Returns:
#   None
################################################################################
main() {

    export PS4='+$LINENO:{${FUNCNAME[0]}} '

    readonly IP_LIST_FILE_PATH="/tmp/ip.list"
    readonly PINT_COUNT=10

    . /etc/sysconfig/network

    if [[ "${NETWORKING}" == "no" ]]; then
        logger::error "network is not available."
    fi

    if [[ ! -f "${IP_LIST_FILE_PATH}" ]]; then
        logger::error "${IP_LIST_FILE_PATH} was not found."
    fi

    while read IP; do
        func:ping "${IP}"
    done < "${IP_LIST_FILE_PATH}"
}

set -o nounset
set -o errexit

main "$@"