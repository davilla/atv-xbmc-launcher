#!/bin/sh

# Name: killxbmxhelper.h

# Author: Stephan Diederich

# Description: does what it says...

#name of the app to kill
BoxeeHELPER="boxeeservice"

#change logfile to get some debug output
LOGFILE=/dev/null
#LOGFILE=/Users/frontrow/xbmhelperkiller.log

### Get PID of BoxeeHelper ###
PID=`ps auxww | grep "$BoxeeHELPER" | awk '!/grep/ {print $2}'`
if [[ -z $PID ]]; then
  echo "Error:" $BoxeeHELPER "not running!" >> $LOGFILE
  exit 2
fi

kill $PID

echo $BoxeeHELPER "killed on PID" $PID "and exited" >> $LOGFILE

