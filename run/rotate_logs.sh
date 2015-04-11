#!/bin/bash

cd ~/.cfortsv/logs/

yr=`date +%Y`
mth=`date +%m`
longtimestamp=`date +%Y-%m-%d %H:%M:%S`
timestamp=`date +%y%m%d`
logfile=$yr/$mth/server-$timestamp.log

mkdir -p $yr/$mth
echo ">> $longtimestamp -- Rotating log files..." >> server.log
mv server.log $logfile
gzip -f -9 $logfile
echo ">> $longtimestamp -- Log file rotation complete!" > server.log
