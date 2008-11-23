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
#import "atvxbmccommon.h"
//activation sequence for Controller events (events which are not sent to controlled app, but are used in this controller, e.g. to kill the app)
const eATVClientEvent XBMC_CONTROLLER_EVENT_ACTIVATION_SEQUENCE[]={ATV_BUTTON_MENU, ATV_BUTTON_MENU, ATV_BUTTON_PLAY};
const double XBMC_CONTROLLER_EVENT_TIMEOUT= -0.5; //timeout for activation sequence in seconds

@class BRLayerController;

@interface XBMCController (private)

- (BOOL) deleteHelperLaunchAgent;
@end

@implementation XBMCController

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
	mp_app_path = [f_app_path retain];
	mp_launch_agent_file_name = [f_lauch_agent_file_name retain];
	return self;
}

- (void)dealloc
{
	PRINT_SIGNATURE();
	[mp_app_path release];
	[mp_launch_agent_file_name release];
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

- (void) wasPushed{
	PRINT_SIGNATURE();
	[super wasPushed];
  //We've just been put on screen, the user can see this controller's content now	
  PRINT_SIGNATURE();	
  bool use_universal = [[XBMCUserDefaults defaults] boolForKey:XBMC_USE_UNIVERSAL_REMOTE];
  //just send a notification to MultiFinder and let it do the rest
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys: 
                            mp_app_path, kApplicationPath,
                            [NSNumber numberWithBool: TRUE], kApplicationNeedsIR, 
                            [NSNumber numberWithBool: use_universal], kApplicationWantsUniversalIRMode, 
                            nil];
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:MULTIFINDER_START_APPLICATION_NOTIFICATION
                                                                 object:nil
                                                               userInfo:userInfo
                                                     deliverImmediately:YES];	
  BRAlertController* alert = [BRAlertController alertOfType:0 titled:nil
                                                primaryText:[NSString stringWithFormat:@"Please wait for MultiLauncher to start app"]
                                              secondaryText:nil];
  [[self stack] swapController:alert];
}

- (BOOL) recreateOnReselect
{ 
	return true;
}

- (BOOL) deleteHelperLaunchAgent
{
  PRINT_SIGNATURE();
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  bool ret;
  if(mp_launch_agent_file_name) {
    NSArray* lib_array = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, TRUE);
    if([lib_array count] != 1){
      ELOG("Bah, something went wrong trying to find users Library directory");
      ret = FALSE;
    }
    NSString * launch_agent_file_path = [[lib_array objectAtIndex:0] stringByAppendingString:@"/LaunchAgents/"];
    launch_agent_file_path = [launch_agent_file_path stringByAppendingString:mp_launch_agent_file_name];
    DLOG(@"trying to delete LaunchAgent file at %@", launch_agent_file_path);
    if([[NSFileManager defaultManager] removeFileAtPath:launch_agent_file_path handler:nil]){
      ILOG(@"Deleted LaunchAgent file at %@", launch_agent_file_path);
      ret = TRUE;
    } else{
      DLOG(@"Failed to delete LaunchAgent file at %@", launch_agent_file_path);
      ret = FALSE;
    }
  } else {
    //no file given, just do nothing
    DLOG("No mp_launch_agent_file_name - don't try to delete it");
    ret = TRUE;
  }
  [pool release];
  return ret;
}

@end
