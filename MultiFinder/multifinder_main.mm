// The idea here is radical, basically a Finder replacement.
// Headless app that handles watchdog and is a launcher for 
// Frontrow and XBMC using notifications. Calling it MultiFinder
// after the original introduced to System 5 
// (http://en.wikipedia.org/wiki/MultiFinder). Steve Jobs might
//  appreciate the humor :)

// Default setup is to have loginwindow launch MultiFinder on boot
// replacing Frontrow (Finder.app) and launch frontrow from MultiFinder.
// XBMCLauncher just sends a notification to MultiFinder to quit 
// frontrow and launch xbmc. Then watches xbmc for terminate, 
// re-launches frontrow. Frontrow will never get in the way again.

// Still a work in progress

// AppleTV framework setup: 
// /Developer/SDKs/MacOSX10.4u.sdk/System/Library/PrivateFrameworks/BackRow.framework
// /Developer/SDKs/MacOSX10.4u.sdk/System/Library/PrivateFrameworks/AppleTV.framework
// /Developer/SDKs/MacOSX10.4u.sdk/System/Library/PrivateFrameworks/iPhotoAccess.framework
//
// Also need this because there are two frameworks inside BackRow.framework
// /System/Library/PrivateFrameworks/BackRow.framework

// Build MultiFinder and place it -> /Users/frontrow/MultiFinder.app
// alternative) set APPLETV_IP in cmake cache and use MGBuildAndCopyToATV target
// sudo defaults write /Library/Preferences/com.apple.loginwindow Finder /Users/frontrow/MultiFinder.app
//
// To switch back to frontrow (Finder.app)
// sudo defaults delete /Library/Preferences/com.apple.loginwindow Finder
//
// If you want to see contents of com.apple.loginwindow.plist, it's a binary plist
// ./plutil -convert xml1 -o ./com.apple.loginwindow.plist /Library/Preferences/com.apple.loginwindow.plist
// more com.apple.loginwindow.plist
//
// Right now manual switching only, to do the switch
// sudo kill `ps awwx | grep [l]oginwindow | awk '{print $1}'`
//
// Launch XBMC
// open /Applications/XBMC.app
//
// Exit XBMC
// sudo kill `ps awwx | grep [X]BMC | awk '{print $1}'`
//
//
// Launch Frontrow (Finder.app)
// open /System/Library/CoreServices/Finder.app
//
// Exit Frontrow
// sudo kill `ps awwx | grep [F]inder | awk '{print $1}'`
//
//
// kudos to Eric Steil III for the initial feeding the watchdog
//
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/time.h>
#include <unistd.h>
#include <notify.h>
#include <time.h>

#import <Foundation/Foundation.h>

#import <MultiFinder.h>

int main(int argc, char *argv[])
{
  // notify apple tv framework stuff (2.1, 2.2, 2.3 only)
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  //start settingsHelper
  NSString* p_settings_helper_path = [[NSBundle bundleForClass:[MultiFinder class]] pathForResource:@"SettingsHelper" ofType:@""];
  NSLog(@"%@",p_settings_helper_path);
  NSTask* p_settings_helper = nil;
  @try {
    p_settings_helper = [NSTask launchedTaskWithLaunchPath:p_settings_helper_path arguments:[NSArray array]];
  } @catch (NSException* e) {
    [p_settings_helper release];
    p_settings_helper = nil;
  }  
  if(!p_settings_helper){
    NSLog(@"Ouch. Could not launch settingshelper");
  } else {
    NSLog(@"Settingshelper successfully launched");
  }
  //wait for settingshelper to be up and running
  //otherwise xbmchelper may has already captured LED/IR and so we can't set LED 
	NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.2];
	[NSThread sleepUntilDate:future];
   
  // setup our app listener which starts up Finder by default
  MultiFinder* multifinder = [[MultiFinder alloc] init];

  // make a run loop and go
  NSRunLoop *theRL = [NSRunLoop currentRunLoop]; 
  while ([theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ; 
  
  // we never get here but this silences a compiler warning
  [multifinder release];
  
  [pool release];
  return EXIT_SUCCESS; 
}



