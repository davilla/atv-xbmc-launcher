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
  
  //run the loop so stuff gets processed
  NSRunLoop *theRL = [NSRunLoop currentRunLoop]; 
  int i=10;
  while(--i) [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]]; 

  [pool release];
  return EXIT_SUCCESS; 
}



