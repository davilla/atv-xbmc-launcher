//
//  GenericPluginModeController.m
//  atv-xbmc-tools
//
//  Created by Stephan Diederich on 08.03.10.
//  Copyright 2010 Stephan Diederich. All rights reserved.
//

#import "GenericPluginModeController.h"
#import "BackRowCompilerShutup.h"
#import "ATV30Compatibility.h"
#import "XBMCDebugHelpers.h"

//temp storage for renderer while XBMC is running
static CARenderer* s_renderer;

@class BRLayerController;

@implementation GenericPluginModeController

- (id) init
{
	[self dealloc];
	@throw [NSException exceptionWithName:@"BNRBadInitCall" reason:@"Init GenericPluginModeController with initWithPath" userInfo:nil];
	return nil;
}

- (id) initWithAppPath:(NSString *) appPath
             arguments:(NSArray *)  args 
        userDictionary:(NSDictionary *) userDictionary {
  if ( self = [super init] ) {
    _applicationPath = [appPath retain];
    _args = [args retain];
    _userInfo = [userDictionary retain];
  }
  return self;
}

- (void) dealloc {
  [_applicationPath release];
  [_args release];
  [_userInfo release];
  
  [super dealloc];
}

#pragma mark -
#pragma mark stack methods
- (void) controlWasActivated {
  [super controlWasActivated];
  [self disableScreenSaver];
  [self disableRendering];
  [self startAppAndAttachListener];
}

- (void) controlWasDeactivated {
  [super controlWasDeactivated];
	if([_task isRunning]) {
    //remove our listener, so the other cleanup isn't called
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_task interrupt];
    [_task waitUntilExit];
    //wait a bit to recover
    NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 1.];
    [NSThread sleepUntilDate:future];
  }
  [self enableRendering];
  [self enableScreenSaver];
}

- (BOOL) recreateOnReselect
{ 
	return YES;
}

#pragma mark -
#pragma mark IR handler
- (BOOL)brEventAction:(BREvent *)event
{
	if( [_task isRunning] ){
    [_task terminate];
	} else {
		DLOG(@"App not running - IR event goes upstairs");
		return [super brEventAction:event];
	}
}

#pragma mark -
#pragma mark helper methods
- (void) disableScreenSaver{
	PRINT_SIGNATURE();
	//store screen saver state and disable it
	//!!BRSettingsFacade setScreenSaverEnabled does change the plist, but does _not_ seem to work
	_screensaverTimeout = [[BRSettingsFacade singleton] screenSaverTimeout];
	[[BRSettingsFacade singleton] setScreenSaverTimeout:-1];
	[[BRSettingsFacade singleton] flushDiskChanges];
}

- (void) enableScreenSaver{
	PRINT_SIGNATURE();
	//reset screen saver to user settings
	[[BRSettingsFacade singleton] setScreenSaverTimeout: _screensaverTimeout];
	[[BRSettingsFacade singleton] flushDiskChanges];
}


- (void) enableRendering{
  PRINT_SIGNATURE();
  BRDisplayManager *displayManager = [BRDisplayManager sharedInstance];
  if(getOSVersion() < 230){
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerDisplayOnline"
                                                        object:displayManager ];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerResumeRenderingNotification"
                                                        object:displayManager ];
    [displayManager captureAllDisplays];
  } else if (getOSVersion() < 300) {
    [displayManager _setNewDisplay:kCGDirectMainDisplay];
    [displayManager captureAllDisplays];
  } else {
    BRRenderer *theRender = [BRRenderer singleton];
    //restore the renderer
    [theRender setRenderer:s_renderer];
    [displayManager captureAllDisplays];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerConfigurationEnd" object: [BRDisplayManager sharedInstance]];
  }
}

- (void) disableRendering{
  PRINT_SIGNATURE();
  BRDisplayManager *displayManager = [BRDisplayManager sharedInstance];
  if(getOSVersion() < 230) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerDisplayOffline"
                                                        object:displayManager ];
    [[BRDisplayManager sharedInstance] releaseAllDisplays];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerStopRenderingNotification"
                                                        object:displayManager ];
  } else if (getOSVersion() < 300) {
    [displayManager _setNewDisplay:kCGNullDirectDisplay];
    [displayManager releaseAllDisplays];
  } else {
    //ATV 3.0 and up
    [displayManager releaseAllDisplays];
    //grab the context and release it
    BRRenderer *theRender = [BRRenderer singleton];
    //we need to replace the CARenderer in BRRenderer or Finder crashes in its RenderThread
    //save it so it can be restored later
    s_renderer = [theRender renderer];
    [theRender setRenderer:nil];
    //this enables XBMC to run as a proper fullscreen app (otherwise we get an invalid drawable)
    CGLContextObj ctx = [[theRender context] CGLContext];
    CGLClearDrawable( ctx );
  }
}

- (void) setAppToFrontProcess {
  PRINT_SIGNATURE();
  assert(_task);
  ProcessSerialNumber psn;
  OSErr err = 0;
  
  // loop until we find the process
  DLOG(@"Waiting to get process...");
  while([_task isRunning] && procNotFound == (err = GetProcessForPID([_task processIdentifier], &psn))) {
    // wait...
    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
  }
  
  if(err) {
    ELOG(@"Error getting PSN: %d", err);
  } else {
    DLOG(@"Waiting for process to be visible");
    // wait for it to be visible
    while([_task isRunning] && !IsProcessVisible(&psn)) {
      // do nothing!
      [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }
    if( [_task isRunning] ){
      DLOG(@"Process is visible, making it front");
      SetFrontProcess(&psn);
    }
  }  
}

#pragma mark -
#pragma mark App launch and exit
-(void) startAppAndAttachListener{
  PRINT_SIGNATURE();	
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  //Hide frontrow (this is only needed in 720/1080p)
	[self disableRendering];
    
	//start xbmc
	_task = [[NSTask alloc] init];
	@try {
    [_task setLaunchPath: _applicationPath];
    [_task setCurrentDirectoryPath:@"/Applications"];
    if(_args) //optional argument
      [_task setArguments:_args];
    [_task launch];
	} 
	@catch (NSException* e) {
		// Show frontrow menu 
		[self enableRendering];
		BRAlertController* alert = [BRAlertController alertOfType:0 titled:nil
                                                  primaryText:[NSString stringWithFormat:@"Error: Cannot launch application from path:"]
                                                secondaryText:_applicationPath];
		[[self stack] swapController:alert];
    [pool release];
    return;
	}

	[self disableScreenSaver];
	//wait a bit for task to start
	NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.1];
	[NSThread sleepUntilDate:future];
	
	//attach our listener
	[[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(checkTaskStatus:)
                                               name:NSTaskDidTerminateNotification
                                             object:_task];
  
  // Bring XBMC to the front to capture keyboard input
  [self setAppToFrontProcess];
  [self applicationDidLaunch];
  [pool release];
}

- (void)checkTaskStatus:(NSNotification *)note
{
	PRINT_SIGNATURE();
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	[self enableRendering];
	
	//remove our listener
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	//reenable screensaver
	[self enableScreenSaver];
	if (![_task isRunning])
	{
		ILOG(@"Application did exit.");
		// Return code for application
		int status = [[note object] terminationStatus];
		
		// release the old task, as a new one gets created
		[_task release];
		_task = nil;
    [self applicationDidExitWithCode:status];
	} else {
		//Task is still running. How come?!
		ELOG(@"Task still running. This is definately a bug :/");
	}
  [pool release];
  
}

- (void) applicationDidLaunch {
  //does nothing by default
}

- (void) applicationDidExitWithCode:(int) exitCode {
  //pops this controller by default
  [[self stack] popController];
}

@end
