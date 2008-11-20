//
//  XBMCController.m
//  xbmclauncher
//
//  Created by Stephan Diederich on 13.09.08.
//  Copyright 2008 Stephan Diederich. All rights reserved.
/*
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "XBMCController.h"
#import <BackRow/BackRow.h>
#import <BackRowCompilerShutup.h>
#import "XBMCDebugHelpers.h"
#import "xbmcclientwrapper.h"

//activation sequence for Controller events (events which are not sent to controlled app, but are used in this controller, e.g. to kill the app)
const eATVClientEvent XBMC_CONTROLLER_EVENT_ACTIVATION_SEQUENCE[]={ATV_BUTTON_MENU, ATV_BUTTON_MENU, ATV_BUTTON_PLAY};
const double XBMC_CONTROLLER_EVENT_TIMEOUT= -0.5; //timeout for activation sequence in seconds

@class BRLayerController;

@interface XBMCController (private)

- (void) disableScreenSaver;
- (void) enableScreenSaver;

- (void) enableRendering;
- (void) disableRendering;

- (void) checkTaskStatus:(NSNotification *)note; //callback when App quit or crashed
- (BOOL) deleteHelperLaunchAgent;
- (void) setupHelperSwatter; //starts a NSTimer which callback periodically searches for a running mp_helper_path app and kills it
- (void) disableSwatterIfActive; //disables swatter and releases mp_swatter_timer
- (void) killHelperApp:(NSTimer*) f_timer; //kills a running instance of mp_helper_path application; f_timer can be nil, it's not used
- (void) startAppAndAttachListener;
- (void) setAppToFrontProcess;
@end

@implementation XBMCController

- (void) disableScreenSaver{
	PRINT_SIGNATURE();
	//store screen saver state and disable it
	//!!BRSettingsFacade setScreenSaverEnabled does change the plist, but does _not_ seem to work
	m_screen_saver_timeout = [[BRSettingsFacade singleton] screenSaverTimeout];
	[[BRSettingsFacade singleton] setScreenSaverTimeout:-1];
	[[BRSettingsFacade singleton] flushDiskChanges];
}

- (void) enableScreenSaver{
	PRINT_SIGNATURE();
	//reset screen saver to user settings
	[[BRSettingsFacade singleton] setScreenSaverTimeout: m_screen_saver_timeout];
	[[BRSettingsFacade singleton] flushDiskChanges];
}

- (void) enableRendering{
  //remove our observer
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerDisplayOnline"
																											object:[BRDisplayManager sharedInstance]];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerResumeRenderingNotification"
																											object:[BRDisplayManager sharedInstance]];
	[[BRDisplayManager sharedInstance] captureAllDisplays];	
}

- (void) disableRendering{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerDisplayOffline"
																											object:[BRDisplayManager sharedInstance]];
	[[BRDisplayManager sharedInstance] releaseAllDisplays];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerStopRenderingNotification"
																											object:[BRDisplayManager sharedInstance]];
}

- (void) setAppToFrontProcess{
  PRINT_SIGNATURE();
  assert(mp_task);
  ProcessSerialNumber psn;
  OSErr err;
  
  // loop until we find the process
  DLOG(@"Waiting to get process...");
  while([mp_task isRunning] && procNotFound == (err = GetProcessForPID([mp_task processIdentifier], &psn))) {
    // wait...
    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
  }
  
  if(err) {
    ELOG(@"Error getting PSN: %d", err);
  } else {
    DLOG(@"Waiting for process to be visible");
    // wait for it to be visible
    while([mp_task isRunning] && !IsProcessVisible(&psn)) {
      // do nothing!
      [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    }
    if( [mp_task isRunning] ){
      DLOG(@"Process is visible, making it front");
      SetFrontProcess(&psn);
    }
  }  
}

- (id) init
{
	[self dealloc];
	@throw [NSException exceptionWithName:@"BNRBadInitCall" reason:@"Init XBMCController with initWithPath" userInfo:nil];
	return nil;
}

- (id) initWithAppPath:(NSString*) f_app_path helperPath:(NSString*) f_helper_path lauchAgentFileName:(NSString*) f_lauch_agent_file_name {
	PRINT_SIGNATURE();
	if ( ![super init] )
		return ( nil );
  bool use_universal = [[XBMCUserDefaults defaults] boolForKey:XBMC_USE_UNIVERSAL_REMOTE];
	mp_xbmclient = [[XBMCClientWrapper alloc] initWithUniversalMode:use_universal serverAddress:@"localhost"];
	m_xbmc_running = NO;
	mp_app_path = [f_app_path retain];
	mp_helper_path = [f_helper_path retain];
	mp_launch_agent_file_name = [f_lauch_agent_file_name retain];
	mp_swatter_timer = nil;
	m_controller_event_state = CONTROLLER_EVENT_START_STATE;
	mp_controller_event_timestamp = nil; 
	return self;
}

- (void)dealloc
{
	PRINT_SIGNATURE();
	[self disableSwatterIfActive];
	[mp_xbmclient release];
	[mp_app_path release];
	[mp_helper_path release];
	[mp_launch_agent_file_name release];
	[mp_controller_event_timestamp release];
	[super dealloc];
}

- (void)controlWasActivated
{
	PRINT_SIGNATURE();
	[super controlWasActivated];
}

- (void)controlWasDeactivated
{
	PRINT_SIGNATURE();
	//gets called when powered down (long play)
	//TODO: Shutdown xbmc?
	[super controlWasDeactivated];
}

- (void)checkTaskStatus:(NSNotification *)note
{
	PRINT_SIGNATURE();
	[self enableRendering];
	
	//remove our listener
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	//delete a launchAgent if it's there
	[self deleteHelperLaunchAgent]; 
	//disable swatter 
	[self disableSwatterIfActive];
	//reenable screensaver
	[self enableScreenSaver];
	if (![mp_task isRunning])
	{
		ILOG(@"XBMC/Boxee quit.");
		m_xbmc_running = NO;
		// Return code for XBMC
		int status = [[note object] terminationStatus];
		
		// release the old task, as a new one gets created (if
		[mp_task release];
		mp_task = nil;
		
		//try to kill XBMCHelper (it does not hurt if it's not running, but definately helps if it still is
		[self killHelperApp:nil];
		
		// use exit status to decide what to do
    switch(status){
      case 0:
        [[self stack] popController];
        break;
      case 66:
        DLOG(@"XBMC wants us to restart ATV. Don't do this for now");
        [[self stack] popController];
        break;
      case 65:
        DLOG(@"XBMC wants to be restarted. Do that");
        [self startAppAndAttachListener];
        break;
      default:
      {
        BRAlertController* alert = [BRAlertController alertOfType:0 titled:nil
                                                      primaryText:[NSString stringWithFormat:@"Error: XBMC/Boxee exited with status: %i",status]
                                                    secondaryText:@"Hit menu to return"];
        [[self stack] swapController:alert];        
      }
    }
	} else {
		//Task is still running. How come?!
		ELOG(@"Task still running. This is definately a bug :/");
	}
} 

- (void) willBePushed
{
	// We're about to be placed on screen, but we're not yet there
	// always call super
	PRINT_SIGNATURE();
	[super willBePushed];
}

-(void) startAppAndAttachListener{
  PRINT_SIGNATURE();
	//Hide frontrow (this is only needed in 720/1080p)
	[self disableRendering];
	
	//delete a launchAgent if it's there
	[self deleteHelperLaunchAgent];
  
	//start xbmc
	mp_task = [[NSTask alloc] init];
	@try {
		[mp_task setLaunchPath: mp_app_path];
    [mp_task setCurrentDirectoryPath:@"/Applications"];
		[mp_task launch];
	} 
	@catch (NSException* e) {
		// Show frontrow menu 
		[self enableRendering];
		BRAlertController* alert = [BRAlertController alertOfType:0 titled:nil
																									primaryText:[NSString stringWithFormat:@"Error: Cannot launch XBMC/Boxee from path:"]
																								secondaryText:mp_app_path];
		[[self stack] swapController:alert];
    return;
	}
	m_xbmc_running = YES;
	//reenable screensaver
	[self disableScreenSaver];
	//wait a bit for task to start
	NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.1];
	[NSThread sleepUntilDate:future];
	
	//attach our listener
	[[NSNotificationCenter defaultCenter] addObserver:self
																					 selector:@selector(checkTaskStatus:)
																							 name:NSTaskDidTerminateNotification
																						 object:mp_task];
                                             
  // Bring XBMC to the front to capture keyboard input
  [self setAppToFrontProcess];
}

- (void) wasPushed{
	PRINT_SIGNATURE();
	[super wasPushed];
  //We've just been put on screen, the user can see this controller's content now	
  [self startAppAndAttachListener];
}

- (void) willBePopped
{
	// The user pressed Menu, but we've not been removed from the screen yet
	PRINT_SIGNATURE();
	// always call super
	[super willBePopped];
}

- (void) wasPopped
{
	// The user pressed Menu, removing us from the screen
	PRINT_SIGNATURE();
	// always call super
	[super wasPopped];
}

- (void) willBeBuried
{
	// The user just chose an option, and we will be taken off the screen
	PRINT_SIGNATURE();
	// always call super
	[super willBeBuried];
}

- (void) wasBuriedByPushingController: (BRLayerController *) controller
{
	// The user chose an option and this controller os no longer on screen
	PRINT_SIGNATURE();
	// always call super
	[super wasBuriedByPushingController: controller];
}

- (void) willBeExhumed
{
	// the user pressed Menu, but we've not been revealed yet
	PRINT_SIGNATURE();
	// always call super
	[super willBeExhumed];
}

- (void) wasExhumedByPoppingController: (BRLayerController *) controller
{
	// handle being revealed when the user presses Menu
	PRINT_SIGNATURE();
	// always call super
	[super wasExhumedByPoppingController: controller];
}

- (BOOL) recreateOnReselect
{ 
	return true;
}

- (BOOL) firstResponder{
	return TRUE;
}

-(void) handleControllerEvent:(eATVClientEvent) f_event{
  PRINT_SIGNATURE();
  switch (f_event){
    case ATV_BUTTON_PLAY:
      if([mp_task isRunning])
        [mp_task terminate];
      break;
    default:
      DLOG(@"Unknown controller event: %i", f_event);
  }
}

-(BOOL) isControllerEvent:(eATVClientEvent) f_event{
  switch(m_controller_event_state){
    case CONTROLLER_EVENT_START_STATE:
      if(f_event == XBMC_CONTROLLER_EVENT_ACTIVATION_SEQUENCE[0]){
        [mp_controller_event_timestamp release];
        mp_controller_event_timestamp = [[NSDate dateWithTimeIntervalSinceNow:0.] retain];
        m_controller_event_state = CONTROLLER_EVENT_STATE_1;
      }
      break;
    case CONTROLLER_EVENT_STATE_1:
      if(f_event == XBMC_CONTROLLER_EVENT_ACTIVATION_SEQUENCE[1] && [mp_controller_event_timestamp timeIntervalSinceNow] > XBMC_CONTROLLER_EVENT_TIMEOUT){
        [mp_controller_event_timestamp release];
        mp_controller_event_timestamp = [[NSDate dateWithTimeIntervalSinceNow:0.] retain];
        m_controller_event_state = CONTROLLER_EVENT_STATE_2;
      } else if(f_event == XBMC_CONTROLLER_EVENT_ACTIVATION_SEQUENCE[0]){
        [mp_controller_event_timestamp release];
        mp_controller_event_timestamp = [[NSDate dateWithTimeIntervalSinceNow:0.] retain];
        m_controller_event_state = CONTROLLER_EVENT_STATE_1;
      }
      else
        m_controller_event_state = CONTROLLER_EVENT_START_STATE;
      break;
    case CONTROLLER_EVENT_STATE_2:
      if(f_event == XBMC_CONTROLLER_EVENT_ACTIVATION_SEQUENCE[2] && [mp_controller_event_timestamp timeIntervalSinceNow] > XBMC_CONTROLLER_EVENT_TIMEOUT){
        ILOG(@"Recognized controller event. Next button press goes to XBMCController");
        m_controller_event_state = CONTROLLER_EVENT_STATE_3;
      }
      else if(f_event == XBMC_CONTROLLER_EVENT_ACTIVATION_SEQUENCE[0]){
        [mp_controller_event_timestamp release];
        mp_controller_event_timestamp = [[NSDate dateWithTimeIntervalSinceNow:0.] retain];
        m_controller_event_state = CONTROLLER_EVENT_STATE_1;
      } 
      else
        m_controller_event_state = CONTROLLER_EVENT_START_STATE;
      break;
    case CONTROLLER_EVENT_STATE_3:
        m_controller_event_state = CONTROLLER_EVENT_START_STATE;
        return true;
    default:
      ELOG(@"Something went wrong in controller event state machine. Resetting it...");
      m_controller_event_state = CONTROLLER_EVENT_START_STATE;
  }
  return false;
}

+ (eATVClientEvent) ATVClientEventFromBREvent:(BREvent*) f_event
{
  unsigned int hashVal = (uint32_t)([f_event page] << 16 | [f_event usage]);
  DLOG(@"XBMCController: Button press hashVal = %i; event value %i", hashVal, [f_event value]);
  switch (hashVal)
  {
    case 65676:  // tap up
      if([f_event value] == 1)
        return ATV_BUTTON_UP;
      else
        return ATV_BUTTON_UP_RELEASE;
      return YES;
    case 65677:  // tap down
      if([f_event value] == 1)
        return ATV_BUTTON_DOWN;
      else
        return ATV_BUTTON_DOWN_RELEASE;
      return YES;
    case 65675:  // tap left
      if([f_event value] == 1)
        return ATV_BUTTON_LEFT;
      else
        return ATV_BUTTON_LEFT_RELEASE;
      return YES;
    case 786612: // hold left (THIS EVENT IS ONLY PRESENT ON ATV <= 2.1)
      return ATV_BUTTON_LEFT_H;
      return YES;
    case 65674:  // tap right
      if([f_event value] == 1)
        return ATV_BUTTON_RIGHT;
      else
        return ATV_BUTTON_RIGHT_RELEASE;
      return YES;
    case 786611: // hold right (THIS EVENT IS ONLY PRESENT ON ATV <= 2.1)
      return ATV_BUTTON_RIGHT_H;
      return YES;
    case 65673:  // tap play
      return ATV_BUTTON_PLAY;
      return YES;
    case 65668:  // hold play  (THIS EVENT IS ONLY PRESENT ON ATV >= 2.2)
      return ATV_BUTTON_PLAY_H;
      return YES;
    case 65670:  // menu
      return ATV_BUTTON_MENU;
      return YES;
    case 786496: // hold menu
      return ATV_BUTTON_MENU_H;
    default:
      ELOG(@"XBMCController: Unknown button press hashVal = %i",hashVal);
      return ATV_INVALID_BUTTON;
  }
}

- (BOOL)brEventAction:(BREvent *)event
{
	if( m_xbmc_running ){
    eATVClientEvent xbmcclient_event = [XBMCController ATVClientEventFromBREvent:event];
    if( xbmcclient_event == ATV_INVALID_BUTTON ){
      return NO;
    } else if( [self isControllerEvent:xbmcclient_event] ){
      [self handleControllerEvent:xbmcclient_event];
      return TRUE;
    } else {
      [mp_xbmclient handleEvent:xbmcclient_event];
      return TRUE;
    }
	} else {
		DLOG(@"XBMC not running. IR event goes upstairs");
		return [super brEventAction:event];
	}
}

- (void) killHelperApp:(NSTimer*) f_timer{
  PRINT_SIGNATURE();
  DLOG(@"Trying to kill: %@", [mp_helper_path lastPathComponent]); 
	//TODO for now we use a script as I don't know how to kill a Task with OSX API. any hints are pretty welcome!
	NSString* killer_path = [[NSBundle bundleForClass:[self class]] pathForResource:@"killxbmchelper" ofType:@"sh"];
	NSTask* killer = [NSTask launchedTaskWithLaunchPath:@"/bin/bash" arguments: [NSArray arrayWithObjects
																																							 :killer_path,
																																							 [mp_helper_path lastPathComponent],
																																							 nil]];
	[killer waitUntilExit];
}

- (void) setupHelperSwatter{
	PRINT_SIGNATURE();
	[self disableSwatterIfActive];
	mp_swatter_timer = [NSTimer scheduledTimerWithTimeInterval:1. target:self selector:@selector(killHelperApp:) userInfo:nil repeats:YES];
	[mp_swatter_timer retain];
}

- (void) disableSwatterIfActive{
  PRINT_SIGNATURE();
	if(mp_swatter_timer){
		[mp_swatter_timer invalidate];
		[mp_swatter_timer release];
		mp_swatter_timer = nil;
	}
}

- (BOOL) deleteHelperLaunchAgent
{
  PRINT_SIGNATURE();
  if(mp_launch_agent_file_name) {
    NSArray* lib_array = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, TRUE);
    if([lib_array count] != 1){
      ELOG("Bah, something went wrong trying to find users Library directory");
      return FALSE;
    }
    NSString * launch_agent_file_path = [[lib_array objectAtIndex:0] stringByAppendingString:@"/LaunchAgents/"];
    launch_agent_file_path = [launch_agent_file_path stringByAppendingString:mp_launch_agent_file_name];
    DLOG(@"trying to delete LaunchAgent file at %@", launch_agent_file_path);
    if([[NSFileManager defaultManager] removeFileAtPath:launch_agent_file_path handler:nil]){
      ILOG(@"Deleted LaunchAgent file at %@", launch_agent_file_path);
      return TRUE;
    } else{
      DLOG(@"Failed to delete LaunchAgent file at %@", launch_agent_file_path);
      return FALSE;
    }
  } else {
    //no file given, just do nothing
    DLOG("No mp_launch_agent_file_name - don't try to delete it");
    return TRUE;
  }
}

@end
