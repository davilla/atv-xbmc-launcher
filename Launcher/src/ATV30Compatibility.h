//
//  ATV30Compatibility.h
//  atv-xbmc-tools
//
//  Created by Stephan Diederich on 30.10.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BackRow/BRImage.h"
#import "BackRow/BRMenuController.h"
#import "BackRow/BRRenderer.h"
@interface BRImage (ATV30Compatibility)

+ (id) imageWithPath:(id)path;

@end

@interface BRControl (XBMCCompat)

- (NSRect) bounds;
- (NSRect) setBounds:(NSRect) bounds;

- (NSRect) frame;
- (NSRect) setFrame:(NSRect) frame;
@end;

@class BRRenderContext;
@class CARenderer;

@interface BRRenderer (XBMCCompatFor30)
+ (id) singleton;
@end

@interface BRRenderer (NitoAdditions)

- (BRRenderContext *) context;

- (CARenderer*) renderer;
- (void) setRenderer:(CARenderer*) theRenderer;

@end

