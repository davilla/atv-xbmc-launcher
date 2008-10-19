#!/bin/sh

# Name: killxbmxhelper.h

# Author: Stephan Diederich

# Description: does what it says...

#name of the app to kill
XBMCHELPER="$1"

#change logfile to get some debug output
LOGFILE=/dev/null
#LOGFILE=/Users/frontrow/xbmhelperkiller.log

### Get PID of XBMCHelper ###
PID=`ps auxww | grep "$XBMCHELPER" | awk '!/grep|killxbmchelper/ {print $2}'`
if [[ -z $PID ]]; then
  echo "Error:" $XBMCHELPER "not running" >> $LOGFILE
  exit 0
fi

kill $PID

echo $XBMCHELPER "killed on PID" $PID "and exited" >> $LOGFILE

