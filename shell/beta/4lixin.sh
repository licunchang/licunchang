#!/bin/bash

################################################################################
# Put error messages to STDERR.
# Globals:
#   None
# Arguments:
#   String
# Returns:
#   None
################################################################################
logger_error() {
    # `date --iso-8601=ns`
    printf "%s\n" "[error:$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
    exit 1
}

################################################################################
# do something
# Globals:
#   None
# Arguments:
#   IP
# Returns:
#   Integer
################################################################################
func_dosomething() {
    printf "java -jar target/dptest-mobileapi-auto-api.jar --variable apiversion:\""$1"\"  MobileApi/SearchMobileApi/\n"
    java -jar target/dptest-mobileapi-auto-api.jar --variable apiversion:\""$1"\"  MobileApi/SearchMobileApi/
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

    if [[ 0 -eq "$#" ]]; then
        echo
        echo usage: $0 [file-path]
        echo
        echo e.g. $0 /tmp/version.txt
        echo
        exit
    fi

    if [[ -z "$1" ]]; then
        echo
        echo usage: $0 [file-path]
        echo
        echo e.g. $0 /tmp/version.txt
        echo
        exit
    fi

    readonly VERSION_FILE="$1"

    if [[ ! -f "${VERSION_FILE}" ]]; then
        logger_error "${VERSION_FILE} was not found."
    fi

    while read VERSION; do
        func_dosomething "${VERSION}"
    done < "${VERSION_FILE}"
}

set -o nounset
set -o errexit

main "$@"