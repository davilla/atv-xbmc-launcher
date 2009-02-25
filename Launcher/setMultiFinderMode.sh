#!/bin/bash

# setMultiFinderMode.sh
# xbmclauncher
#
# Created by Stephan Diederich on 02/2009.
# Copyright 2009 University Heidelberg. All rights reserved.
PASSWD=frontrow
E_MISSING_MF=3

MULTIFINDER=/System/Library/CoreServices/Finder.app/Contents/Plugins/XBMCLauncher.frappliance/Contents/Resources/MultiFinder.app
case $1 in
OFF)
  #should we delete MultiFinder.app here?
  echo "Resetting loginwindow" 
  echo $PASSWD | sudo -S sh -c "/usr/bin/defaults delete /Library/Preferences/com.apple.loginwindow Finder"
  # restart loginwindow
  echo "Restarting loginwindow" 
  kill `ps awwx | grep [l]oginwindow | awk '{print $1}'`
  kill `ps awwx | grep [F]inder | grep -v setMultFinderMode | awk '{print $1}'`
  ;;
ON)
  # do some sanity checks here.
  # does MultiFinder.app exist
  if [ ! -d "$MULTIFINDER" ]; then
   echo "MultiFinder.app not found in $MULTIFINDER. Bailing out..."
   exit $E_MISSING_MF
  fi
  #set as default app on boot
  echo "Setting loginwindow to $MULTIFINDER" 
  echo $PASSWD | sudo -S sh -c "/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow Finder $MULTIFINDER"
  # restart loginwindow
  echo "Restarting loginwindow" 
  kill `ps awwx | grep [l]oginwindow | awk '{print $1}'`
  kill `ps awwx | grep [F]inder | grep -v setMultFinderMode | awk '{print $1}'`
  ;;
*)
  echo "USAGE: setMultiFinderMode.sh {ON|OFF}"
  echo "ON: enables MultiFinder by setting loginwindow to $MULTIFINDER"
  echo "OFF: deletes 'Finder' key in loginwindow's plist"
  ;;
esac



