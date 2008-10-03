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
#import <BackRowCompilerShutup.h>

@class BRLayerController;

@interface XBMCController (private)

- (void) disableScreenSaver;
- (void) enableScreenSaver;

- (void) enableRendering;
- (void) disableRendering;

- (void) checkTaskStatus:(NSNotification *)note; //callback when XBMC quit or crashed
- (BOOL) setDesiredAppleRemoteMode; //sets appleremoteMode to 0,1 or 2 depeding on m_use_internal_ir and XBMC_USE_UNIVERSAL_REMOTE
- (BOOL) inUserSettingsSetXpath:(NSString*) f_xpath toInt:(int) f_value;
- (BOOL) deleteHelperLaunchAgent;
- (void) setupHelperSwatter; //starts a NSTimer which callback periodically searches for a running mp_helper_path app and kills it
- (void) disableSwatterIfActive; //disables swatter and releases mp_swatter_timer
- (void) killHelperApp:(NSTimer*) f_timer; //kills a running instance of mp_helper_path application; f_timer can be nil, it's not used

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

- (id) init
{
	[self dealloc];
	@throw [NSException exceptionWithName:@"BNRBadInitCall" reason:@"Init XBMCController with initWithPath" userInfo:nil];
	return nil;
}
- (id) initWithAppPath:(NSString*) f_app_path helperPath:(NSString*) f_helper_path lauchAgentFileName:(NSString*) f_lauch_agent_file_name guiSettingsPath:(NSString*) f_guisettings_path{
	PRINT_SIGNATURE();
	if ( ![super init] )
		return ( nil );
	mp_xbmclient = [[XBMCClientWrapper alloc] init];
	m_xbmc_running = NO;
	mp_app_path = [f_app_path retain];
	mp_helper_path = [f_helper_path retain];
	mp_launch_agent_file_name = [f_lauch_agent_file_name retain];
	mp_guisettings_path = [f_guisettings_path retain];
	mp_swatter_timer = nil;
	//read preferences
	m_use_internal_ir = [[XBMCUserDefaults defaults] boolForKey:XBMC_USE_INTERNAL_IR];
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
	[mp_guisettings_path release];
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
		
		//again try to set xbmchelper status what we want to have (in case it was changed during this session)
		[self setDesiredAppleRemoteMode];
		//try to kill XBMCHelper (it does not hurt if it's not running, but definately helps if it still is
		[self killHelperApp:nil];
		
		// Show frontrow menu 
		if (status != 0)
		{
			BRAlertController* alert = [BRAlertController alertOfType:0 titled:nil
																										primaryText:[NSString stringWithFormat:@"Error: XBMC/Boxee exited With Status: %i",status]
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

- (BOOL) inUserSettingsSetXpath:(NSString*) f_xpath toInt:(int) f_value{
	PRINT_SIGNATURE();
	//assemble path to guisettings.xml
	NSArray* app_support_path_array = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, TRUE);
	if([app_support_path_array count] != 1){
		ELOG(@"Huh? No application support directory?");
		return FALSE;
	}
	NSString* guisettings_path = [[app_support_path_array objectAtIndex:0] stringByAppendingString:mp_guisettings_path];
	
	NSError *err=nil;
	NSURL *furl = [NSURL fileURLWithPath:guisettings_path];
	if (!furl) {
		ELOG(@"Can't create an URL from file %@.", guisettings_path);
		return FALSE;
	}
	NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:furl
																								options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)
																									error:&err];
	//TODO checkme. is this a proper solution for not writing release in all the return paths below?
	[xmlDoc autorelease];
	if (xmlDoc == nil || err)  {
		if (err) {
			ELOG(@"Erred opening guisettings.xml %@", err);
		}
		return FALSE;
	}
	//get the key of mode in settings/appleremote/
	err = nil;
	NSArray *nodes = [xmlDoc nodesForXPath:f_xpath error:&err];
	if (err != nil || [nodes count] != 1 ) {
		ELOG(@"Did NOT find %@ in %@. Error was %@", f_xpath, guisettings_path, err);
		return FALSE;
	}
	//compare mode to target_mode
	NSString* target_format_string = [NSString stringWithFormat:@"%i",f_value];
	NSXMLElement*	mode = [nodes objectAtIndex:0];
	if( [[mode stringValue] isEqualTo:target_format_string] ){  
		DLOG(@"%@ already set to: %@",f_xpath, [mode stringValue]); 
		return TRUE;
	}
	//set mode to target_mode
	[mode setStringValue:target_format_string];		
	//write back data
	NSData* xmlData = [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
	if (![xmlData writeToFile:guisettings_path atomically:YES]) {
		ELOG(@"Could not write guisettings back to %@", guisettings_path);
		return FALSE;
	}
	DLOG(@"Wrote %i to into %@ at path %@", f_value, guisettings_path, f_xpath);
	return TRUE;
}

- (void) wasPushed{
	PRINT_SIGNATURE();
	[super wasPushed];

	//We've just been put on screen, the user can see this controller's content now	
	//Hide frontrow (this is only needed in 720/1080p)
	[self disableRendering];
	
	//delete a launchAgent if it's there
	[self deleteHelperLaunchAgent];
	//if enabled start our own instance of XBMCHelper
	if( m_use_internal_ir ){
		//try to disable xbmchelper in guisettings.xml
		bool worked = [self setDesiredAppleRemoteMode];
		//if it did not work, set up a fly-swatter
		if(!worked)
			[self setupHelperSwatter];
	} else {
		[self setDesiredAppleRemoteMode];
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
		[self enableRendering];
		[[BRDisplayManager sharedInstance] 	fadeInDisplay];
		BRAlertController* alert = [BRAlertController alertOfType:0 titled:nil
																									primaryText:[NSString stringWithFormat:@"Error: Cannot launch XBMC/Boxee from path:"]
																									secondaryText:mp_app_path];
		[[self stack] swapController:alert];
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
		unsigned int hashVal = (uint32_t)([event page] << 16 | [event usage]);
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
	} else {
		DLOG(@"XBMC not running. IR event goes upstairs");
		return [super brEventAction:event];
	}
}

- (void) killHelperApp:(NSTimer*) f_timer{
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
	if(mp_swatter_timer){
		[mp_swatter_timer invalidate];
		[mp_swatter_timer release];
		mp_swatter_timer = nil;
	}
}

- (BOOL) setDesiredAppleRemoteMode
{
	if( m_use_internal_ir ){
		return [self inUserSettingsSetXpath:@"./settings/appleremote/mode" toInt:0];
	} else {
		//check if universal remote is on
		if ([[XBMCUserDefaults defaults] boolForKey:XBMC_USE_UNIVERSAL_REMOTE])
			return [self inUserSettingsSetXpath:@"./settings/appleremote/mode" toInt:2];
		else
			return [self inUserSettingsSetXpath:@"./settings/appleremote/mode" toInt:1];
	}
}

- (BOOL) deleteHelperLaunchAgent
{
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
}

@end
