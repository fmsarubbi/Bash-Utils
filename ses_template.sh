#!/bin/bash

HOST_OS=`uname`

if [ "$HOST_OS" -eq "Darwin" ]; then
    SED_CMD="sed -i \"\""
else
    if [ "$HOST_OS" -eq "Linux" ]; then
        SED_CMD="sed -i"
    fi
fi

DOUBLE_SEP="========================================================================="
SINGLE_SEP="-------------------------------------------------------------------------"
PACKAGE_NAME=__PACKAGE_NAME__

announce()
{
    local MSG=$1
    local DBL=$2

    if [ -z $DBL ]; then
        local SEP=$SINGLE_SEP
    else
        local SEP=$DOUBLE_SEP
    fi

    echo $SEP
    echo " $MSG"
    echo $SEP
}

error()
{
    local MESSAGE=$1
    local FATAL_CODE=$2

    echo
    echo "ERROR: $MESSAGE"
    echo

    if [ ! -z $FATAL_CODE ]; then
        exit $FATAL_CODE
    fi 
}

execute()
{
    local COMMAND=$1
    local EXPECT=$2
    local CODE=$3

    if [ -z $EXPECT ]; then
        EXPECT=0
        CODE=1
    fi

    [[ ! -z "$VERBOSE" ]] && echo "Executing: $COMMAND"
    /bin/bash -c "$COMMAND"

    RETVAL=$?

    if [ $EXPECT -ne $RETVAL ]; then
       local MESSAGE="Command \'$COMMAND\' had unexpected exit code: $RETVAL, expected: $EXPECT"
       error $MESSAGE $CODE
   fi
}

init()
{
    if [ -e "$INSTALL_DIR" ]; then
        error "installation directory '$INSTALL_DIR' exists." 3
    fi

    local PARENT_DIR=`dirname $INSTALL_DIR`

    if [ ! -e "$PARENT_DIR" ]; then
        announce "Creating parent dir: $PARENT_DIR"
        execute "mkdir -p \"$PARENT_DIR\""
    fi
    
    INSTALL_DIR=`cd "$PARENT_DIR" && pwd`/`basename $INSTALL_DIR`

    echo
    announce "Installing '$PACKAGE_NAME'" 1
    echo
}

cleanup()
{
    announce "Installed into directory '$INSTALL_DIR'"
}

unpack()
{
    local INSTALL_DIR=$1
    local PAYLOAD_START=`awk '/^__PAYLOAD_BELOW__/ {print NR + 1; exit 0; }' $0`
    local TEMP_DIR=`mktemp -d -t "$PACKAGE_NAME"`

    announce "Unpacking into directory '$INSTALL_DIR'"

	execute "tail -n+$PAYLOAD_START $0 | base64 --decode | tar -C \"$TEMP_DIR\" -pxvzf -"

    if [ $? -eq 0 ]; then
        execute "mv \"$TEMP_DIR\" \"$INSTALL_DIR\""
    fi
}

configure()
{
	local DIR=$1

    announce "Configuring executables"

	for FILE in "$DIR"/*
    do 
        execute "$SED_CMD \"s|__INSTALL_DIR__|\"$INSTALL_DIR\"|g\" $FILE"
    done
}

print_usage()
{
    local VAL=$1
    echo
    echo "    Usage: $0 [-h][-v] -i <installation directory>"
    echo "           -h : help dialogue"
    echo "           -v : verbose mode, default: false"
    echo "           -i : installation directory"
    echo
    exit $VAL
}

process_args()
{
    while getopts "hvi:" OPT;do
        case $OPT in
            h) echo && print_usage 0 ;;
            v) VERBOSE=1 ;;
            i) INSTALL_DIR="$OPTARG";;
           \?) echo "Invalid arg: $OPT" >&2 && print_usage 1 ;;
        esac
    done

    if [ -z "$INSTALL_DIR" ]; then
        error "installation directory was not specified"
        print_usage 2;
    fi
}

process_args $@
init
unpack "$INSTALL_DIR"
configure "$INSTALL_DIR"/bin
cleanup

exit 0
