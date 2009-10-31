//
//  XBMCPreviewController.m
//  atv-xbmc-tools
//
//  Created by Stephan Diederich on 30.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "XBMCPreviewController.h"
#import "ATV30Compatibility.h"
#import "common/XBMCDebugHelpers.h"

@interface BRControl (XBMCCompat)
- (NSRect) frame;
- (NSRect) bounds;
- (void) setBounds:(NSRect) rect;
@end

@implementation XBMCPreviewController

-(id) init {
  if (self = [super init] ){
    NSString *imgPath = [[NSBundle bundleForClass:[XBMCPreviewController class]] pathForResource:@"Preview" ofType:@"png"];
    BRImage *img = [BRImage imageWithPath:imgPath];
    [self setImage:img];
  }
  return self;
}

- (void) dealloc {  
  [super dealloc];
}

- (void) layoutSubcontrols {
  PRINT_SIGNATURE();
  NSRect bounds = [self bounds]; //(350x200)
  [self setBounds:NSMakeRect(bounds.size.width/2.0f - 350/2.0f, 0, 350, 200)];
}
@end
