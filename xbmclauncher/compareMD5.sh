#!/bin/sh

# Name: compareMD5

# Author: Stephan Diederich

# Description: input filename and a MD5 sum; ouput: TRUE if MD5 matches, false if file not present or no match

#name of the app to kill
FILENAME="$1"
MD5SUM="$2"
MD5APP=/sbin/md5

if [ ! $FILENAME ]; then exit -1; fi;
if [ ! $MD5SUM ]; then exit -1; fi;

#change logfile to get some debug output
LOGFILE=/dev/null
#LOGFILE=/Users/frontrow/compareMD5.log

### Get PID of XBMCHelper ###
echo "Checking MD5 of" $FILENAME "against" $MD5SUM >> $LOGFILE

if [ -f $FILENAME ] 
then
	TESTSUM=`$MD5APP $FILENAME | sed "s/.*= //"`  
	echo File MD5: $TESTSUM >> $LOGFILE
	echo Test MD5:$MD5SUM >> $LOGFILE
	if [ "$TESTSUM" = "$MD5SUM" ] 
	then
		echo "MD5 matches!" >> $LOGFILE		
		exit 0
	fi
	echo "MD5 does _NOT_ match!" >> $LOGFILE		
	exit -1
fi

echo $FILENAME "not found" >> $LOGFILE
exit -1



