//
//  QuDownloadController.m
//  QuDownloader
//
//  Created by Alan Quatermain on 19/04/07.
//  Copyright 2007 AwkwardTV. All rights reserved.
//
// Updated by nito 08-20-08 - works in 2.x

#import "QuDownloadController.h"
#import "QuProgressBarControl.h"
#import <BackRow/BackRow.h>
#import <XBMCDebugHelpers.h>

@implementation QuDownloadController

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
		
		// ensure this exists
		[[NSFileManager defaultManager] createDirectoryAtPath: __cachePath
																							 attributes: nil];
	}
	
	return ( __cachePath );
}

+ (NSString *) outputPathForURLString: (NSString *) urlstr
{
	NSString * cache = [self downloadCachePath];
	NSString * name = [urlstr lastPathComponent];
	
	// trim any parameters from the URL
	NSRange range = [name rangeOfString: @"?"];
	if ( range.location != NSNotFound )
		name = [name substringToIndex: range.location];
	
	NSString * folder = [[name stringByDeletingPathExtension]
											 stringByAppendingPathExtension: @"download"];
	
	return ( [NSString pathWithComponents: [NSArray arrayWithObjects: cache,
																					folder, name, nil]] );
}

- (void) drawSelf
{	
	// lay out our UI
	NSRect masterFrame = [self frame];
	NSRect frame = masterFrame;
	
	// header goes in a specific location
	frame.origin.y = frame.size.height * 0.82f;
	frame.size.height = [[BRThemeInfo sharedTheme] listIconHeight];
	[_header setFrame: frame];
	
	// progress bar goes in a specific place too (one-eighth of the way
	// up the screen)
	frame.size.width = masterFrame.size.width * 0.45f;
	frame.size.height = ceilf( frame.size.width * 0.068f );
	frame.origin.x = (masterFrame.size.width - frame.size.width) * 0.5f;
	frame.origin.y = masterFrame.origin.y + (masterFrame.size.height * (1.0f / 8.0f));
	[_progressBar setFrame: frame];
  
	[self setSourceText: mp_urlstr];   // this lays itself out
  [_progressBar setCurrentValue: [_progressBar minValue]];
  
	// add the controls
	[self addControl: _header];
	[self addControl: _sourceText];
	[self addControl: _progressBar];
	
	
}

- (id) initWithDownloadPath:(NSString*) fp_path MD5:(NSString*) fp_md5{
  PRINT_SIGNATURE();
	if ( [super init] == nil )
		return ( nil );
	mp_urlstr = [fp_path retain];
	mp_md5 = [fp_md5 retain];
  
	//create gui elements
	_header = [[BRHeaderControl alloc] init];
	_sourceText = [[BRTextControl alloc] init];
	_progressBar = [[QuProgressBarControl alloc] init];
	
	// work out our desired output path
	_outputPath = [[QuDownloadController outputPathForURLString: mp_urlstr] retain];
	return ( self );
}

- (void) dealloc
{
  PRINT_SIGNATURE();
	[self cancelDownload];
  
	[_header release];
	[_sourceText release];
	[_progressBar release];
	[_downloader release];
	[_outputPath release];
	[mp_urlstr release];	
  [mp_md5 release];
	[super dealloc];
}

- (BOOL) beginDownload
{
	if ( _downloader != nil )
		return ( NO );
	m_download_complete = FALSE;
	// see if we can resume from the current data
	if ( [self resumeDownload] == YES )
		return ( YES );
	
	// didn't work, delete & try again
	[self deleteDownload];
	
	NSURL * url = [NSURL URLWithString: mp_urlstr];
	if ( url == nil )
		return ( NO );
	
	NSURLRequest * req = [NSURLRequest requestWithURL: url
																				cachePolicy: NSURLRequestUseProtocolCachePolicy
																		timeoutInterval: 20.0];
	
	// create the dowloader
	_downloader = [[NSURLDownload alloc] initWithRequest: req delegate: self];
	if ( _downloader == nil )
		return ( NO );
	
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

// stack callbacks
- (void)controlWasActivated;
{
	[self drawSelf];
  	
	if ( [self beginDownload] == NO )
	{
		[self setTitle: @"Download Failed"];
		[_progressBar setPercentage: 0.0f];
		////[[self scene] renderScene];
	}
	
	[super controlWasActivated];
}

- (void)controlWillDeactivate;
{
	[self cancelDownload];
	[super controlWillDeactivate];
}

- (BOOL) isNetworkDependent
{
	return ( YES );
}

- (void) setTitle: (NSString *) title
{
	[_header setTitle: title];
}

- (NSString *) title
{
	return ( [_header title] );
}
- (void) setSourceText: (NSString *) srcText
{
	[_sourceText setText: srcText withAttributes:[[BRThemeInfo sharedTheme] paragraphTextAttributes]];
	// layout this item
	NSRect masterFrame = [self frame];
	CGSize txtSize = [_sourceText renderedSize];
	
	CGRect frame;
	frame.origin.x = (masterFrame.size.width - txtSize.width) * 0.5f;
	frame.origin.y = (masterFrame.size.height * 0.75f) - txtSize.height;
	frame.size = txtSize;
	
	[_sourceText setFrame: frame];
}

- (NSString *) sourceText
{
	return ( [_sourceText text] );
}

- (float) percentDownloaded
{
	return ( [_progressBar percentage] );
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

// NSURLDownload delegate methods
- (void) download: (NSURLDownload *) download
decideDestinationWithSuggestedFilename: (NSString *) filename
{
	// we'll ignore the given filename and use our own
	// they'll likely be the same, anyway
	
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
	
	// show an alert for the returned error (hopefully it has nice
	// localized reasons & such...)
	BRAlertController * obj = [BRAlertController alertForError:error];
	[[self stack] swapController: obj];
}

- (void) download: (NSURLDownload *) download didReceiveDataOfLength: (unsigned) length
{
	_gotLength += (long long) length;
	float percentage = 0.0f;
	
	//NSLog( @"Got %u bytes, %lld total", length, _gotLength );
	
	// we'll handle the case where the NSURLResponse didn't include the
	// size of the source file
	if ( _totalLength == 0 )
	{
		// bump up the max value a bit
		percentage = [_progressBar percentage];
		if ( percentage >= 95.0f )
			[_progressBar setMaxValue: [_progressBar maxValue] + (float) (length << 3)];
	}
	
	[_progressBar setCurrentValue: _gotLength];
}

- (void) download: (NSURLDownload *) download didReceiveResponse: (NSURLResponse *) response
{
	// we might receive more than one of these (if we get redirects,
	// for example)
	_totalLength = 0;
	_gotLength = 0;
	
	NSLog( @"Got response for new download, length = %lld", [response expectedContentLength] );
	
	if ( [response expectedContentLength] != NSURLResponseUnknownLength )
	{
		_totalLength = [response expectedContentLength];
		[_progressBar setMaxValue: (float) _totalLength];
	}
	else
	{
		// an arbitrary number -- one megabyte
		[_progressBar setMaxValue: 1024.0f * 1024.0f];
	}
}

- (BOOL) download: (NSURLDownload *) download
shouldDecodeSourceDataOfMIMEType: (NSString *) encodingType
{
	NSLog( @"Asked to decode data of MIME type '%@'", encodingType );
	
	// we'll allow decoding only if it won't interfere with resumption
	if ( [encodingType isEqualToString: @"application/gzip"] )
		return ( NO );
	
	return ( YES );
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
		[_progressBar setMaxValue: (float) _totalLength];
	}
	else
	{
		// an arbitrary number
		[_progressBar setMaxValue: (float) (_gotLength << 1)];
	}
	
	// reset current value as appropriate
	[_progressBar setCurrentValue: (float) _gotLength];
}

- (BOOL) MD5SumMismatch{
  return m_md5sum_mismatch;
}

- (void) downloadDidFinish: (NSURLDownload *) download
{
	// completed the download: set progress full (just in case) and
	// go do something with the data
	[_progressBar setPercentage: 100.0f];
	
	NSLog( @"Download finished" );
	m_download_complete = TRUE;
  
	// we'll swap ourselves off the stack here, so let's remove our
	// reference to the downloader, just in case calling -cancel now
	// might cause a problem
	[_downloader autorelease];
	_downloader = nil;
  if( mp_md5 && ! [QuDownloadController checkMD5SumOfFile:_outputPath MD5:mp_md5] ){
    m_md5sum_mismatch = TRUE;
    DLOG(@"Remove broken download");				
    [[NSFileManager defaultManager] removeFileAtPath: [_outputPath stringByDeletingLastPathComponent]
                                             handler: nil];
  } else {
    DLOG(@"MD5 sums matched or none was given");
    m_md5sum_mismatch = FALSE;
  }
  [[self stack] popController];
}

- (BOOL) downloadComplete{
	return m_download_complete;
}
@end
