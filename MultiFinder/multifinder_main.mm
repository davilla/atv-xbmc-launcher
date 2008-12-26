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

// Build MultiFinder and place it -> /Applications/MultiFinder.app
// alternative) set APPLETV_IP in cmake cache and use MGBuildAndCopyToATV target
// sudo defaults write /Library/Preferences/com.apple.loginwindow Finder /Applications/MultiFinder.app
//
// To switch back to frontrow (Finder.app)
// sudo defaults delete /Library/Preferences/com.apple.loginwindow Finder
//
// If you want to see contents of com.apple.loginwindow.plist, it's a binary plist
// ./plutil -convert xml1 -o ./com.apple.loginwindow.plist /Library/Preferences/com.apple.loginwindow.plist
// more com.apple.loginwindow.plist
//
//
// To powerup and launch directly into XBMC.app.
// defaults write com.teamxbmc.multifinder DefaultApplicationIRMode -int 1
// defaults write com.teamxbmc.multifinder DefaultApplication "/Applications/XBMC.app/Contents/MacOS/XBMC"
//
// To revert
// rm ~/Library/Preferences/com.teamxbmc.multifinder
//
//
// doing
// defaults write com.teamxbmc.xbmclauncher XBMCExpertMode 1
// enables the MFDefaultApp setting so the above can be done in Launcher
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

//--------------------------------------------------------------
@interface FeedWatchDog : NSObject 
- (void) bone:(NSTimer *)timer; 
@end 

//--------------------------------------------------------------
@implementation FeedWatchDog 
- (void) bone:(NSTimer *)timer
{ 
  //NSLog(@"here's a bone for watchdog");
  notify_post("com.apple.riptide.heartbeat");
} 
@end

//--------------------------------------------------------------
void signal_handler(int sig) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  printf("Caught signal. Exiting...\n");
  [NSApp terminate:nil];
  [pool release];
}

//--------------------------------------------------------------
void atv_hw_init(void) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  //start settingsHelper and wait for finish
  NSString* p_settings_helper_path = [[NSBundle bundleForClass:[MultiFinder class]] pathForResource:@"SettingsHelper" ofType:@""];
  NSLog(@"%@",p_settings_helper_path);
  NSTask* p_settings_helper = nil;
  @try {
    p_settings_helper = [NSTask launchedTaskWithLaunchPath:p_settings_helper_path arguments:[NSArray array]];
  } @catch (NSException* e) {
    p_settings_helper = nil;
  }  
  if(!p_settings_helper) {
    NSLog(@"Ouch. Could not launch settingshelper");
  } else {
    NSLog(@"Settingshelper successfully launched");
  }
  [p_settings_helper waitUntilExit];
  
  [pool release];
}

//--------------------------------------------------------------
//--------------------------------------------------------------
int main(int argc, char *argv[])
{
  signal(SIGQUIT, signal_handler);
  signal(SIGTERM, signal_handler);
  signal(SIGINT, signal_handler);
  
  // notify apple tv framework stuff (2.1, 2.2, 2.3 only)
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  //create a connection to window server
  //at least one way to get informed of NSWorkspace notifications of app-launches
  [NSApplication sharedApplication];

  // setup hardware
  atv_hw_init();
  
  // setup our NSTimers
  FeedWatchDog *feed_watchdog = [[[FeedWatchDog alloc] init] autorelease]; 
  [NSTimer scheduledTimerWithTimeInterval:58.0 target:feed_watchdog selector:@selector(bone:) userInfo:nil repeats:YES]; 
    
  // setup our app listener which starts up Finder by default
  [[[MultiFinder alloc] init] autorelease];

  // make a run loop and go
  [NSApp run];
    
  [pool release];
  return EXIT_SUCCESS; 
}



