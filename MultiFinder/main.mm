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

// Build MultiFinder and place it -> /Users/frontrow/MultiFinder
// sudo defaults write /Library/Preferences/com.apple.loginwindow Finder /Users/frontrow/MultiFinder
//
// To switch back to frontrow (FInder.app)
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

//--------------------------------------------------------------
@interface ATVSettingsHelper
+(id)singleton;
-(BOOL)tellWatchdogWeAreUpAndRunning;
@end

//--------------------------------------------------------------
@interface ATVHardwareUtility
+(void)turnOnWhiteLED;
@end

//--------------------------------------------------------------
@interface GetCGStatus : NSObject 
- (void) get_cg_staus:(NSTimer *)timer; 
@end 
 
@implementation GetCGStatus 
- (void) get_cg_staus:(NSTimer *)timer
{ 
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  NSLog(@"get cg_status...");

  [pool release];
} 
@end 
 
//--------------------------------------------------------------
@interface FeedWatchDog : NSObject 
- (void) bone:(NSTimer *)timer; 
@end 

@implementation FeedWatchDog 
- (void) bone:(NSTimer *)timer
{ 
  NSLog(@"here's a bone for watchdog");
  notify_post("com.apple.riptide.heartbeat");
} 
@end 

//--------------------------------------------------------------
//--------------------------------------------------------------
int main(int argc, char *argv[])
{
  // notify apple tv framework stuff (2.1, 2.2, 2.3 only)
  NSAutoreleasePool *pool = [NSAutoreleasePool new];
  
  // preamble (setup watchdog and default the LED to white)
  [[ATVSettingsHelper singleton] tellWatchdogWeAreUpAndRunning];
  [ATVHardwareUtility turnOnWhiteLED];
  
  // setup our NSTimers
  GetCGStatus *cg_status = [[GetCGStatus alloc] init]; 
  [NSTimer scheduledTimerWithTimeInterval:5.0 target:cg_status selector:@selector(get_cg_staus:) userInfo:nil repeats:YES]; 

  FeedWatchDog *feed_watchdog = [[FeedWatchDog alloc] init]; 
  [NSTimer scheduledTimerWithTimeInterval:58.0 target:feed_watchdog selector:@selector(bone:) userInfo:nil repeats:YES]; 

  // make a run loop and go
  NSRunLoop *theRL = [NSRunLoop currentRunLoop]; 
  while ([theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ; 
  
  [pool release];
  return EXIT_SUCCESS; 
}



