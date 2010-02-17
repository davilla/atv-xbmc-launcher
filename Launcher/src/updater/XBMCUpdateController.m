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
#import "XBMCSimpleDownloader.h"
#import "XBMCUserDefaults.h"

@class BRLayerController;
@implementation XBMCUpdateController

- (id) init {
	[self dealloc];
	@throw [NSException exceptionWithName:@"BNRBadInitCall" reason:@"Init XBMCUpdateController with initWithURL" userInfo:nil];
	return nil;
}

- (id) initWithURLs:(NSArray*) fp_urls {
	PRINT_SIGNATURE();
	if( ! [super init])
		return nil;

  //hold our own copy, we modify it
  mp_urls = [fp_urls mutableCopy];
  //aditionally check preferences for more download urls
  //make sure we get up2date information
  [[XBMCUserDefaults defaults] synchronize];
  [mp_urls addObjectsFromArray: [[XBMCUserDefaults defaults] arrayForKey:XBMC_ADDITIONAL_DOWNLOAD_PLIST_URLS]];

  mp_downloads = [[NSMutableArray alloc] init];
  
  //load image and create imageControl
  NSString *imgPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"download-icon" ofType:@"png"];
  BRImage *myIcon = [BRImage imageWithPath:imgPath];

  imageControl = [[BRImageAndSyncingPreviewController alloc] init];
  [imageControl setImage:myIcon];
  [imageControl setReflectionAmount:0.1f];
  [imageControl setReflectionOffset:0.0f];

  return self;
}

- (void) dealloc {
	PRINT_SIGNATURE();
	[mp_urls release];
	[mp_updates release];
	[mp_items release]; 
	[mp_downloads release];
  [mp_updateScriptPath release];
  [imageControl release];
  
	[super dealloc];
}

#pragma mark -
#pragma mark stack handling overrides
- (void)controlWasActivated{
  PRINT_SIGNATURE();
  [super controlWasActivated];
}

- (void)controlWasDeactivated{
  PRINT_SIGNATURE();
  [super controlWasDeactivated];
}

- (void) wasPushed {
  [super setListTitle: @"Launcher - Downloads"];
  NSPropertyListFormat format;
  mp_updates = [[NSMutableArray alloc] init];
  //iterate over urls given and try to download the plist
  NSEnumerator *enumerator = [mp_urls objectEnumerator];
  id anObject;
  while (anObject = [enumerator nextObject]) {
    DLOG(@"Adding downloads from URL: %@", anObject);
  	NSString *error;
    NSURL* url = [NSURL URLWithString: anObject];
    NSData* plistdata = [NSData dataWithContentsOfURL: url];
    NSArray* updates = [NSPropertyListSerialization propertyListFromData:plistdata
                                                        mutabilityOption:NSPropertyListImmutable
                                                                  format:&format
                                                        errorDescription:&error];
    if(!updates)
    {
      ELOG(@"Could not download urls from %@. Error was: %@", url, error);
      //todo: Alert user?
      [error release];
    } else {
      [mp_updates addObjectsFromArray:updates];
    }
  }
  
	if(![mp_updates count])
	{
    [[self stack] swapController: [BRAlertController alertOfType:0 titled:nil primaryText:@"No downloads found!"
                                                   secondaryText:[NSString stringWithFormat:@"URLs tried: %@", mp_urls]]];
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

- (void) wasPopped{
  PRINT_SIGNATURE();
  [super wasPopped];
}

#pragma mark -
#pragma mark XBMCSimpleDownloaderDelegate
- (void) simpleDownloader:(XBMCSimpleDownloader*) theDownloader didFailWithError:(NSError*) error {
  //remove downloader from stack and push an alert controller for the returned error
  //(hopefully it has nice localized reasons & such...)
	BRAlertController * obj = [BRAlertController alertForError:error];
	[[self stack] swapController: obj];
}

//called if download finished successfully
- (void) simpleDownloader:(XBMCSimpleDownloader *) theDownloader didFinishDownloadingToFile:(NSString *) filename {

  //store filename into the finishedDownloads array
  [mp_downloads addObject:filename];

  //pop the current downloader from the stack
  [[self stack] popController];

  NSDictionary* dict = [mp_updates objectAtIndex:m_update_item];
  //check if there is another download we want to start
  NSString* next_url_lookup = [NSString stringWithFormat:@"URL_%i",[mp_downloads count]];
  DLOG(@"checking for next URL with %@", next_url_lookup);
  NSString* l_url = [dict valueForKey:next_url_lookup];
  if(l_url){
    DLOG(@"found new url: %@", l_url);
    //there' another download. start that one first
    NSString* next_md5_lookup = [NSString stringWithFormat:@"MD5_%i",[mp_downloads count]];

    XBMCSimpleDownloader *downloader = [[XBMCSimpleDownloader alloc] initWithDownloadPath:l_url
                                                                   MD5:[dict objectForKey:next_md5_lookup]];
    [downloader setDelegate:self];
    [downloader setTitle:[NSString stringWithFormat:@"Downloading update: %@",[dict valueForKey:@"Name"]]];
    [[self stack] pushController: downloader];
    [downloader release];
  } else {
    //start the update script with path to downloaded file(s)
    DLOG(@"Running update %@ with argument %@", mp_updateScriptPath, mp_downloads);
    XBMCUpdateBlockingController* updateController = [[XBMCUpdateBlockingController alloc]
                                                      initWithScript:mp_updateScriptPath downloads:mp_downloads];
    [updateController setDelegate:self];
    [[self stack] pushController: updateController];
    [updateController release];
  }
}

//called on md5 mismatch
- (void) simpleDownloaderDidFailMD5Check:(XBMCSimpleDownloader *) theDownloader {
  //swap the download controller with an alertcontroller
  BRAlertController *alertController = [BRAlertController alertOfType:0
                                                               titled:@"Error"
                                                          primaryText:@"MD5 sums don't match. Please try to redownload."
                                                        secondaryText:@"If this message still appears after redownload, updates have changed.This should be corrected automatically in a few hours, if not please file an issue at http://atv-xbmc-launcher.googlecode.com. Thanks!"
                                        ];
  [[self stack] swapController:alertController];
}

#pragma mark -
#pragma mark XBMCUpdateBlockingControllerDelegate and helpers

- (void) cleanupUpdateFiles {
  //clear downloaded files
  DLOG(@"Update finished. Clearing download cache");
  NSDictionary* dict = [mp_updates objectAtIndex:m_update_item];
  NSString* script_folder = [mp_updateScriptPath stringByDeletingLastPathComponent];
  DLOG("Removing %@ ", script_folder);
  [[NSFileManager defaultManager] removeFileAtPath: script_folder
                                           handler: nil];
  NSEnumerator *enumerator = [mp_downloads objectEnumerator];
  NSString *downloadPath;
  while (downloadPath = [enumerator nextObject]) {
    NSString* download_folder =  [downloadPath stringByDeletingLastPathComponent];
    DLOG("Removing %@ ", download_folder);
    [[NSFileManager defaultManager] removeFileAtPath: download_folder
                                             handler: nil];
  }
}

- (void) xBMCUpdateBlockingControllerDidSucceed:(XBMCUpdateBlockingController *) theUpdater {
  [self cleanupUpdateFiles];
  [[self stack] swapController: [BRAlertController alertOfType:0 titled:nil
                                                   primaryText:@"Update finished successfully!"
                                                 secondaryText:@"Hit menu to return"]];
}

- (void) xBMCUpdateBlockingController:(XBMCUpdateBlockingController *) theUpdater didFailWithExitCode:(int) exitCode {
  [self cleanupUpdateFiles];
  [[self stack] swapController: [BRAlertController alertOfType:0 titled:nil
                                                   primaryText:[NSString stringWithFormat:@"Error: Update script exited with status: %i",exitCode]
                                                 secondaryText:nil]];
}

#pragma mark -
#pragma mark BRMenuControllerDataDelegate
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
    //ToDo show what went wrong
		return;
	}
	//store it where XBMCDownloader stores stuff, too
  if( mp_updateScriptPath ){
    [mp_updateScriptPath release];
    mp_updateScriptPath = nil;
  }
	mp_updateScriptPath = [[XBMCSimpleDownloader generateOutputPathForURLString:[dict valueForKey:@"UpdateScript"]] retain];
	[[NSFileManager defaultManager] createDirectoryAtPath: [mp_updateScriptPath stringByDeletingLastPathComponent]
                                             attributes: nil];
	if( ! [script_data writeToFile:mp_updateScriptPath atomically:YES] ) {
		ELOG(@"Could not save update script to %@", mp_updateScriptPath);
		return;
	}
	DLOG(@"Downloaded update script to %@. Starting download of update...", mp_updateScriptPath);
  [mp_downloads removeAllObjects];
  
  //push the download controller, it reports back through the delegate
  XBMCSimpleDownloader *downloader = [[XBMCSimpleDownloader alloc] initWithDownloadPath:[dict valueForKey:@"URL"] MD5:[dict objectForKey:@"MD5"]];
  [downloader setDelegate:self];
	[downloader setTitle:[NSString stringWithFormat:@"Downloading %@",[dict valueForKey:@"Name"]]];
	[[self stack] pushController: downloader];
  [downloader release];
}

- (float)heightForRow:(long)row				{	return 0.0f; }
- (BOOL)rowSelectable:(long)row				{	return YES;}
- (long)itemCount							{	return (long) [mp_items count];}
- (id)itemForRow:(long)row					{	return [mp_items objectAtIndex:row]; }
- (long)rowForTitle:(id)title				{	return (long)[mp_items indexOfObject:title]; }
- (id)titleForRow:(long)row					{	return [[mp_items objectAtIndex:row] title]; }

#pragma mark -
#pragma mark BRMediaMenuController overrides
- (id) previewControlForItem:(long)fp8 {
  return imageControl;
}

- (BOOL) isNetworkDependent{
	return TRUE;
}

@end
