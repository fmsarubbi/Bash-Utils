#!/bin/bash

# ===================================
# ses_creator.sh
# ===================================
# desc: creates self-extracting script 
# by compressing, encoding (base64)
# and appending a direcory's contents
# to an installer template file.
#
# author: mniebla
# ===================================

DOUBLE_SEP="====================================================="
SINGLE_SEP="-----------------------------------------------------"
TEMP_DIR=`mktemp -d -t ses`

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

init()
{
    echo
    announce "Creating Self-Extracting Script (ses) for '$PACKAGE_NAME'" 1
    echo
}

prepare_installer()
{
    local TEMPLATE=$1
    local OUTPUT=$2

    announce "Preparing installer '$OUTPUT'"

	sed "s/__PACKAGE_NAME__/$PACKAGE_NAME/" "$TEMPLATE" > "$OUTPUT"
    chmod 755 $OUTPUT

}

compress_package()
{
    local PACKAGE_NAME="$1"
    local INPUT_DIR="$2"
    local CURR_DIR=`pwd`

    announce "Compressing '$INPUT_DIR'"

    cd "$INPUT_DIR"
    tar -pcvzf "$PAYLOAD_FILE" ./*
    cd "$CURR_DIR"
}

append_package()
{
    local PAYLOAD="$2"
    local OUTPUT="$3"

    announce "Base64 encoding '$PAYLOAD'"

	echo "__PAYLOAD_BELOW__" >> "$OUTPUT"
	cat "$PAYLOAD" | base64 >> "$OUTPUT"
}

cleanup()
{
    rm -rf $TEMP_DIR

    announce "Final ses '$OUTPUT_FILE'"
}

print_usage()
{
    VAL=$1
    echo
    echo "    Usage: `basename $0` [-h][-v][-n package_name] -d <input_dir> -i <installer_template> -o <output_file>"
    echo "           -h : help dialogue"
    echo "           -v : verbose mode, default: false"
    echo "           -n : package name, default: leaf of input directory"
    echo "           -d : input directory to package"
    echo "           -i : installer template file"
    echo "           -o : output file"
    echo
    exit $VAL
}

process_args()
{
    while getopts "hvn:d:i:o:" OPT;do
        case $OPT in
            h) echo && print_usage 0 ;;
            v) VERBOSE=1 ;;
            n) OPTNAME=$OPTARG ;;
            d) INPUT_DIR=$OPTARG ;;
            i) INPUT_TEMPLATE=$OPTARG ;;
            o) OUTPUT_FILE=$OPTARG ;;
           \?) echo "Invalid arg: $OPT" >&2 && print_usage 1 ;;
        esac
    done

    if [ -z "$INPUT_DIR" ]; then
        echo "Input directory was not specified." >&2 && print_usage 2
    fi

    if [ -z "$INPUT_TEMPLATE" ]; then
        echo "Input template file was not specified." >&2 && print_usage 3
    fi

    if [ -z "$OUTPUT_FILE" ]; then
        echo "Output file was not specified." >&2 && print_usage 4
    fi

    if [ -z "$OPTNAME" ]; then
        PACKAGE_NAME=`basename "$INPUT_DIR"`
    else
        PACKAGE_NAME="$OPTNAME"
    fi

    PAYLOAD_FILE="$TEMP_DIR"/"$PACKAGE_NAME.tgz"
}

process_args $@

init
compress_package "$PACKAGE_NAME" "$INPUT_DIR"
prepare_installer "$INPUT_TEMPLATE" "$OUTPUT_FILE"
append_package "$INPUT_TEMPLATE" "$PAYLOAD_FILE" "$OUTPUT_FILE"
cleanup
