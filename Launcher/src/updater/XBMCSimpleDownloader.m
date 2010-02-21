//
//  XBMCSimpleDownloader.m
//  XBMCSimpleDownloader
//  based on QuDownloader
//  Created by Alan Quatermain on 19/04/07.
//  Copyright 2007 AwkwardTV. All rights reserved.
//
// Updated by nito 08-20-08 - works in 2.x

#import "XBMCSimpleDownloader.h"
#import <BackRow/BackRow.h>
#import "common/XBMCDebugHelpers.h"
#import <helpers/BackRowCompilerShutup.h>
#import <uuid/uuid.h>

@interface XBMCSimpleDownloader (private)
- (BOOL) beginDownload;
- (BOOL) resumeDownload;
- (void) cancelDownload;
- (void) deleteDownload;
- (void) storeResumeData;

@end

@implementation XBMCSimpleDownloader

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

+ (BOOL) checkMD5SumOfFile:(NSString*) f_file_path MD5:(NSString*) f_md5{
	PRINT_SIGNATURE();
	DLOG(@"File: %@ MD5:%@", f_file_path, f_md5);
	NSString* md5checkerpath = [[NSBundle bundleForClass:[self class]] pathForResource:@"compareMD5" ofType:@"sh"];
	NSTask* md5task = [NSTask launchedTaskWithLaunchPath:@"/bin/bash" arguments: [NSArray arrayWithObjects
																																								:md5checkerpath,
																																								f_file_path,
																																								f_md5,
																																								nil]];
	//get md5 of file specified	
	[md5task waitUntilExit];
	return ([md5task terminationStatus] == 0);
}

+ (void) clearAllDownloadCaches
{
	[[NSFileManager defaultManager] removeFileAtPath: [self downloadCachePath]
																					 handler: nil];
}

+ (NSString *) downloadCachePath
{
	static NSString * __cachePath = nil;
	
	if ( __cachePath == nil )
	{
		// find the user's Caches folder
		NSArray * list = NSSearchPathForDirectoriesInDomains( NSCachesDirectory,
																												 NSUserDomainMask, YES );
		
		// handle any failures in that API
		if ( (list != nil) && ([list count] != 0) )
			__cachePath = [list objectAtIndex: 0];
		else
			__cachePath = NSTemporaryDirectory( );
		
		__cachePath = [[__cachePath stringByAppendingPathComponent: @"XBMCLauncherDownloads"] retain];
		
    NSFileManager* filemanager = [NSFileManager defaultManager];
    
    //there have been problems where this directory is actually an already existing file
    BOOL isDirectory = YES;
    if ([filemanager fileExistsAtPath:__cachePath isDirectory:&isDirectory] && !isDirectory) {
      //remove that file
      if (! [filemanager removeFileAtPath:__cachePath handler:nil] ) {
        ELOG(@"Failed to clean download-cache from file '%@'", __cachePath);
      }
    }
    
		// create the directory
		[filemanager createDirectoryAtPath: __cachePath
                            attributes: nil];
	}
	
	return ( __cachePath );
}

+ (NSString *) generateOutputPathForURLString: (NSString *) urlstr
{
	NSString * cache = [self downloadCachePath];
	NSString * name = [urlstr lastPathComponent];
	
  //sanity check the name
  if( name == nil || [name length] == 0 ){
    uuid_t uuid;
    uuid_generate(uuid);
    char uuidString[37];
    uuid_unparse_upper(uuid, uuidString);
    name = [[NSFileManager defaultManager]
            stringWithFileSystemRepresentation:uuidString
            length:strlen(uuidString)];
  } else {
    // trim any parameters from the URL
    NSRange range = [name rangeOfString: @"?"];
    if ( range.location != NSNotFound )
      name = [name substringToIndex: range.location];    
  }
  	
	NSString * folder = [[name stringByDeletingPathExtension]
											 stringByAppendingPathExtension: @"download"];
	
	NSString *ret = [NSString pathWithComponents: [NSArray arrayWithObjects: cache,
																					folder, name, nil]];
  DLOG(@"Generated output path '%@' from urlstr '%@'", ret, urlstr);
  return ret;
}

- (id) initWithDownloadPath:(NSString*) fp_path MD5:(NSString*) fp_md5{
  PRINT_SIGNATURE();
  DLOG(@"Initializing XBMCSimpleDownloader with URL:%@ and MD5:%@", fp_path, fp_md5);
	if( ! [super initWithType:0 titled:nil primaryText:nil secondaryText:nil])
		return nil;
	mp_urlstr = [fp_path retain];
  mp_md5 = [fp_md5 retain];
  
  [self setSecondaryText:[NSString stringWithFormat:@"URL: %@", mp_urlstr]];
	// work out our desired output path
	_outputPath = [[XBMCSimpleDownloader generateOutputPathForURLString: mp_urlstr] retain];
	return ( self );
}

- (void) dealloc
{
  PRINT_SIGNATURE();
	[self cancelDownload];
  [_downloader release];
	[_outputPath release];
	[mp_urlstr release];	
  [mp_md5 release];
	[super dealloc];
}

- (BOOL) beginDownload
{
	if ( _downloader != nil ){
		ELOG(@"Download already running. Exiting..");
		return ( NO );
  }

	// see if we can resume from the current data
	if ( [self resumeDownload] == YES )
		return ( YES );
	
	// didn't work, delete & try again
	[self deleteDownload];
	
	NSURL * url = [NSURL URLWithString: [mp_urlstr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if ( url == nil ){
		ELOG(@"Could not convert downloadpath (%@) to URL. Exiting..", mp_urlstr);
		return ( NO );
  }
	
	NSURLRequest * req = [NSURLRequest requestWithURL: url
																				cachePolicy: NSURLRequestUseProtocolCachePolicy
																		timeoutInterval: 20.0];
	
	// create the dowloader
	_downloader = [[NSURLDownload alloc] initWithRequest: req delegate: self];
	if ( _downloader == nil ){
		ELOG(@"Could not initialize NSURLDownload. Exiting..");
		return ( NO );
  }
	
	[_downloader setDeletesFileUponFailure: NO];
	
	return ( YES );
}

- (BOOL) resumeDownload
{
	if ( _outputPath == nil )
		return ( NO );
	
	NSString * resumeDataPath = [[_outputPath stringByDeletingLastPathComponent]
															 stringByAppendingPathComponent: @"ResumeData"];
	if ( [[NSFileManager defaultManager] fileExistsAtPath: resumeDataPath] == NO )
		return ( NO );
	
	NSData * resumeData = [NSData dataWithContentsOfFile: resumeDataPath];
	if ( (resumeData == nil) || ([resumeData length] == 0) )
		return ( NO );
	
	// try to initialize using the saved data...
	_downloader = [[NSURLDownload alloc] initWithResumeData: resumeData
																								 delegate: self
																										 path: _outputPath];
	if ( _downloader == nil )
		return ( NO );
	
	[_downloader setDeletesFileUponFailure: NO];
	
	return ( YES );
}

- (void) cancelDownload
{
	[_downloader cancel];
	[self storeResumeData];
}

- (void) deleteDownload
{
	if ( _outputPath == nil )
		return;
	
	[[NSFileManager defaultManager] removeFileAtPath:
	 [_outputPath stringByDeletingLastPathComponent]
																					 handler: nil];
}

- (void) storeResumeData
{
	NSData * data = [_downloader resumeData];
	if ( data != nil )
	{
		// store this in the .download folder
		NSString * path = [[_outputPath stringByDeletingLastPathComponent]
											 stringByAppendingPathComponent: @"ResumeData"];
		[data writeToFile: path atomically: YES];
	}
}

#pragma mark -
#pragma mark stack callbacks
- (void)controlWasActivated;
{
  PRINT_SIGNATURE();
	[super controlWasActivated];
  [self disableScreenSaver];
	if ( [self beginDownload] == NO )
	{
		[self setTitle: @"Download Failed"];
	}
}

- (void)controlWasDeactivated;
{
  PRINT_SIGNATURE();
	[super controlWasDeactivated];
	[self cancelDownload];
  [self enableScreenSaver];
}

- (BOOL) isNetworkDependent
{
	return ( YES );
}

#pragma mark -
#pragma mark NSURLDownloadDelegate
- (void) download: (NSURLDownload *) download
decideDestinationWithSuggestedFilename: (NSString *) filename
{
	// we'll ignore the given filename and use our own
	// ensure that all new path components exist
	[[NSFileManager defaultManager] createDirectoryAtPath: [_outputPath stringByDeletingLastPathComponent]
																						 attributes: nil];

	NSLog( @"Starting download to file '%@'", _outputPath );

	[download setDestination: _outputPath allowOverwrite: YES];
}

- (void) download: (NSURLDownload *) download didFailWithError: (NSError *) error
{
	[self storeResumeData];

	NSLog( @"Download encountered error '%d' (%@)", [error code],
				[error localizedDescription] );

  [delegate simpleDownloader:self didFailWithError:error];
}

- (void) download: (NSURLDownload *) download didReceiveDataOfLength: (unsigned) length
{
	_gotLength += (long long) length;
	
//	NSLog( @"Got %u bytes, %lld total of %i", length, _gotLength, _totalLength );

  if(_totalLength){
    [self setPrimaryText:[NSString stringWithFormat:@"%1.2f of %1.1fMB", _gotLength/(1024.*1024.), (_totalLength/(1024.*1024.))]];
  }
  else
    [self setPrimaryText:[NSString stringWithFormat:@"%1.2fiMB", _gotLength/(1024.*1024)]];
}

- (void) download: (NSURLDownload *) download didReceiveResponse: (NSURLResponse *) response
{
	// we might receive more than one of these (if we get redirects,
	// for example)
	_totalLength = 0;
	_gotLength = 0;
	
	NSLog( @"Got response for new download, length = %lld", [response expectedContentLength] );
	
	if ( [response expectedContentLength] != NSURLResponseUnknownLength )
		_totalLength = [response expectedContentLength];
	else
    _totalLength = 0;
}

- (BOOL) download: (NSURLDownload *) download
shouldDecodeSourceDataOfMIMEType: (NSString *) encodingType
{
	NSLog( @"Asked to decode data of MIME type '%@'", encodingType );
	
	// we'll allow decoding only if it won't interfere with resumption
  return ( NO );
}

- (void) download: (NSURLDownload *) download
willResumeWithResponse: (NSURLResponse *) response
				 fromByte: (long long) startingByte
{
	// resuming now, so pretty much as above, except we have a starting
	// value to set on the progress bar
	_totalLength = 0;
	_gotLength = (long long) startingByte;
	
	// the total here seems to be the amount *remaining*, not the
	// complete total
	
	NSLog( @"Resumed download at byte %lld, remaining is %lld",
				_gotLength, [response expectedContentLength] );
	
	if ( [response expectedContentLength] != NSURLResponseUnknownLength )
	{
		_totalLength = _gotLength + [response expectedContentLength];
	}
	else
	{
		// an arbitrary number
    _totalLength = 0;
	}
	// reset current value as appropriate
  if(_totalLength)
    [self setPrimaryText:[NSString stringWithFormat:@"%1.2f/100", _gotLength/(_totalLength*1.f)*100.]];
  else
    [self setPrimaryText:[NSString stringWithFormat:@"%qi", _gotLength]];
}

- (void) downloadDidFinish: (NSURLDownload *) download
{
	// completed the download: set progress full (just in case) and
	// go do something with the data
  //	[_progressBar setPercentage: 100.0f];
	
	NSLog( @"Download finished" );
  
	[_downloader autorelease];
	_downloader = nil;

  if( mp_md5 && ! [XBMCSimpleDownloader checkMD5SumOfFile:_outputPath MD5:mp_md5] ){
    DLOG(@"MD5 sum mismatch. Removing broken download");
    [[NSFileManager defaultManager] removeFileAtPath: [_outputPath stringByDeletingLastPathComponent]
                                             handler: nil];
    [delegate simpleDownloaderDidFailMD5Check:self];
  } else {
    if( mp_md5 != nil )
      DLOG(@"Download did finish and MD5 sums matched");
    else
      DLOG(@"Download did finish; no MD5 given to check");

    [delegate simpleDownloader:self didFinishDownloadingToFile:_outputPath];
  }
}

#pragma mark -
#pragma mark Delegate handling
- (void) setDelegate:(id) aDelegate {
  delegate = aDelegate;
}

- (id) delegate {
  return delegate;
}


@end
