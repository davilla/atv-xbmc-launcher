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
#import "common/XBMCDebugHelpers.h"
#import "updater/XBMCUpdateController.h"
#import "XBMCMFController.h"
#import "XBMCPureController.h"
#import "XBMCPreferencesController.h"
#import "XBMCUserDefaults.h"

//enable this one to get notifications to BRDisplayManger logged
#define BRDISPLAY_MANAGER_OBSERVATION 1

//static XBMCAppliance variable to store mode we're running in
static bool g_multifinder_mode = false;

@implementation XBMCAppliance

//tries to extract version from bundle and returns it
+ (NSNumber * ) LauncherVersion
{
  NSNumber* version;
  NSDictionary* info_dic = [[NSBundle bundleForClass:self] infoDictionary];
  if(!info_dic)
    version = [NSNumber numberWithInt:-1];
  else
    version = [info_dic objectForKey:@"CFBundleVersion"];
  return version;
}

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
    [defaultValues setValue:[NSNumber numberWithBool:NO] forKey:XBMC_EXPERT_MODE];
  
	//register dictionary defaults
	[[XBMCUserDefaults defaults] registerDefaults:defaultValues];

    //check which mode we're running in
    NSWorkspace * ws = [NSWorkspace sharedWorkspace];
    NSArray * apps = [ws valueForKeyPath:@"launchedApplications.NSApplicationName"];
    g_multifinder_mode = [apps containsObject:@"MultiFinder"]; 
  NSString *startupOutput;
  if(g_multifinder_mode)
    startupOutput = [NSString stringWithFormat:@"Launcher %@ running in MultiFinder mode", [[self class] LauncherVersion]];
  else
    startupOutput = [NSString stringWithFormat:@"Launcher %@ running in pure mode", [[self class] LauncherVersion]];
  NSLog(@"%@", startupOutput);
    
}

// Override to allow FrontRow to load custom appliance plugins
+ (NSString *) className {
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
		className = @"MOVAppliance";
	}
	return className;
}

+ (bool) inMultiFinderMode {
    return g_multifinder_mode;
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
	NSString* licence_string = @"This program is free software: you can redistribute it and/or modify\nit under the terms of the GNU General Public License as published by\nthe Free Software Foundation, either version 3 of the License, or\
(at your option) any later version.\
This program is distributed in the hope that it will be useful,\
but WITHOUT ANY WARRANTY; without even the implied warranty of\
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the\
GNU General Public License for more details.\
You should have received a copy of the GNU General Public License\
along with this program. If not, see <http://www.gnu.org/licenses/>.";
	return [BRAlertController alertOfType:0 titled:@"About" 
                            primaryText:[NSString stringWithFormat:@"Launcher %@", [[self class] LauncherVersion]]
													secondaryText:[NSString stringWithFormat:@"Contributors: Scott Davilla / Stephan Diederich Copyright 2008 Team-XBMC\nsee http://atv-xbmc-launcher.googlecode.com or www.xbmc.org for details\n%@",licence_string
																				 ]];
	
}

- (id)controllerForIdentifier:(id)identifier args:(id) identifier2{
  PRINT_SIGNATURE();
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
		NSArray* arguments = [obj valueForKey:@"arguments"];
		NSString* launch_agent_file_name = [obj valueForKey:@"LaunchAgentFileName"];
        //depending on we're running in MultiFinder mode we return corresponding controller
        if([[self class] inMultiFinderMode]) {
            return [[[XBMCMFController alloc] initWithAppPath:appPath 
                                                    arguments:arguments
                                           lauchAgentFileName:launch_agent_file_name 
                     ] autorelease];
        }
        else {
            NSString* helperPath = [obj valueForKey:@"helperpath"];
            return [[[XBMCPureController alloc] initWithAppPath:appPath
                                                      arguments:arguments
                                                    helperPath:helperPath
                                            lauchAgentFileName:launch_agent_file_name
                     ] autorelease];        
        }
	} 
	else if ( [entry_type isEqualToNumber:[NSNumber numberWithInt: UPDATER]] ){
		NSArray* urls = [obj valueForKey:@"URLs"];
		return [[[XBMCUpdateController alloc] initWithURLs:urls] autorelease];
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

// ATV <3.0 method. forward to current above
- (id)controllerForIdentifier:(id)identifier {
  [self controllerForIdentifier:identifier args:nil];
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


- (id)previewControlForIdentifier:(id)arg1 {
  PRINT_SIGNATURE();
  NSString *imgPath = [[NSBundle bundleForClass:[XBMCAppliance class]] pathForResource:@"Preview" ofType:@"png"];
  NSImage *theImage = [[NSImage alloc] initWithContentsOfFile:imgPath];
  [theImage setSize:NSMakeSize(64.0,64.0)];
  BRImage *myIcon = [BRImage imageWithData:[theImage TIFFRepresentation]];
  [theImage release];
  BRImageAndSyncingPreviewController* control = [[[BRImageAndSyncingPreviewController alloc] init] autorelease];
  [control setImage:myIcon];
  [control setReflectionAmount:0.2f];
  [control setReflectionOffset:-0.2f];
  return control;
}

/*
 - (id)identifierForContentAlias:(id)arg1 {
 PRINT_SIGNATURE();
 return nil;
 }
 
- (void)refreshPreviewControlDataForIdentifier:(id)arg1 {
  PRINT_SIGNATURE();
}

- (BOOL)handleObjectSelection:(id)arg1 userInfo:(id)arg2 {
  PRINT_SIGNATURE();
  return NO;
}

- (BOOL)handlePlay:(id)arg1 userInfo:(id)arg2 {
  PRINT_SIGNATURE();
  return NO;
}

- (id)previewProvidersForIdentifier:(id)arg1 withNames:(id *)arg2 {
  PRINT_SIGNATURE();
  return nil;
}

- (long)shelfColumnCount {
  return 0;
}
- (id)musicStoreItemWithIdentifier:(id)arg1 {
  PRINT_SIGNATURE();
  return nil;
}
- (id)categoryWithIdentifier:(id)arg1 {
  PRINT_SIGNATURE();
  return nil;
}
- (id)alertControllerForNoContent {
  PRINT_SIGNATURE();
  return nil;
}
- (int)noContentBRError {
  PRINT_SIGNATURE();
  return 0;
}
- (id)alertControllerForNoRemoteContent {
  PRINT_SIGNATURE();
  return nil;
}
- (int)noRemoteContentBRError {
  PRINT_SIGNATURE();
  return 0;
}
- (BOOL)previewError {
  PRINT_SIGNATURE();
  return NO;
}
- (id)previewErrorText {
  PRINT_SIGNATURE();
  return @"Crap";
}
- (id)previewErrorSubtext {
  PRINT_SIGNATURE();
  return @"previewErrorSubtext";
}
- (id)previewErrorIconImage{
  PRINT_SIGNATURE();
  return nil;
}
- (void)previewProviderCountChanged:(id)arg1 {
  PRINT_SIGNATURE();
  return;
}
*/

@end
