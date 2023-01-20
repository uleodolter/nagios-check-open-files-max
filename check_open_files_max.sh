#!/bin/bash
# 
# https://github.com/uleodolter/nagios-check-open-files-max
# Author: Ulrich Leodolter
#
# Inspired by: https://github.com/wefixit-AT/nagios_check_open_files

SUDO=/bin/sudo
LSOF=/sbin/lsof
AWK=/bin/awk
WC=/bin/wc

ERROR_CODE=-1
if [ -z "$1" ]; then
    echo "Usage: $0 username"
    echo "  username: Username to check for to much open files"
    exit $ERROR_CODE
else
    USER=$1
fi

function checkExitStatus {
    if [ $1 -ne 0 ]; then
        echo "!!! command failure !!! $2"
        exit -1
    fi
}

# check if the username is valid
id $USER &> /dev/null
checkExitStatus $? "Username wrong"

# check if a PID is available for the user
PID=`ps -u $USER | tail -1 | awk '{print $1}'`
checkExitStatus $? "No PID found"
OPEN_F=`$SUDO cat /proc/$PID/limits | grep "open files" | awk '{print $5}'`

read FILES PID < <($SUDO $LSOF -u $USER | tail -n+2 | awk '{print $2}' | sort | uniq -c | sort -nr | head -n1)

PERCDONE_PRE=$(echo "scale=2;(($FILES/$OPEN_F) * 100)" |bc)
PERCDONE=`echo $PERCDONE_PRE | cut -d. -f1`

if [ $PERCDONE -lt 84 ]; then
    ERROR_CODE=0
    printf "FILES OK - $PERCDONE %% with $FILES files open pid=$PID|files=$FILES;;;\n"
else
    if [ $PERCDONE -ge 85 ] && [ $PERCDONE -le 94 ]; then
        ERROR_CODE=1
    	printf "FILES WARN - $PERCDONE %% with $FILES files open pid=$PID|files=$FILES;;;\n"
    elif [ $PERCDONE -ge 95 ]; then
        ERROR_CODE=2
    	printf "FILES CRIT - $PERCDONE %% with $FILES files open pid=$PID|files=$FILES;;;\n"
  fi
fi

exit $ERROR_CODE
