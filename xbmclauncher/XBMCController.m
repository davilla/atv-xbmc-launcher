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
	m_enable_xbmcclient = NO;
	mp_xbmclient = [[XBMCClientWrapper alloc] init];
	mp_app_path=f_path;
	[mp_app_path retain]; 
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
	//reset stack, so stuff gets drawn
	[self setStack: mp_stack];
	if (! [task isRunning])
	{
		NSLog(@"task stopped! give back remote commands to Controller");
		m_enable_xbmcclient = NO;
		// Return code for XBMC
		int status = [[note object] terminationStatus];
		
		// release the old task, as a new one gets created (if
		[task release];
		task = nil;
		
		// Show frontrow menu 
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerResumeRenderingNotification"
																												object:[BRDisplayManager sharedInstance]];
		[[BRDisplayManager sharedInstance] captureAllDisplays];
		if (status != 0)
		{
			BRAlertController* alert = [BRAlertController alertOfType:0 titled:nil
																										primaryText:[NSString stringWithFormat:@"Error: XBMC exited With Status: %i",status]
																										secondaryText:nil];
			[[self stack] swapController:alert];
			//now we need to kill XBMCHelper! (if its even running)
			//TODO for now we use a script as I don't know how to kill a Task with OSX API. any hints are pretty welcome!
			NSString* killer_path = [[NSBundle bundleForClass:[self class]] pathForResource:@"killxbmchelper" ofType:@"sh"];
			NSTask* killer = [NSTask launchedTaskWithLaunchPath:@"/bin/bash" arguments: [NSArray arrayWithObject:killer_path]];
			[killer waitUntilExit];
		} else {
			[[self stack] popController];
		}
	} else {
		//Task is still running. How come?!
		NSLog(@"Task still running. This is definately a bug :/");
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
	[[BRDisplayManager sharedInstance] 	fadeOutDisplay];
	//We've just been put on screen, the user can see this controller's content now	
	//Hide frontrow menu this seems not to be needed for 2.1. XBMC is aggressive enough...
	//reenabled to test in 2.02
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerStopRenderingNotification"
																											object:[BRDisplayManager sharedInstance]];
	[[BRDisplayManager sharedInstance] releaseAllDisplays];
	//start xbmc
	task = [[NSTask alloc] init];
	@try {

//		[task setLaunchPath: @"/usr/bin/open"];
//		[task setArguments:[NSArray arrayWithObject:@"/Users/frontrow/Applications/XBMC.app"]];

		[task setLaunchPath: mp_app_path];
		[task setArguments:[NSArray arrayWithObject:@"-fs"]]; // fullscreen seems to be ignored...
		[task launch];
	} 
	@catch (NSException* e) {
		// Show frontrow menu 
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerResumeRenderingNotification"
																												object:[BRDisplayManager sharedInstance]];
		[[BRDisplayManager sharedInstance] captureAllDisplays];
		[[BRDisplayManager sharedInstance] 	fadeInDisplay];
		BRAlertController* alert = [BRAlertController alertOfType:0 titled:nil
																									primaryText:[NSString stringWithFormat:@"Error: Cannot launch XBMC. Path tried was:"]
																									secondaryText:mp_app_path];
		[[self stack] swapController:alert];
		return [super wasPushed];
	}

	//enable XBMC-Client
	m_enable_xbmcclient = YES;
	//wait a bit for task to start
	NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.1];
	[NSThread sleepUntilDate:future];

	//attach our listener
	[[NSNotificationCenter defaultCenter] addObserver:self
																					 selector:@selector(checkTaskStatus:)
																							 name:NSTaskDidTerminateNotification
																						 object:task];
	//save stack for later use:
	mp_stack = [self stack];
	//set stack to nil, so nothing gets drawn
	[self setStack: nil];
	// NEVER! call super this brings Frontrow back on screen
	//[super wasPushed];
}

- (void) willBePopped
{
	// The user pressed Menu, but we've not been removed from the screen yet
	PRINT_SIGNATURE();
	m_enable_xbmcclient = NO;
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

- (BOOL)brEventAction:(BREvent *)event
{
	if(m_enable_xbmcclient){
	/*
		if ([[self stack] peekController] != self){
			NSLog(@"Not on top of the stack, exiting...");
			return NO;
		}
	*/
		unsigned int hashVal = [event pageUsageHash];
		NSLog([NSString stringWithFormat:@"XBMCController: Button press hashVal = %i",hashVal]);
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
				NSLog([NSString stringWithFormat:@"XBMCController: Unknown button press hashVal = %i",hashVal]);
				return NO;
		}
	} else {
		NSLog(@"bypassing controller, give event upstairs...");
		return [super brEventAction:event];
	}
}

/*
 NSLog(@"NSApplication stuff");
 NSLog([NSString stringWithFormat: @"nsapp: %i", [NSApplication sharedApplication]] );
 NSLog([NSString stringWithFormat: @"shielded: %i", CGShieldingWindowID(CGMainDisplayID())]);
 NSLog([NSString stringWithFormat: @"is hidden: %i", [[NSApplication sharedApplication] isHidden]]);
 NSLog([NSString stringWithFormat: @"is runnning: %i", [[NSApplication sharedApplication] isRunning]]);
 NSLog([NSString stringWithFormat: @"keyWindow: %i", [[NSApplication sharedApplication] keyWindow]]);
 NSLog([NSString stringWithFormat: @"modalwindow: %i", [[NSApplication sharedApplication] modalWindow]]);
 NSLog([NSString stringWithFormat: @"windowsCount: %i", [[[NSApplication sharedApplication] windows] count]]);
 NSLog([NSString stringWithFormat: @"isactive: %i", [[NSApplication sharedApplication] isActive]]);
 NSLog(@"NSApplication mainwindow stuff");
 NSLog([NSString stringWithFormat: @"windowNumber: %i", [[[NSApplication sharedApplication] mainWindow] windowNumber]]);
 NSLog([NSString stringWithFormat: @"windowRef: %i", [[[NSApplication sharedApplication] mainWindow] windowRef]]);
 NSLog(@"BRRenderScene stuff");	
 NSLog([NSString stringWithFormat: @"BRRenderScene windowList: %i", [[BRRenderScene singleton] windowList]]);							
 NSLog([NSString stringWithFormat: @"BRRenderScene windowList size: %i", [[[BRRenderScene singleton] windowList] count]]);
 NSLog([NSString stringWithFormat: @"BRRenderScene opaque: %i", [[BRRenderScene singleton] opaque] ]);	
 NSLog([NSString stringWithFormat: @"BRRenderScene size x: %i", [[BRRenderScene singleton] size].width]);							
 NSLog([NSString stringWithFormat: @"BRRenderScene size y: %i", [[BRRenderScene singleton] size].height]);							
 NSLog(@"BRRenderScene window stuff");	
 BRWindow* win = [[[BRRenderScene singleton] windowList] objectAtIndex:0];
 NSLog([NSString stringWithFormat: @"isOpaque: %i", 	[win isOpaque]]);		
 NSLog([NSString stringWithFormat: @"acceptsFocus: %i", 	[win acceptsFocus]]);		
 NSLog([NSString stringWithFormat: @"level: %i", 	[win level]]);		
 [win setLevel:NSNormalWindowLevel];
 BRRenderScene* scene = [BRRenderScene singleton];
 [scene setOpaque:FALSE]; 
 [scene setBackgroundRemoved:TRUE];
 [scene setDrawableContext:nil];
*/
@end
