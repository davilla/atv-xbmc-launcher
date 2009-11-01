//
//  XBMCSimpleDownloader.h
//  xbmclauncher
//
//  Created by Stephan Diederich on 11/20/08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>

@protocol XBMCSimpleDownloaderDelegate;


@interface XBMCSimpleDownloader : BRAlertController {
	int		padding[16];
  NSURLDownload *         _downloader;
	NSString *              _outputPath;
	long long               _totalLength;
	long long               _gotLength;
	NSString *							mp_urlstr;
  NSString *              mp_md5;
  int                     m_screen_saver_timeout;

  id<XBMCSimpleDownloaderDelegate> delegate;
}
+ (void) clearAllDownloadCaches;
+ (NSString *) downloadCachePath;
+ (NSString *) outputPathForURLString: (NSString *) urlstr;
+ (BOOL) checkMD5SumOfFile:(NSString*) f_file_path MD5:(NSString*) f_md5;

// inits a new downloader for specified path and optional MD5
// once it's pushed onto the stack, it starts downloading
- (id) initWithDownloadPath:(NSString*) fp_download_path MD5:(NSString*) fp_md5;

  
- (void) setDelegate:(id) delegate;
- (id) delegate;

@end


@protocol XBMCSimpleDownloaderDelegate<NSObject>

//called if download finished successfully
- (void) simpleDownloaderDidFinish:(XBMCSimpleDownloader *) theDownloader;

//called if download failed
- (void) simpleDownloader:(XBMCSimpleDownloader *) theDownloader didFailWithError:(NSError *) error;

//called on md5 mismatch
- (void) simpleDownloaderDidFailMD5Check:(XBMCSimpleDownloader *) theDownloader;

@end
