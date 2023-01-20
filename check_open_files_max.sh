#!/bin/bash
# 
# Inspired by: https://github.com/wefixit-AT/nagios_check_open_files
#
# Author: Ulrich Leodolter
# Mail: ulrich.leodolter at obvsg.at

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

PERCDONE_MAX=0
FILES_MAX=0
PID_MAX=0

while read FILES PID; do
    if [ "$FILES" -gt "$FILES_MAX" ]; then
        PERCDONE_PRE=$(echo "scale=2;(($FILES/$OPEN_F) * 100)" |bc)
        PERCDONE_MAX=`echo $PERCDONE_PRE | cut -d. -f1`
        FILES_MAX=$FILES
        PID_MAX=$PID
    fi
done < <($SUDO $LSOF -u $USER | tail -n+2 | awk '{print $2}' | sort | uniq -c)

if [ $PERCDONE_MAX -lt 84 ]; then
    ERROR_CODE=0
    printf "FILES OK - $PERCDONE_MAX %% with $FILES_MAX files open pid=$PID_MAX|files=$FILES_MAX;;;\n"
else
    if [ $PERCDONE_MAX -ge 85 ] && [ $PERCDONE_MAX -le 94 ]; then
        ERROR_CODE=1
    	printf "FILES WARN - $PERCDONE_MAX %% with $FILES_MAX files open pid=$PID_MAX|files=$FILES_MAX;;;\n"
    elif [ $PERCDONE_MAX -ge 95 ]; then
        ERROR_CODE=2
    	printf "FILES CRIT - $PERCDONE_MAX %% with $FILES_MAX files open pid=$PID_MAX|files=$FILES_MAX;;;\n"
  fi
fi

exit $ERROR_CODE
