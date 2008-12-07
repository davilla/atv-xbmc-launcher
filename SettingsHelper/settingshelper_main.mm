#include <stdio.h>
#include <stdlib.h>
#include <notify.h>

#import <Foundation/Foundation.h>

//--------------------------------------------------------------
@interface ATVSettingsHelper
+ (id)singleton;
- (BOOL)tellWatchdogWeAreUpAndRunning;
@end

//--------------------------------------------------------------
@interface ATVHardwareUtility
+ (id)singleton;
+ (void)turnOnWhiteLED;
+ (void)turnOffWhiteLED;
+ (void)blinkWhiteLED;
+ (void)turnOnAmberLED;
+ (void)turnOffAmberLED;
+ (void)blinkAmberLED;
+ (void)flushDiskChanges;
+ (void)turnOnDriveAcceleration;
+ (void)turnOffDriveAcceleration;
+(void)setLowPowerMode:(BOOL)fp8;
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
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // preamble (setup watchdog and default the LED to white)
  //NSLog(@"%@", [ATVSettingsHelper singleton]); 
  //TODO: check this! singleton returns nil, so the method isn't called
  // why does it?
  [[ATVSettingsHelper singleton] tellWatchdogWeAreUpAndRunning];
    
  NSLog(@"Setting white LED to ON");
  [ATVHardwareUtility setLowPowerMode: NO];
  [ATVHardwareUtility turnOnWhiteLED];
  
  // setup our NSTimers
  FeedWatchDog *feed_watchdog = [[[FeedWatchDog alloc] init] autorelease]; 
  [NSTimer scheduledTimerWithTimeInterval:58.0 target:feed_watchdog selector:@selector(bone:) userInfo:nil repeats:YES]; 

  // make a run loop and go
  NSRunLoop *theRL = [NSRunLoop currentRunLoop]; 
  while ([theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ; 
    
  [pool release];
  return EXIT_SUCCESS; 
}



