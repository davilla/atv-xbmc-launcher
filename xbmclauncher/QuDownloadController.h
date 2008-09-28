//
//  QuDownloadController.h
//  QuDownloader
//
//  Created by Alan Quatermain on 19/04/07.
//  Copyright 2007 AwkwwardTV. All rights reserved.
//
// Updated by nito 08-20-08 - works in 2.x

#import <Foundation/Foundation.h>
#import <BackRow/BRController.h>

@class BRHeaderControl, BRTextControl, QuProgressBarControl;

@interface QuDownloadController : BRController
{
	int		padding[16];
	BRHeaderControl *       _header;
	BRTextControl *         _sourceText;
	QuProgressBarControl *  _progressBar;
	
	NSURLDownload *         _downloader;
	NSString *              _outputPath;
	NSString *							mp_title;
	long long               _totalLength;
	long long               _gotLength;
	NSString *							mp_urlstr;
	BOOL										m_download_complete;
}
-(NSRect)frame;

+ (void) clearAllDownloadCaches;
+ (NSString *) downloadCachePath;
+ (NSString *) outputPathForURLString: (NSString *) urlstr;

- (id) initWithDownloadPath:(NSString*) fp_download_path;
- (BOOL) beginDownload;
- (BOOL) resumeDownload;
- (void) cancelDownload;
- (void) deleteDownload;

- (BOOL) downloadComplete;

// stack callbacks
- (BOOL) isNetworkDependent;

- (void) setTitle: (NSString *) title;
- (NSString *) title;

- (void) setSourceText: (NSString *) text;
- (NSString *) sourceText;

- (float) percentDownloaded;

- (void) storeResumeData;

// NSURLDownload delegate methods
- (void) download: (NSURLDownload *) download
decideDestinationWithSuggestedFilename: (NSString *) filename;
- (void) download: (NSURLDownload *) download didFailWithError: (NSError *) error;
- (void) download: (NSURLDownload *) download didReceiveDataOfLength: (unsigned) length;
- (void) download: (NSURLDownload *) download didReceiveResponse: (NSURLResponse *) response;
- (BOOL) download: (NSURLDownload *) download
shouldDecodeSourceDataOfMIMEType: (NSString *) encodingType;
- (void) download: (NSURLDownload *) download
willResumeWithResponse: (NSURLResponse *) response
				 fromByte: (long long) startingByte;
- (void) downloadDidFinish: (NSURLDownload *) download;

@end
