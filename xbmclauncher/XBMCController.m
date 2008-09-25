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

#import <BackRow/BackRow.h>
#import "XBMCController.h"
#import "XBMCDebugHelpers.h"
#import "xbmcclientwrapper.h"

@class BRLayerController;

@implementation XBMCController
- (id) init
{
	[self dealloc];
	@throw [NSException exceptionWithName:@"BNRBadInitCall" reason:@"Init XBMCController with initWithPath" userInfo:nil];
	return nil;
}

-(id) initWithPath:(NSString*) f_path
{
	PRINT_SIGNATURE();
	if ( ![super init] )
		return ( nil );
	mp_xbmclient = [[XBMCClientWrapper alloc] init];
	m_xbmc_running = NO;
	mp_app_path = f_path;
	[mp_app_path retain]; 
	//read preferences
	m_universal_remote = [[NSUserDefaults standardUserDefaults] boolForKey:XBMCEnableUniversalXBMCHelper];
	m_ir_control_type = [[NSUserDefaults standardUserDefaults] integerForKey:XBMCIRControlType];
	return self;
}

- (void)dealloc
{
	PRINT_SIGNATURE();
	[mp_xbmclient release];
	[mp_app_path release];
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
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerDisplayOnline"
																											object:[BRDisplayManager sharedInstance]];
	//remove our listener
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	if (! [mp_task isRunning])
	{
		ILOG(@"XBMC quit.");
		m_xbmc_running = NO;
		// Return code for XBMC
		int status = [[note object] terminationStatus];
		
		// release the old task, as a new one gets created (if
		[mp_task release];
		mp_task = nil;
		
		// Show frontrow menu 
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerResumeRenderingNotification"
																												object:[BRDisplayManager sharedInstance]];
		[[BRDisplayManager sharedInstance] captureAllDisplays];
		if (status != 0)
		{
			//now we need to kill XBMCHelper! (if its even running)
			//TODO for now we use a script as I don't know how to kill a Task with OSX API. any hints are pretty welcome!
			NSString* killer_path = [[NSBundle bundleForClass:[self class]] pathForResource:@"killxbmchelper" ofType:@"sh"];
			NSTask* killer = [NSTask launchedTaskWithLaunchPath:@"/bin/bash" arguments: [NSArray arrayWithObject:killer_path]];
			[killer waitUntilExit];
			BRAlertController* alert = [BRAlertController alertOfType:0 titled:nil
																										primaryText:[NSString stringWithFormat:@"Error: XBMC exited With Status: %i",status]
																									secondaryText:nil];
			[[self stack] swapController:alert];
		} else {
			[[self stack] popController];
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

- (void) wasPushed
{
	PRINT_SIGNATURE();
	[super wasPushed];

	//We've just been put on screen, the user can see this controller's content now	
	//Hide frontrow (this is only needed in 720/1080p
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerDisplayOffline"
																											object:[BRDisplayManager sharedInstance]];
	[[BRDisplayManager sharedInstance] releaseAllDisplays];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerStopRenderingNotification"
																											object:[BRDisplayManager sharedInstance]];
	//if enabled start our own instance of XBMCHelper
	if(m_ir_control_type == IR_INTERNAL_XBMCHELPER){
		DLOG(@"Using internal XBMCHelper...");
		NSString* xbmchelper_path = [[NSBundle bundleForClass:[self class]] pathForResource:@"XBMCHelper" ofType:@""];
		DLOG(@"... from %@ ...", xbmchelper_path);
		if(m_universal_remote){
			DLOG(@"... in universal mode");
			[NSTask launchedTaskWithLaunchPath:xbmchelper_path arguments: [NSArray arrayWithObject:@"-u"]];
		} else {
			DLOG(@"... in normal mode");
			[NSTask launchedTaskWithLaunchPath:xbmchelper_path arguments: [NSArray array]];
			}
	} else if( m_ir_control_type == IR_INTERNAL ){
		//TODO: how to we keep XBMC from launching its XBMCHelper?
		DLOG(@"Using internal IR mode");
	} else if( m_ir_control_type == IR_XBMC ){
		DLOG(@"Using XBMC IR mode");
	} else {
		ELOG(@"IR mode undefined. BUG!");
	}
	//start xbmc
	mp_task = [[NSTask alloc] init];
	@try {
		[mp_task setLaunchPath: mp_app_path];
		[mp_task setArguments:[NSArray arrayWithObject:@"-fs"]]; // fullscreen seems to be ignored...
		[mp_task launch];
	} 
	@catch (NSException* e) {
		// Show frontrow menu 
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerDisplayOnline"
																												object:[BRDisplayManager sharedInstance]];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerResumeRenderingNotification"
																												object:[BRDisplayManager sharedInstance]];
		[[BRDisplayManager sharedInstance] captureAllDisplays];
		[[BRDisplayManager sharedInstance] 	fadeInDisplay];
		BRAlertController* alert = [BRAlertController alertOfType:0 titled:nil
																									primaryText:[NSString stringWithFormat:@"Error: Cannot launch XBMC from path:"]
																									secondaryText:mp_app_path];
		[[self stack] swapController:alert];
	}
	m_xbmc_running = YES;
	//wait a bit for task to start
	NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.1];
	[NSThread sleepUntilDate:future];

	//attach our listener
	[[NSNotificationCenter defaultCenter] addObserver:self
																					 selector:@selector(checkTaskStatus:)
																							 name:NSTaskDidTerminateNotification
																						 object:mp_task];
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

- (BOOL)brEventAction:(BREvent *)event
{
	if( m_xbmc_running ){
		if( m_ir_control_type == IR_INTERNAL ) {
			unsigned int hashVal = [event pageUsageHash];
			DLOG(@"XBMCController: Button press hashVal = %i",hashVal);
			switch (hashVal)
			{
				case 65676:  // tap up
					if([event value] == 1)
						[mp_xbmclient handleEvent:ATV_BUTTON_UP_PRESS];
					else
						[mp_xbmclient handleEvent:ATV_BUTTON_UP_RELEASE];
					return YES;
				case 65677:  // tap down
					if([event value] == 1)
						[mp_xbmclient handleEvent:ATV_BUTTON_DOWN_PRESS];
					else
						[mp_xbmclient handleEvent:ATV_BUTTON_DOWN_RELEASE];
					return YES;
				case 65675:  // tap left
					[mp_xbmclient handleEvent:ATV_BUTTON_LEFT];
					return YES;
				case 65674:  // tap right
					[mp_xbmclient handleEvent:ATV_BUTTON_RIGHT];
					return YES;
				case 65673:  // tap play
					[mp_xbmclient handleEvent:ATV_BUTTON_PLAY];
					return YES;
				case 786611: //hold right
					[mp_xbmclient handleEvent:ATV_BUTTON_RIGHT_H];
					return YES;
				case 786612: //hold left
					[mp_xbmclient handleEvent:ATV_BUTTON_LEFT_H];
					return YES;
				case 65670: //menu
					[mp_xbmclient handleEvent:ATV_BUTTON_MENU];
					return YES;
				case 786496: //hold menu
					[mp_xbmclient handleEvent:ATV_BUTTON_MENU_H];
					return YES;
				default:
					ELOG(@"XBMCController: Unknown button press hashVal = %i",hashVal);
					return NO;
			}
		}	else {
			DLOG(@"Bypassing XBMCController internal IR");
			return NO;
		}
	} else {
		DLOG(@"XBMC not running. IR event goes upstairs");
		return [super brEventAction:event];
	}
}

@end
