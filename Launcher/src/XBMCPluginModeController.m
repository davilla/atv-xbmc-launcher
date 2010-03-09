//
//  XBMCPureController.m
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

#import "XBMCPluginModeController.h"
#import <BackRow/BackRow.h>
#import <OpenGL/OpenGL.h>

#import "helpers/BackRowCompilerShutup.h"
#import "common/XBMCDebugHelpers.h"
#import "common/xbmcclientwrapper.h"
#import "common/osdetection.h"
#import "ATV30Compatibility.h"

//activation sequence for Controller events (events which are not sent to controlled app, but are used in this controller, e.g. to kill the app)
const eATVClientEvent XBMC_CONTROLLER_EVENT_ACTIVATION_SEQUENCE[]={ATV_BUTTON_MENU, ATV_BUTTON_MENU, ATV_BUTTON_PLAY};
const double XBMC_CONTROLLER_EVENT_TIMEOUT= -0.5; //timeout for activation sequence in seconds

@interface XBMCPluginModeController (private)

- (void) checkTaskStatus:(NSNotification *)note; //callback when App quit or crashed
- (void) deleteHelperLaunchAgent;
- (void) setupHelperSwatter; //starts a NSTimer which callback periodically searches for a running mp_helper_path app and kills it
- (void) disableSwatterIfActive; //disables swatter and releases mp_swatter_timer
- (void) killHelperApp:(NSTimer*) f_timer; //kills a running instance of mp_helper_path application; f_timer can be nil, it's not used
- (void) startAppAndAttachListener;
- (void) setAppToFrontProcess;
@end

@implementation XBMCPluginModeController

static const NSString * kXBMCHelperPath = @"helperpath";
static const NSString * kXBMCHelperLaunchAgentFileName = @"LaunchAgentFileName";

- (id) initWithAppPath:(NSString*) appPath
             arguments:(NSArray*) args
        userDictionary:(NSDictionary*) userDictionary
{
	PRINT_SIGNATURE();
  
	if ( self = [super initWithAppPath:appPath arguments:args userDictionary:userDictionary] ) {
    bool use_universal = [[XBMCUserDefaults defaults] boolForKey:XBMC_USE_UNIVERSAL_REMOTE];
    mp_xbmclient = [[XBMCClientWrapper alloc] initWithUniversalMode:use_universal serverAddress:@"localhost"];
    m_xbmc_running = NO;
    mp_helper_path = [[userDictionary objectForKey:kXBMCHelperPath] retain];
    mp_launch_agent_file_name = [[userDictionary objectForKey:kXBMCHelperLaunchAgentFileName] retain];
    mp_swatter_timer = nil;
    m_controller_event_state = CONTROLLER_EVENT_START_STATE;
    mp_controller_event_timestamp = nil;     
  }
  return self;
}

- (void)dealloc
{
	PRINT_SIGNATURE();
	[self disableSwatterIfActive];
	[mp_xbmclient release];
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
	[super controlWasDeactivated];
  
  //delete a launchAgent if it's there
  [self deleteHelperLaunchAgent];
  //disable swatter
  [self disableSwatterIfActive];
}

- (void) applicationDidLaunch {
  m_xbmc_running = YES;
  
	//delete a launchAgent if it's there
	[self deleteHelperLaunchAgent];
}

- (void) applicationDidExitWithCode:(int)exitCode {
  m_xbmc_running = NO;
  //try to kill XBMCHelper (it does not hurt if it's not running, but definately helps if it still is
  [self killHelperApp:nil];
  // use exit status to decide what to do
  switch(exitCode){
    case 0:
      [[self stack] popController];
      break;
    case 65:
      DLOG(@"XBMC wants to be restarted. Do that");
      [self startAppAndAttachListener];
      break;
    case 66:
      DLOG(@"Reboot requested - XBMC should do that");
      [[self stack] popController];
      break;
    case 64:
      ILOG(@"Shutdown requested - XBMC should do that");
      [[self stack] popController];
      break;
    default:
    {
      BRAlertController* alert = [BRAlertController alertOfType:0 titled:nil
                                                    primaryText:[NSString stringWithFormat:@"Error: XBMC/Boxee exited with status: %i",exitCode]
                                                  secondaryText:@"Hit menu to return"];
      [[self stack] swapController:alert];        
    }
  }
}

-(void) handleControllerEvent:(eATVClientEvent) f_event{
  PRINT_SIGNATURE();
  switch (f_event){
    case ATV_BUTTON_PLAY:
      if([_task isRunning])
        [_task terminate];
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
        ILOG(@"Recognized controller event. Next button press goes to XBMCPureController");
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

/*
 //unused for now, just a reference and can't be used
 //like that as they change from release to release
 // see + (eATVClientEvent) ATVGestureFromBREvent:
 typedef enum {
 BR_REMOTE_ACTION_UNDEFINED = 0,
 BR_REMOTE_ACTION_MENU = 1,
 BR_REMOTE_ACTION_MENU_H = 2,
 BR_REMOTE_ACTION_UP = 3,
 BR_REMOTE_ACTION_DOWN = 4,
 BR_REMOTE_ACTION_PLAY = 5,
 BR_REMOTE_ACTION_LEFT = 6,
 BR_REMOTE_ACTION_RIGHT = 7,
 BR_REMOTE_ACTION_PLAY_H = 21,
 
 //generic touch events
 BR_REMOTE_ACTION_TOUCH_BEGIN = 29,
 BR_REMOTE_ACTION_TOUCH_MOVE = 30,
 BR_REMOTE_ACTION_TOUCH_END = 31,
 
 //already generated gestures
 BR_REMOTE_ACTION_SWIPE_LEFT = 32,
 BR_REMOTE_ACTION_SWIPE_RIGHT = 33,
 BR_REMOTE_ACTION_SWIPE_UP = 34,
 BR_REMOTE_ACTION_SWIPE_DOWN = 35,
 
 BR_REMOTE_ACTION_FLICK_LEFT = 36,
 BR_REMOTE_ACTION_FLICK_RIGHT = 37,
 
 //hm...
 BR_REMOTE_ACTION_FIGURE_ME_OUT2 = 38,
 BR_REMOTE_ACTION_FIGURE_ME_OUT3 = 45,
 } eBackRowRemoteAction;
 */

+ (eATVClientEvent) ATVGestureFromBREvent:(BREvent*) event {
  PRINT_SIGNATURE();
  static NSDictionary *gestureDict = nil;
  if(!gestureDict) {
    if(getOSVersion() < 300) {
      gestureDict = [[NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInt: ATV_BUTTON_MENU], [NSNumber numberWithInt: 1],
                      [NSNumber numberWithInt: ATV_BUTTON_PLAY], [NSNumber numberWithInt: 5],
                      [NSNumber numberWithInt: ATV_BUTTON_PLAY_H], [NSNumber numberWithInt: 20],
                      [NSNumber numberWithInt: ATV_GESTURE_SWIPE_LEFT], [NSNumber numberWithInt: 31],
                      [NSNumber numberWithInt: ATV_GESTURE_SWIPE_RIGHT], [NSNumber numberWithInt: 32],
                      [NSNumber numberWithInt: ATV_GESTURE_SWIPE_UP], [NSNumber numberWithInt: 33],
                      [NSNumber numberWithInt: ATV_GESTURE_SWIPE_DOWN], [NSNumber numberWithInt: 34],
                      nil] retain];
    } else {
      gestureDict = [[NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInt: ATV_BUTTON_MENU], [NSNumber numberWithInt: 1],
                      [NSNumber numberWithInt: ATV_BUTTON_PLAY], [NSNumber numberWithInt: 5],
                      [NSNumber numberWithInt: ATV_BUTTON_PLAY_H], [NSNumber numberWithInt: 21],
                      [NSNumber numberWithInt: ATV_GESTURE_SWIPE_LEFT], [NSNumber numberWithInt: 32],
                      [NSNumber numberWithInt: ATV_GESTURE_SWIPE_RIGHT], [NSNumber numberWithInt: 33],
                      [NSNumber numberWithInt: ATV_GESTURE_SWIPE_UP], [NSNumber numberWithInt: 34],
                      [NSNumber numberWithInt: ATV_GESTURE_SWIPE_DOWN], [NSNumber numberWithInt: 35],
                      nil] retain];
    }
  }
  NSNumber * atv_client_event = [gestureDict objectForKey:[NSNumber numberWithInt:[event remoteAction]]];
  if(atv_client_event != nil)
    return [atv_client_event intValue];
  else
    return ATV_INVALID_BUTTON;
}

+ (eATVClientEvent) ATVClientEventFromBREvent:(BREvent*) f_event
{
  BOOL downEvent = [f_event value];
  int action = [f_event remoteAction];
  DLOG(@"got action %i %@", action, (downEvent)? @"pressed":@"released");
  
  //new button handling; needed for iPhone Remote gestures
  if(! [f_event respondsToSelector:@selector(page)]) {
    //    DLOG(@"got iPhone remote event");
    //fire only on downEvents for now
    //BackRow filters them nicely
    if(downEvent)
      return [XBMCPluginModeController ATVGestureFromBREvent:f_event];
    else
      return ATV_INVALID_BUTTON;
  }
  //old legacy handling. fix me!
  unsigned int hashVal = (uint32_t)([f_event page] << 16 | [f_event usage]);
  //  DLOG(@"XBMCPureController: Button press hashVal = %i; event value %i", hashVal, [f_event value]);
  switch (hashVal)
  {
    case 65676:  // tap up
      if([f_event value] == 1)
        return ATV_BUTTON_UP;
      else
        return ATV_BUTTON_UP_RELEASE;
    case 65677:  // tap down
      if([f_event value] == 1)
        return ATV_BUTTON_DOWN;
      else
        return ATV_BUTTON_DOWN_RELEASE;
    case 65675:  // tap left
      if([f_event value] == 1)
        return ATV_BUTTON_LEFT;
      else
        return ATV_BUTTON_LEFT_RELEASE;
    case 786612: // hold left (THIS EVENT IS ONLY PRESENT ON ATV <= 2.1) and came back with 2.3 as rewind
      if(getOSVersion() < 230)
        return ATV_BUTTON_LEFT_H;
      else
      {
        if([f_event value] == 1)
          return ATV_LEARNED_REWIND;
        else
          return ATV_LEARNED_REWIND_RELEASE;
      }
    case 65674:  // tap right
      if([f_event value] == 1)
        return ATV_BUTTON_RIGHT;
      else
        return ATV_BUTTON_RIGHT_RELEASE;
    case 786611: // hold right (THIS EVENT IS ONLY PRESENT ON ATV <= 2.1) and came back with 2.3 as forward
      if(getOSVersion() < 230)
        return ATV_BUTTON_RIGHT_H;
      else
      {
        if([f_event value] == 1)
          return ATV_LEARNED_FORWARD;
        else
          return ATV_LEARNED_FORWARD_RELEASE;
      }
    case 65673:  // tap play
      return ATV_BUTTON_PLAY;
    case 65668:  // hold play  (THIS EVENT IS ONLY PRESENT ON ATV >= 2.2)
      return ATV_BUTTON_PLAY_H;
    case 65670:  // menu
      return ATV_BUTTON_MENU;
    case 786496: // hold menu
      return ATV_BUTTON_MENU_H;
    case 786608: //learned play
      return ATV_LEARNED_PLAY;
    case 786609: //learned pause
      return ATV_LEARNED_PAUSE;
    case 786615: //learned stop
      return ATV_LEARNED_STOP;
    case 786613: //learned nexxt
      return ATV_LEARNED_NEXT;
    case 786614: //learned previous
      return ATV_LEARNED_PREVIOUS;
    case 786630: //learned enter, like go into something
      return ATV_LEARNED_ENTER;
    case 786631: //learned return, like go back
      return ATV_LEARNED_RETURN;
    case 786637:
      return ATV_ALUMINIUM_PLAY;
    default:
      ELOG(@"XBMCPureController: Unknown button press hashVal = %i",hashVal);
      return ATV_INVALID_BUTTON;
  }
}

- (BOOL)brEventAction:(BREvent *)event
{
	if( m_xbmc_running ){
    eATVClientEvent xbmcclient_event = [[self class] ATVClientEventFromBREvent:event];
    
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
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  DLOG(@"Trying to kill: %@", [mp_helper_path lastPathComponent]); 
	//TODO for now we use a script as I don't know how to kill a Task with OSX API. any hints are pretty welcome!
	NSString* killer_path = [[NSBundle bundleForClass:[self class]] pathForResource:@"killxbmchelper" ofType:@"sh"];
	NSTask* killer = [NSTask launchedTaskWithLaunchPath:@"/bin/bash" arguments: [NSArray arrayWithObjects
                                                                               :killer_path,
                                                                               [mp_helper_path lastPathComponent],
                                                                               nil]];
	[killer waitUntilExit];
  [pool release];
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

- (void) deleteHelperLaunchAgent
{
  PRINT_SIGNATURE();
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  if(mp_launch_agent_file_name) {
    NSArray* lib_array = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, TRUE);
    if([lib_array count] != 1){
      ELOG("Bah, something went wrong trying to find users Library directory");
      return;
    }
    NSString * launch_agent_file_path = [[lib_array objectAtIndex:0] stringByAppendingString:@"/LaunchAgents/"];
    launch_agent_file_path = [launch_agent_file_path stringByAppendingString:mp_launch_agent_file_name];
    if([[NSFileManager defaultManager] removeFileAtPath:launch_agent_file_path handler:nil]){
      ILOG(@"Deleted LaunchAgent file at %@", launch_agent_file_path);
    } else{
      DLOG(@"Failed to delete/No LaunchAgent file at %@", launch_agent_file_path);
    }
  } else {
    //no file given, just do nothing
    DLOG("No mp_launch_agent_file_name - don't try to delete it");
  }
  [pool release];
}

@end
