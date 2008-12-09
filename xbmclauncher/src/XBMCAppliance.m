//
//  XBMCAppliance.m
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

#import "XBMCAppliance.h"
#import <XBMCDebugHelpers.h>
#import <updater/XBMCUpdateController.h>
#import "XBMCController.h"
#import "XBMCPreferencesController.h"
#import "XBMCUserDefaults.h"

//enable this one to get notifications to BRDisplayManger logged
#define BRDISPLAY_MANAGER_OBSERVATION 1


@implementation XBMCAppliance

+ (void) initialize
{
	PRINT_SIGNATURE();
	Class cls = NSClassFromString( @"BRFeatureManager" );
	if ( cls == nil )
		return;
	[[cls sharedInstance] enableFeatureNamed: [[NSBundle bundleForClass: self] bundleIdentifier]];
	
	//create default settings
	NSMutableDictionary* defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:XBMC_USE_UNIVERSAL_REMOTE];
	
	//register dictionary defaults
	[[XBMCUserDefaults defaults] registerDefaults:defaultValues];
}

// Override to allow FrontRow to load custom appliance plugins
+ (NSString *) className {
	PRINT_SIGNATURE();
	// this function creates an NSString from the contents of the
	// struct objc_class, which means using this will not call this
	// function recursively, and it'll also return the *real* class
	// name.
	NSString * className = NSStringFromClass( self );
	
	// new method based on the BackRow NSException subclass, which conveniently provides us a backtrace
	// method!
	NSRange result = [[BRBacktracingException backtrace] rangeOfString:@"(in BackRow)"];
	
	if(result.location != NSNotFound) {
		DLOG(@"+[%@ className] called for whitelist check, so I'm lying, m'kay?", className);
		className = @"RUIDVDAppliance";
	}
	return className;
}

#ifdef BRDISPLAY_MANAGER_OBSERVATION
- (void) listen:(NSNotification*) note{
	DLOG(@"-------Logged %@", [note name]);
}
#endif

- (id) init
{
	if( ![super init] )
		return nil;
#ifdef BRDISPLAY_MANAGER_OBSERVATION
	[[NSNotificationCenter defaultCenter] addObserver:self
																					 selector:@selector(listen:)
																							 name:nil
																						 object:[BRDisplayManager sharedInstance]];
#endif
	return self;
}
- (void) dealloc
{
#ifdef BRDISPLAY_MANAGER_OBSERVATION
	[[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
	[super dealloc];
}

+ (BRAlertController*) getAboutController {
  NSNumber* version;
  NSDictionary* info_dic = [[NSBundle bundleForClass:self] infoDictionary];
  if(!info_dic)
    version = [NSNumber numberWithInt:-1];
  else
    version = [info_dic objectForKey:@"CFBundleVersion"];
	NSString* licence_string = @"This program is free software: you can redistribute it and/or modify\nit under the terms of the GNU General Public License as published by\nthe Free Software Foundation, either version 3 of the License, or\
(at your option) any later version.\
This program is distributed in the hope that it will be useful,\
but WITHOUT ANY WARRANTY; without even the implied warranty of\
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\
GNU General Public License for more details.\
You should have received a copy of the GNU General Public License\
along with this program. If not, see <http://www.gnu.org/licenses/>.";
	return [BRAlertController alertOfType:0 titled:@"About" 
                            primaryText:[NSString stringWithFormat:@"XBMCLauncher %@", version]
													secondaryText:[NSString stringWithFormat:@"Contributors: Scott Davilla / Stephan Diederich Copyright 2008 Team-XBMC\nsee http://atv-xbmc-launcher.googlecode.com or www.xbmc.org for details\n%@",licence_string
																				 ]];
	
}

- (id)controllerForIdentifier:(id)identifier {
	// find the proper entry in categories list from Info.plist
	NSEnumerator *enumerator = [[[self applianceInfo] applianceCategoryDescriptors] objectEnumerator];
	id obj = nil;
	while((obj = [enumerator nextObject]) != nil) {
		if ([identifier isEqualToString:[obj valueForKey:@"identifier"]]){
			break;
		}
	}
	NSNumber*	entry_type = [obj valueForKey:@"entry-type"];
	//entry type is the key if this is an XBMC.app entry or something else like updater, etc
	if( [entry_type isEqualToNumber:[NSNumber numberWithInt: APPLICATION]] ){
		//there can be more than one xbmc entry in the list, e.g. to test developer version etc.
		//so read the path of current and pass to controller
		NSString* appPath = [obj valueForKey:@"apppath"];
		NSString* helperPath = [obj valueForKey:@"helperpath"];
		NSString* launch_agent_file_name = [obj valueForKey:@"LaunchAgentFileName"];
		return [[[XBMCController alloc] initWithAppPath:appPath 
																				 helperPath:helperPath 
																 lauchAgentFileName:launch_agent_file_name 
						 ] autorelease];
	} 
	else if ( [entry_type isEqualToNumber:[NSNumber numberWithInt: UPDATER]] ){
		// here we want to use something like BRTextWithSpinnerController to get the update running
		NSURL* url = [NSURL URLWithString: [obj valueForKey:@"URL"]];
		return [[[XBMCUpdateController alloc] initWithURL:url] autorelease];
	} else if( [identifier isEqualToString:@"Settings"] ){
		return [[[XBMCPreferencesController alloc] init] autorelease];
	} else if( [identifier isEqualToString:@"About"] ){
		return [XBMCAppliance getAboutController];
	} else {
		return [BRAlertController alertOfType:0
																	 titled:@"XBMCLauncher"
															primaryText:@"Error"
														secondaryText:@"Unknown menu entry. This should definately NOT happen"];
	}
}

-(id)applianceCategories {
	NSMutableArray *categories = [NSMutableArray array];
	
	NSEnumerator *enumerator = [[[self applianceInfo] applianceCategoryDescriptors] objectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]) != nil) {
		BRApplianceCategory *category = [BRApplianceCategory categoryWithName:[obj valueForKey:@"name"] identifier:[obj valueForKey:@"identifier"] preferredOrder:[[obj valueForKey:@"preferred-order"] floatValue]];
		[categories addObject:category];
	}
	return categories;
}


@end
