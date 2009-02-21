#!/bin/bash

# setAutoUpdate.sh
# xbmclauncher
#
# Created by Stephan Diederich on 11/21/08.
# Copyright 2008 University Heidelberg. All rights reserved.
PASSWD=frontrow
case $1 in
OFF)
  echo $PASSWD | sudo -S sh -c "echo \"127.0.0.1 mesu.apple.com\" >> /etc/hosts"
  ;;
ON)
  echo $PASSWD | sudo -S /usr/bin/sed -ie '/mesu.apple.com/d' "/etc/hosts"
  ;;
*)
  echo "USAGE: setAutoUpdate.sh {ON|OFF}"
  ;;
esac



