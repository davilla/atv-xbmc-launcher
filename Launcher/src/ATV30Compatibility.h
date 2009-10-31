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

@interface BRImage (ATV30Compatibility)

+ (id) imageWithPath:(id)path;

@end


//BRCenteredMenuController vanished in 3.0 and was replaced with an category on BRMenuController
@interface BRMenuController (ATV30Compatibility)

- (void) setUseCenteredLayout:(BOOL)yesno;
- (void)setPrimaryInfoText:(id)fp8;
- (void) setSecondaryInfoText:(id)fp8;

@end