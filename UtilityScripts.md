
```
-bash-2.05b$ cat bin/watchStuff.sh 
#!/bin/sh

watch -n 1 'ps auxww | egrep -i "xbmc|boxee|finder" | grep -v egrep'
```


---

```
-bash-2.05b$ cat goTesting.sh 
#!/bin/bash

echo frontrow | sudo -S sed -i -e  's#xbmc-info/#xbmc-info-testing/#' "/System/Library/CoreServices/Finder.app/Contents/PlugIns/XBMCLauncher.frappliance/Contents/Info.plist"
echo frontrow | sudo -S sed -i -e  's#mf-info/#xbmc-info-testing/#' "/System/Library/CoreServices/Finder.app/Contents/PlugIns/XBMCLauncher.frappliance/Contents/Info.plist"
#restart finder
kill `ps awx | grep [F]inder | awk '{print $1}'`
```


---

```
-bash-2.05b$ cat resetLoginwindow 
#!/bin/bash
sudo defaults delete /Library/Preferences/com.apple.loginwindow Finder
```


---

```
-bash-2.05b$ cat setLoginwindow 
#!/bin/bash
sudo defaults delete /Library/Preferences/com.apple.loginwindow Finder
```


---

```
-bash-2.05b$ cat restartLogin 
#!/bin/bash

kill `ps -ax | grep [l]oginwindow | grep -v "$0" | awk '{print $1}'`
```


---

add xbmc-info-testing to Info.plist (needs Launcher >= 3.0)

```
-bash-2.05b$ cat bin/addXBMCInfoTesting.sh 
#!/bin/sh

PLIST=/System/Library/CoreServices/Finder.app/Contents/PlugIns/XBMCLauncher.frappliance/Contents/Info.plist

sed -i -e 's#\(\<string\>http://atv-xbmc-launcher.googlecode.com/svn/tags/ul-info/update_urls.plist\</string\>\)#\1\
\<string\>http://atv-xbmc-launcher.googlecode.com/svn/tags/xbmc-info-testing/update_urls.plist\</string\>#' $PLIST

#restart Finder
kill `ps -ax | grep [F]inder | grep -v "$0" | awk '{print $1}'`
```