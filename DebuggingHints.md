# Gettings logs #

To report a bug it's essential to provide logfiles. For XBMC on ATV those are the interesting ones:
/Library/Logs/Console/501/console.log
/Users/frontrow/Library/Logs/xbmc.log

To get them from your Apple to your local disk use:
```
scp frontrow@appletv.local:/Library/Logs/Console/501/console.log .
scp frontrow@appletv.local:/Users/frontrow/Library/Logs/xbmc.log .
```

Now both of them should be on your local disk in the folder you ran scp (pwd shows it). Paste them to a public pastebin ([pastebin](http://pastebin.com), [rafb](http://www.rafb.net/paste)) and include the links to those pastes in your bugreport.