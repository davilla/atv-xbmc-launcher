//
//  XBMCPreferencesController.m
//  xbmclauncher
//
//  Created by Stephan Diederich on 25.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import "XBMCPreferencesController.h"
#import "XBMCUserDefaults.h"
#import "XBMCDebugHelpers.h"
#import "XBMCAppliance.h"
#import "atvxbmccommon.h"

///helper class for putting into the app array
@interface LauncherApplicationEntry : NSObject {
	NSString* mp_identifier;
	NSString* mp_app_path;
  eMultiFinderAppIRMode m_ir_mode;
}
+ (id) finderEntry;
- (id) initWithIdentifier:(NSString*) fp_identifier path:(NSString*) fp_path irMode:(eMultiFinderAppIRMode) f_ir_mode;
- (NSString*) appPath;
- (NSString*) identifier;
- (eMultiFinderAppIRMode) irMode;

@end

@implementation LauncherApplicationEntry
- (id) init{
  [self dealloc];
  @throw [NSException exceptionWithName:@"XBMCBadInitCall" reason:@"Don't use default initializer" userInfo:nil];
  return nil;
};

- (id) initWithIdentifier:(NSString*) fp_identifier path:(NSString*) fp_path irMode:(eMultiFinderAppIRMode) f_ir_mode{
  if(![super init])
    return nil;
  mp_identifier = [fp_identifier retain];
  mp_app_path = [fp_path retain];
  m_ir_mode = f_ir_mode;
  return self;
}

+ (id) finderEntry{
  return [[[LauncherApplicationEntry alloc]initWithIdentifier:@"Finder" path:@"/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder" irMode:MFAPP_IR_MODE_NONE] autorelease];
}

- (NSString*) identifier{
  return mp_identifier;
}

- (NSString*) appPath{
  return mp_app_path;
}

- (eMultiFinderAppIRMode) irMode{
  return m_ir_mode;
}

-(void) dealloc{
  [mp_app_path release];
  [mp_identifier release];
  [super dealloc];
}  
@end


@implementation XBMCPreferencesController

+ (BOOL) autoUpdateEnabled{
  PRINT_SIGNATURE();
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  NSTask* task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/grep" arguments:[NSArray arrayWithObjects:@"mesu.apple.com", @"/etc/hosts",nil]];
  [task waitUntilExit];
  int status = [task terminationStatus];
  [pool release];
  PRINT_SIGNATURE();
  return (status != 0);
}

+ (void) setAutoUpdate:(BOOL) f_enabled{
  PRINT_SIGNATURE();
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  NSString* argument; 
  if(f_enabled)
    argument = @"ON";
  else
    argument = @"OFF";
  NSString* helper_path = [[NSBundle bundleForClass:[self class]] pathForResource:@"setAutoUpdate" ofType:@"sh"];
  DLOG(@"%@",helper_path);
  NSTask* helper = [NSTask launchedTaskWithLaunchPath:@"/bin/bash" arguments: [NSArray arrayWithObjects:
                                                                               helper_path,
                                                                               argument,
                                                                               nil]];
  [helper waitUntilExit];
  [pool release];
}

- (float)heightForRow:(long)row				{	return 0.0f; }
- (BOOL)rowSelectable:(long)row				{	return YES;	}
- (long)itemCount							{	return (long) [mp_items count];}
- (id)itemForRow:(long)row					{	return [mp_items objectAtIndex:row]; }
- (long)rowForTitle:(id)title				{	return (long)[mp_items indexOfObject:title]; }
- (id)titleForRow:(long)row					{	return [[mp_items objectAtIndex:row] title]; }

- (id) init{
	PRINT_SIGNATURE();
	if( ! [super init])
		return nil;
  m_selected_app = 0;
  mp_apps = nil;
  mp_items = nil;
	return self;
}

- (void) dealloc {
	PRINT_SIGNATURE();
	[mp_items release]; 
  [mp_apps release];
	[super dealloc];
}

- (void) wasPushed {	
	[super setListTitle: @"XBMCLauncher"];
	[super setPrimaryInfoText:@"Settings"];
	[self recreateMenuList];
  [self recreateAppList];
	//set ourselves as datasource for the updater list
	[[self list] setDatasource: self];
	[super wasPushed];
}

- (void)itemSelected:(long)index {
	PRINT_SIGNATURE();
	//hack! TODO: if there are more items, do proper selection handling with index 
  switch(index){
    case 0:
    {
      int val = [[XBMCUserDefaults defaults] boolForKey:XBMC_USE_UNIVERSAL_REMOTE];
      [[XBMCUserDefaults defaults] setBool:!val forKey:XBMC_USE_UNIVERSAL_REMOTE];
      [[XBMCUserDefaults defaults] synchronize];
      [[self itemForRow:index] setRightJustifiedText:[[XBMCUserDefaults defaults] boolForKey:XBMC_USE_UNIVERSAL_REMOTE] ? @"Yes": @"No"];
      [self recreateAppList];
      break;
    }
    case 1:
    {
      NSString* current = [[self itemForRow:index] rightJustifiedText];
      if( [current isEqualToString:@"Yes"] )
        [XBMCPreferencesController setAutoUpdate:FALSE];
      else if( [current isEqualToString:@"No"] )
        [XBMCPreferencesController setAutoUpdate:TRUE];
      else
        ELOG(@"Arg, can't be true! Translation issue?!");
      [[self itemForRow:index] setRightJustifiedText:[XBMCPreferencesController autoUpdateEnabled]? @"Yes": @"No"];
      break;
    }
    case 2:
    {
      //choose one app from mp_apps and display it to user
      LauncherApplicationEntry* entry = [mp_apps objectAtIndex:m_selected_app];
      //finally increase selected app for next selection
      if(++m_selected_app >= [mp_apps count]){
        m_selected_app = 0;
      }
      //send a notification to MultiFinder to request default app change
      NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys: 
                                [entry appPath], kApplicationPath,
                                [NSNumber numberWithBool: [entry irMode] ? TRUE:FALSE], kApplicationNeedsIR, 
                                [NSNumber numberWithBool: ([entry irMode] == MFAPP_IR_MODE_UNIVERSAL)? TRUE:FALSE], kApplicationWantsUniversalIRMode, 
                                nil];
      
      [[NSDistributedNotificationCenter defaultCenter] 
       postNotificationName: MULTIFINDER_CHANGE_DEFAULT_APPLICATION_NOTIFICATION
       object: nil
       userInfo: userInfo
       options:NSNotificationDeliverImmediately | NSNotificationPostToAllSessions];
      //push an controller to inform user of that change
      [[self stack] pushController:[BRAlertController alertOfType:0 
                                                           titled:@"Changed MultiFinder's default app to:" 
                                                      primaryText:[entry identifier] 
                                                      secondaryText:[NSString stringWithFormat:@"LaunchPath: %@ IRMode: %i", [entry appPath], [entry irMode]]
                                    ]];
      break;
    }
    default:
      ELOG(@"Huh? Item is not in list :/");
      break;
	}
	[[self list] reload];
}

- (void) recreateMenuList
{
  PRINT_SIGNATURE();
	if(!mp_items){
		mp_items = [[NSMutableArray alloc] initWithObjects:nil]; 
	} else {
		[mp_items removeAllObjects];
	}
	id item = [BRTextMenuItemLayer menuItem];
  [item setTitle:@"Use Universal Mode"];
  [item setRightJustifiedText:[[XBMCUserDefaults defaults] boolForKey:XBMC_USE_UNIVERSAL_REMOTE] ? @"Yes": @"No"];
  [mp_items addObject:item];
	item = [BRTextMenuItemLayer menuItem];
  [item setTitle:@"ATV autoupdate enabled"];
  [item setRightJustifiedText:[XBMCPreferencesController autoUpdateEnabled] ? @"Yes": @"No"];
  [mp_items addObject:item];
  item = [BRTextMenuItemLayer menuItem];
  [item setTitle:@"Toggle MFDefaultApp"];
  [item setRightJustifiedText:@""];
  [mp_items addObject:item];
}

- (void) recreateAppList{
  PRINT_SIGNATURE();
  if(!mp_apps){
    mp_apps = [[NSMutableArray array] retain];
  } else {
		[mp_apps removeAllObjects];
  }

  NSDictionary* info = [[NSBundle bundleForClass:[XBMCAppliance class]] infoDictionary];
  NSArray *categorydescriptors = [info objectForKey:@"FRApplianceCategoryDescriptors"];
  NSEnumerator* enumerator = [categorydescriptors objectEnumerator];
	id obj;
	while((obj = [enumerator nextObject]) != nil) {
    NSNumber*	entry_type = [obj objectForKey:@"entry-type"];
    //entry type is the key if this is an XBMC.app entry or something else like updater, etc
    if( [entry_type isEqualToNumber:[NSNumber numberWithInt: APPLICATION]] ){
      //so read info of current app
      NSString* identifier = [obj objectForKey:@"identifier"];
      NSString* appPath = [obj objectForKey:@"apppath"];
      //just use current setting of ir_mode
      eMultiFinderAppIRMode ir_mode = [[XBMCUserDefaults defaults] boolForKey:XBMC_USE_UNIVERSAL_REMOTE] ? MFAPP_IR_MODE_UNIVERSAL: MFAPP_IR_MODE_NORMAL;
      LauncherApplicationEntry* entry = [[LauncherApplicationEntry alloc] 
                                         initWithIdentifier: identifier
                                         path: appPath
                                         irMode: ir_mode];
      [mp_apps addObject:entry];
      [entry release];
    } 
	}

  //add finder
  [mp_apps addObject:[LauncherApplicationEntry finderEntry]];
  //reset current application
  m_selected_app = 0;
}
@end
