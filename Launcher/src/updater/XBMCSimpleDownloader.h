//
//  XBMCSimpleDownloader.h
//  xbmclauncher
//
//  Created by Stephan Diederich on 11/20/08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>

@interface XBMCSimpleDownloader : BRAlertController {
	int		padding[16];
  NSURLDownload *         _downloader;
	NSString *              _outputPath;
	long long               _totalLength;
	long long               _gotLength;
	NSString *							mp_urlstr;
	BOOL										m_download_complete;
  BOOL                    m_md5sum_mismatch;
  NSString *              mp_md5;
  int m_screen_saver_timeout;
}
+ (void) clearAllDownloadCaches;
+ (NSString *) downloadCachePath;
+ (NSString *) outputPathForURLString: (NSString *) urlstr;
+ (BOOL) checkMD5SumOfFile:(NSString*) f_file_path MD5:(NSString*) f_md5;

- (id) initWithDownloadPath:(NSString*) fp_download_path MD5:(NSString*) fp_md5;
- (BOOL) downloadComplete;

- (BOOL) MD5SumMismatch;

// stack callbacks
- (BOOL) isNetworkDependent;

@end
