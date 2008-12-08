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
+ (void)setLowPowerMode:(BOOL)fp8;
@end

//--------------------------------------------------------------
//--------------------------------------------------------------
int main(int argc, char *argv[])
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // tellWatchdogWeAreUpAndRunning which resets the boot count
  // Since Finder.app is not running yet (or might not be running)
  // we need to manually load AppleTV.frameworka and find ATVSettingsHelper.
  // Refs to pre r1.1 is included just in case we ever want to run under r1.0.
  NSBundle *appleTVFramework = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/AppleTV.framework"];
  if(appleTVFramework) {
    NSLog(@"Running on Apple TV 1.1+");
    [appleTVFramework load];
  } else {
    appleTVFramework = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/BackRow.framework"];
    if(appleTVFramework) {
      NSLog(@"Running on Apple TV 1.0");
      [appleTVFramework load];
    }
  }

  if(appleTVFramework) {
    id settingsHelper = nil;
    Class cls = nil;
    if(cls = NSClassFromString(@"ATVSettingsHelper")) {
      settingsHelper = [cls sharedInstance];
    } else if(cls = NSClassFromString(@"BRSettingsHelper")) {
      settingsHelper = [cls sharedInstance];
    } else {
      fprintf(stderr, "Can't find ATVSettingsHelper or BRSettingsHelper class, aborting.\n");
    }
    
    if(settingsHelper) {
      NSLog(@"tellWatchdogWeAreUpAndRunning");
      [settingsHelper tellWatchdogWeAreUpAndRunning];
    } else {
      fprintf(stderr, "Instance of settings helper class not found?!\n");
    }
  } else {
    fprintf(stderr, "Unable to load Apple TV frameworks.\n");
  }
    
  NSLog(@"Setting white LED to ON");
  [ATVHardwareUtility setLowPowerMode: NO];
  [ATVHardwareUtility turnOnWhiteLED];
  
  //run the loop so stuff gets processed
  NSRunLoop *theRL = [NSRunLoop currentRunLoop]; 
  int i=10;
  while(--i) [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]; 

  [pool release];
  
  return EXIT_SUCCESS; 
}



