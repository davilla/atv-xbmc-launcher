# Uninstall #

... is done on the terminal after logging into the atv by ssh, but still pretty easy, as there are only a few folders to delete (password is frontrow):

login
```
ssh frontrow@appletv.local
```

delete launcher and XBMC / Boxee
```
sudo rm -rf /Applications/{Boxee,XBMC}.app/ 
sudo rm -rf ~/Applications/{Boxee,XBMC}.app/ 
sudo rm -rf /System/Library/CoreServices/Finder.app/Contents/PlugIns/XBMCLauncher.frappliance/
```

remove settings of Boxee and XBMC:
```
rm -rf /Users/frontrow/Library/Application\ Support/{BOXEE,XBMC}/
```

That's it.