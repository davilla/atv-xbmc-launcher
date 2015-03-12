# Introduction #

For updates XBMC/Boxeelauncher downloads a file called update\_urls.plist from
  * http://atv-xbmc-launcher.googlecode.com/svn/tags/xbmc-info/update_urls.plist for Launcher <= 0.8
  * http://atv-xbmc-launcher.googlecode.com/svn/tags/mf-info/update_urls.plist for Launcher >= 2.0
> That URL is stored in XBMCLauncher.frappliance/Contents/Info.plist

# WARNING #
Don't use any of those entries if you are not sure what you are doing or if you cannot recover from serious problems on your ATV by yourself.

# Change to xbmc-info-testing #
If this URL is changed to http://atv-xbmc-launcher.googlecode.com/svn/tags/xbmc-info-testing/update_urls.plist Finder needs to be restarted. This list of updates is not maintained all the time and currently mostly used for testing versions of XBMC/Boxeelauncher.
After an update of XBMCLauncher this URL is reset to it's original value, so for another update you'll need to change it again.


This little script (put it e.g. in /usr/bin/goTesting.sh)  changes update\_urls.plist URL and restarts Finder:
```
#!/bin/bash

sed -i -e  's#xbmc-info/#xbmc-info-testing/#' "/System/Library/CoreServices/Finder.app/Contents/PlugIns/XBMCLauncher.frappliance/Contents/Info.plist"
sed -i -e  's#mf-info/#xbmc-info-testing/#' "/System/Library/CoreServices/Finder.app/Contents/PlugIns/XBMCLauncher.frappliance/Contents/Info.plist"

#restart finder
kill `ps awx | grep [F]inder | awk '{print $1}'`
```