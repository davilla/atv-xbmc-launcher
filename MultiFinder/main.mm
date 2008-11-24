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
#import "atvxbmccommon.h"

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
@interface AppKeeper : NSObject {
  NSTask* mp_task;
  NSString* mp_next_app_to_launch; //when the currently running app dies, this one is started next
  BOOL m_app_needs_ir; //if true, launchApplication should also start our IR daemon;
  NSString* mp_default_app; //app to launch in the beginning
  BOOL m_default_app_needs_ir; //does default app need ir?
  NSTask* mp_ir_helper;
  NSString* mp_ir_helper_path;
}
- (BOOL) launchApplication:(NSString*) f_app_path;
- (void) startApplicationRequest:(NSNotification *)notification;
@end


//--------------------------------------------------------------
@implementation AppKeeper

- (id) init{
 if( ![super init] )
   return nil;
  mp_next_app_to_launch = nil;
  m_app_needs_ir = false;
  mp_default_app = @"/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder";
  m_default_app_needs_ir = false;

  mp_ir_helper_path = [[NSBundle bundleForClass:[self class]] pathForResource:@"xbmchelper" ofType:@""];
  NSLog(@"App status callback %@", mp_ir_helper_path);
  //register cross-app-notification listeners
  [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(startApplicationRequest:) name:MULTIFINDER_START_APPLICATION_NOTIFICATION object:nil];
  //by default launch Finder
  [self launchApplication:mp_default_app];
  return self;
}

//--------------------------------------------------------------
- (void) dealloc{
  [[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:MULTIFINDER_START_APPLICATION_NOTIFICATION object:nil];
  [super dealloc];
}

//--------------------------------------------------------------
- (void)checkTaskStatus:(NSNotification *)note
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:mp_task];
  NSLog(@"App status callback");
  if( ! [mp_task isRunning] ){
    //kill helper and release task object
    [mp_ir_helper terminate];
    [mp_ir_helper release];
    mp_ir_helper = nil;
    
    //print some status and release task object
    int status = [[note object] terminationStatus];
    NSLog(@"App exited with status %i", status);
		[mp_task release];
		mp_task = nil;
    
    if( mp_next_app_to_launch ){
      NSLog(@"Looks like killed by request. Starting app %@ with IR:%i", mp_next_app_to_launch, m_app_needs_ir);
      [self launchApplication:mp_next_app_to_launch];
    }
    else {
      NSLog(@"No app given. Starting default app %@ with IR:%i", mp_default_app, m_default_app_needs_ir);
      m_app_needs_ir = m_default_app_needs_ir;
      [self launchApplication:mp_default_app];    
    }
  }
  [pool release];
}

//--------------------------------------------------------------
- (BOOL) launchApplication:(NSString*) f_app_path {
	mp_task = [[NSTask alloc] init];
	@try {
		[mp_task setLaunchPath: f_app_path];
    [mp_task setCurrentDirectoryPath:@"/Applications"];
		[mp_task launch];
	} 
	@catch (NSException* e) {
    NSLog(@"Could not launch application %@", f_app_path);
    return FALSE;
	}
	//wait a bit for task to start
	NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.1];
	[NSThread sleepUntilDate:future];
	//attach our listener
	[[NSNotificationCenter defaultCenter] addObserver:self
																					 selector:@selector(checkTaskStatus:)
																							 name:NSTaskDidTerminateNotification
																						 object:mp_task];
  if(m_app_needs_ir){
    NSArray* arg = [NSArray arrayWithObjects
                    :@"-v",
                    nil];
    mp_ir_helper = [[NSTask launchedTaskWithLaunchPath:mp_ir_helper_path arguments: arg] retain];    
  }
  //now reset the variables
  [mp_next_app_to_launch release];
  mp_next_app_to_launch = nil;
  m_app_needs_ir = false;
  return TRUE;
}

//--------------------------------------------------------------
- (void) startApplicationRequest:(NSNotification *)notification {
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  NSLog(@"Got an start application request");
  NSDictionary* userInfo = [notification userInfo];
  //set next app to launch
  mp_next_app_to_launch = [[userInfo objectForKey:kApplicationPath] retain];
  if( !mp_next_app_to_launch)
    NSLog(@"Ouch something went wrong. Got a request to start an app, but no app was given!");
  //does it need IR?
  m_app_needs_ir = [[userInfo objectForKey:kApplicationNeedsIR] boolValue];
  NSLog(@"Request for app %@ withRemote:%i", mp_next_app_to_launch, m_app_needs_ir);
  //kill current app
  [mp_task terminate];
  [pool release];
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
  FeedWatchDog *feed_watchdog = [[FeedWatchDog alloc] init]; 
  [NSTimer scheduledTimerWithTimeInterval:58.0 target:feed_watchdog selector:@selector(bone:) userInfo:nil repeats:YES]; 

  // setup our app listener which starts up Finder by default
  AppKeeper* appkeeper = [[AppKeeper alloc] init];

  // make a run loop and go
  NSRunLoop *theRL = [NSRunLoop currentRunLoop]; 
  while ([theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ; 
  
  [pool release];
  return EXIT_SUCCESS; 
}



