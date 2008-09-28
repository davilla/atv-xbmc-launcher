//
//  XBMCUpdateController.m
//  xbmclauncher
//
//  Created by Stephan Diederich on 20.09.08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "XBMCUpdateController.h"
#import "XBMCDebugHelpers.h"
#import "XBMCUpdateBlockingController.h"
#import "QuDownloadController.h"

@class BRLayerController;
@implementation XBMCUpdateController


- (id) init {
	[self dealloc];
	@throw [NSException exceptionWithName:@"BNRBadInitCall" reason:@"Init XBMCUpdateController with initWithURL" userInfo:nil];
	return nil;
}


- (id) initWithURL:(NSURL*) fp_url {
	PRINT_SIGNATURE();
	if( ! [super init])
		return nil;
	mp_url = [fp_url retain];
	return self;
}

- (void) dealloc {
	PRINT_SIGNATURE();
	[mp_url release];
	[mp_updates release];
	[mp_items release]; 
	[super dealloc];
}

- (void) willbePushed {
}

- (void) wasPushed {	
	[super setListTitle: @"XBMCLauncher"];
	[super setPrimaryInfoText: @"Updater"];
	[super setSecondaryInfoText: @"Available Downloads (Those are just stubs, nothing is working yet):"];

	//this simple test worked, so we'll reuse this one I think
	//[[self stack] swapController: [[QuDownloadController alloc] init]];
	NSString *error;
	NSPropertyListFormat format;
	NSData* plistdata = [NSData dataWithContentsOfURL: mp_url];
	mp_updates = [[NSPropertyListSerialization propertyListFromData:plistdata
																					 mutabilityOption:NSPropertyListImmutable
																										 format:&format
																								errorDescription:&error] retain];
	if(!mp_updates)
	{
    NSLog(error);
    [error release];
		[[self stack] swapController: [BRAlertController alertOfType:0 titled:nil primaryText:@"Update URLs not found or corrupt!" 
																									 secondaryText:[NSString stringWithFormat:@" %@", mp_url]]];
	} 
	mp_items = [[NSMutableArray alloc] initWithObjects:nil]; 
	unsigned int i;
	for(i=0; i < [mp_updates count]; ++i){
		id item = [BRTextMenuItemLayer menuItem];
		NSDictionary* dict = [mp_updates objectAtIndex:i];
		[item setTitle:[dict valueForKey:@"Name"]];
		[item setRightJustifiedText:[dict valueForKey:@"Type"]];
		[mp_items addObject:item];
	}
	//set ourselves as datasource for the updater list
	[[self list] setDatasource: self];
	[super wasPushed];
}

- (void)itemSelected:(long)index {
	PRINT_SIGNATURE();
	m_update_item = index;
	//get the dict for this update
	NSDictionary* dict = [mp_updates objectAtIndex:index];
	//first download the script. this should be easy
	NSString* scriptURL =  [dict valueForKey:@"UpdateScript"];
	NSData* script_data = [NSData dataWithContentsOfURL: [NSURL URLWithString:scriptURL]];
	if(! script_data ){
		ELOG(@"Could not download update script from %@", [dict valueForKey:@"UpdateScript"]);
		return;
	}
	//store it where QuDownloader stores stuff, too
	NSString* script_path = [QuDownloadController outputPathForURLString:[dict valueForKey:@"UpdateScript"]];
	[[NSFileManager defaultManager] createDirectoryAtPath: [script_path stringByDeletingLastPathComponent]
																						 attributes: nil];
	if( ! [script_data writeToFile:script_path atomically:YES] ) {
		ELOG(@"Could not save update script to %@", script_path);
		return;
	}
	DLOG(@"Downloaded update script to %@. Starting download of update...", script_path);
	//now start the real download
	mp_downloader = [[QuDownloadController alloc] initWithDownloadPath:[dict valueForKey:@"URL"]];
	[mp_downloader setTitle:[NSString stringWithFormat:@"Downloading update: %@",[dict valueForKey:@"Name"]]];
	[[self stack] pushController: mp_downloader];
}

- (BOOL) isNetworkDependent{
	return TRUE;
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
	
- (void) wasExhumedByPoppingController: (id) controller
{
	// handle being revealed when the user presses Menu
	PRINT_SIGNATURE();
	// always call super
	[super wasExhumedByPoppingController: controller];
	//if the download controller popped us check if download was properly finished
	if(controller == mp_downloader){
		if ( [mp_downloader downloadComplete] ){
			//start the update script with path to downloaded file 
			DLOG(@"Download finished. Starting update");
			NSDictionary* dict = [mp_updates objectAtIndex:m_update_item];
			NSString* script_path = [QuDownloadController outputPathForURLString:[dict valueForKey:@"UpdateScript"]];
			NSString* download =  [QuDownloadController outputPathForURLString:[dict valueForKey:@"URL"]];
			
			DLOG(@"Running %@ with argument %@", script_path, download);
			XBMCUpdateBlockingController* blocker = [[[XBMCUpdateBlockingController alloc] 
																							 initWithScript: script_path forUpdate:download] autorelease];
			[[self stack] pushController: blocker];
		}else {
			DLOG(@"Download not yet completed");
		}
		//release the downloader, it gets recreated on new selection
		[mp_downloader release];
		mp_downloader = nil;
	}
	else {
		DLOG(@"someone else popped us");
	}
}

- (float)heightForRow:(long)row				{	return 0.0f; }
- (BOOL)rowSelectable:(long)row				{	return YES;}
- (long)itemCount							{	return (long) [mp_items count];}
- (id)itemForRow:(long)row					{	return [mp_items objectAtIndex:row]; }
- (long)rowForTitle:(id)title				{	return (long)[mp_items indexOfObject:title]; }
- (id)titleForRow:(long)row					{	return [[mp_items objectAtIndex:row] title]; }

@end
