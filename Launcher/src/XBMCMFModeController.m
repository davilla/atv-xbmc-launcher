//
//  XBMCMFController.m
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

#import "XBMCMFModeController.h"
#import <BackRow/BackRow.h>
#import "helpers/BackRowCompilerShutup.h"
#import "XBMCDebugHelpers.h"
#import "atvxbmccommon.h"

@class BRLayerController;

@interface XBMCMFModeController (private)

- (void) deleteHelperLaunchAgent;
@end

@implementation XBMCMFModeController

- (id) init
{
	[self dealloc];
	@throw [NSException exceptionWithName:@"BNRBadInitCall" reason:@"Init XBMCController with initWithPath" userInfo:nil];
	return nil;
}

static const NSString * kXBMCHelperPath = @"helperpath";
static const NSString * kXBMCHelperLaunchAgentFileName = @"LaunchAgentFileName";

- (id) initWithAppPath:(NSString*) appPath
             arguments:(NSArray*) args
        userDictionary:(NSDictionary*) dict {  
	PRINT_SIGNATURE();
	if ( ![super init] )
		return ( nil );
	mp_app_path = [appPath retain];
  mp_args = [args retain];
  mp_launch_agent_file_name = [[dict objectForKey:kXBMCHelperLaunchAgentFileName] retain];
	return self;
}

- (void)dealloc
{
	PRINT_SIGNATURE();
	[mp_app_path release];
  [mp_args release];
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
	NSMutableDictionary* userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                                   mp_app_path, kApplicationPath,
                                   [NSNumber numberWithBool: TRUE], kApplicationNeedsIR, 
                                   [NSNumber numberWithBool: use_universal], kApplicationWantsUniversalIRMode, 
                                   nil];
  if(mp_args){
    [userInfo setObject:mp_args forKey:kApplicationArguments];
  }
	
	[[NSDistributedNotificationCenter defaultCenter] 
   postNotificationName: MULTIFINDER_START_APPLICATION_NOTIFICATION
   object: nil
   userInfo: userInfo
   options:NSNotificationDeliverImmediately | NSNotificationPostToAllSessions];
  //deliverImmediately: YES];	
  
  BRAlertController* alert = [BRAlertController alertOfType:0 titled:nil
                                                primaryText:[NSString stringWithFormat:@"Please wait for MultiFinder to launch app"]
                                              secondaryText:nil];
  [[self stack] swapController:alert];
}

- (BOOL) recreateOnReselect
{ 
	return true;
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
    DLOG(@"trying to delete LaunchAgent file at %@", launch_agent_file_path);
    if([[NSFileManager defaultManager] removeFileAtPath:launch_agent_file_path handler:nil]){
      ILOG(@"Deleted LaunchAgent file at %@", launch_agent_file_path);
    } else{
      DLOG(@"Failed to delete LaunchAgent file at %@", launch_agent_file_path);
    }
  } else {
    //no file given, just do nothing
    DLOG("No mp_launch_agent_file_name - don't try to delete it");
  }
  [pool release];
}

@end
