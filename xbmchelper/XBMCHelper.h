//
//  XBMCHelper.h
//  xbmchelper
//
//  Created by Stephan Diederich on 11/12/08.
//  Copyright 2008 University Heidelberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "xbmcclientwrapper.h"

@class AppleRemote;

@interface XBMCHelper : NSObject {
  AppleRemote* mp_remote_control;
  XBMCClientWrapper* mp_wrapper;
  bool m_verbose;
}

- (void) enableVerboseMode:(bool) f_really;

- (void) connectToServer:(NSString*) fp_server withUniversalMode:(bool) f_yes_no;
- (void) disconnect;
@end
