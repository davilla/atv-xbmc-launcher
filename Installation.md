# Howto install / do an update #

The only requirement to install this plugin is an AppleTV with ssh acess.
The other steps are quite easy:

  * Download the current Launcher in [Downloads](http://code.google.com/p/atv-xbmc-launcher/downloads/list)

  * Copy it to your apple tv e.g. with (password is 'frontrow')
```
 scp  Launcher-debug-0.9.run frontrow@appletv.local:
```
  * ssh into your apple tv (passwort is still 'frontrow')
```
 ssh frontrow@appletv.local
```
  * execute the copied file. This will also prompt to restart Finder.
```
 sudo sh ./Launcher-debug-0.9.run
```

A Launcher entry should now appear in the menu.

There's an open patchstick creator project which allows you to create patchstick for an unpatched ATV:
http://code.google.com/p/atvusb-creator/