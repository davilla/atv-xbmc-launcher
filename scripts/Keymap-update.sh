#!/bin/sh

KEYMAP=$1
PW="frontrow"
XBMC_USERDATA="/Users/frontrow/Library/Application Support/XBMC/userdata/"

echo "Updating Keymap.xml"

# check that disk-image exists
if [ -e $KEYMAP ]; then

 #check if Keymap.xml exists
 if [ -e "$XBMC_USERDATA/Keymap.xml" ]; then
    echo "Backing up old $XBMC_USERDATA/Keymap.xml"
   	mv "$XBMC_USERDATA/Keymap.xml" "$XBMC_USERDATA/Keymap.xml.$(date +%s)"
 fi
 cp $1 $XBMC_USERDATA/Keymap.xml
 exit 0
fi
echo "Failed to find $KEYMAP"
exit -1

