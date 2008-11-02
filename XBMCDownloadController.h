//
//  XBMCDownloadController.h
//  XBMCDownloader
//  based on QuDownloader
//  Created by Alan Quatermain on 19/04/07.
//  Copyright 2007 AwkwwardTV. All rights reserved.
//
// Updated by nito 08-20-08 - works in 2.x

#import <Foundation/Foundation.h>
#import <BackRow/BRController.h>
#import <BackRowCompilerShutup.h>

@class BRHeaderControl, BRTextControl, XBMCProgressBarControl;

@interface XBMCDownloadController : BRController
{
	int		padding[16];
	BRHeaderControl *       _header;
	BRTextControl *         _sourceText;
	XBMCProgressBarControl *  _progressBar;
	
	NSURLDownload *         _downloader;
	NSString *              _outputPath;
	long long               _totalLength;
	long long               _gotLength;
	NSString *							mp_urlstr;
	BOOL										m_download_complete;
  BOOL                    m_md5sum_mismatch;
  NSString *              mp_md5;
}

+ (void) clearAllDownloadCaches;
+ (NSString *) downloadCachePath;
+ (NSString *) outputPathForURLString: (NSString *) urlstr;
+ (BOOL) checkMD5SumOfFile:(NSString*) f_file_path MD5:(NSString*) f_md5;

- (id) initWithDownloadPath:(NSString*) fp_download_path MD5:(NSString*) fp_md5;
- (BOOL) beginDownload;
- (BOOL) resumeDownload;
- (void) cancelDownload;
- (void) deleteDownload;

- (BOOL) downloadComplete;

- (BOOL) MD5SumMismatch;

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
